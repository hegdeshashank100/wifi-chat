import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../models/contact.dart';
import '../models/message.dart';
import '../database/database_helper.dart';
import '../services/device_id_service.dart';
import '../services/profile_service.dart';
import '../services/background_scan_service.dart';
import '../services/lan_transport.dart';
import '../services/bluetooth_transport.dart';

class MessagingService extends ChangeNotifier {
  static final MessagingService instance = MessagingService._init();
  MessagingService._init();

  // Use cluster mode so we can discover/connect to multiple peers at once.
  final Strategy _strategy = Strategy.P2P_CLUSTER;
  final String _serviceId = "com.example.wifi_chat";
  final Uuid _uuid = const Uuid();

  String _myDeviceId = '';
  String _myName = '';
  String? _myPhone;
  final Map<String, String> _connectedDevices = {}; // endpointId -> contactId
  final Map<String, String> _deviceIdToEndpoint = {}; // contactId -> endpointId
  final Set<String> _lanContacts = {}; // contactIds connected over LAN
  final Set<String> _btContacts = {}; // contactIds connected over BT
  late final LanTransport _lanTransport;
  late final BluetoothTransport _btTransport;
  bool _isAdvertising = false;
  bool _isDiscovering = false;
  Timer? _pendingRetryTimer;

  final DatabaseHelper _db = DatabaseHelper.instance;
  final ProfileService _profileService = ProfileService();

  String get myDeviceId => _myDeviceId;
  String get myName => _myName;
  Map<String, String> get connectedDevices => Map.from(_connectedDevices);
  bool get isAdvertising => _isAdvertising;
  bool get isDiscovering => _isDiscovering;

  // Callbacks for UI updates
  Function(Message)? onMessageReceived;
  Function(String contactId, bool isOnline)? onContactStatusChanged;
  Function(String contactId, MessageStatus status)? onMessageStatusChanged;

  Future<void> initialize() async {
    await _requestPermissions();
    await _ensureLocationServiceEnabled();
    final profile = await _profileService.getProfile();
    _myDeviceId = profile?.deviceId ?? await DeviceIdService.getDeviceId();
    _myName = profile?.displayName ?? await _getMyName();
    _myPhone = profile?.phoneNumber;
    _lanTransport = LanTransport(
      deviceId: _myDeviceId,
      displayName: _myName,
      onJsonReceived: _handleLanJson,
      onPeerConnected: _handleLanConnected,
      onPeerDisconnected: _handleLanDisconnected,
    );
    _btTransport = BluetoothTransport(
      deviceId: _myDeviceId,
      displayName: _myName,
      onJsonReceived: _handleBtJson,
      onPeerConnected: _handleBtConnected,
      onPeerDisconnected: _handleBtDisconnected,
    );
    await startServices();
    await _lanTransport.start();
    await _btTransport.start();
    _startPendingRetryLoop();
    await BackgroundScanService.instance.start(onEnsure: ensureServicesRunning);
  }

  Future<void> _ensureLocationServiceEnabled() async {
    try {
      final enabled = await Nearby().checkLocationEnabled();
      if (!enabled) {
        final turnedOn = await Nearby().enableLocationServices();
        if (!turnedOn) {
          debugPrint(
              '⚠️ Location services remain off; nearby discovery may fail.');
        }
      }
    } catch (e) {
      debugPrint('❌ Location enable check failed: $e');
    }
  }

  Future<void> _requestPermissions() async {
    // Only request essential permissions for Nearby Connections
    final permissions = [
      Permission.location, // Required for WiFi Direct/Bluetooth discovery
      Permission.bluetoothAdvertise, // Android 12+ for advertising
      Permission.bluetoothConnect, // Android 12+ for connecting
      Permission.bluetoothScan, // Android 12+ for scanning
      Permission.nearbyWifiDevices, // Android 13+ for WiFi Direct
      Permission
          .notification, // Android 13+ for showing foreground notifications
    ];

    for (final permission in permissions) {
      final status = await permission.status;
      if (status.isDenied || status.isPermanentlyDenied) {
        final result = await permission.request();

        if (result.isPermanentlyDenied &&
            permission == Permission.notification) {
          // Surface a prompt path to app notification settings
          await openAppSettings();
        }
      }
    }
  }

  Future<String> _getMyName() async {
    // Try to get name from first contact (self), or use device ID
    try {
      final contact = await _db.getContact(_myDeviceId);
      return contact?.name ?? 'User_${_myDeviceId.substring(0, 8)}';
    } catch (e) {
      return 'User_${_myDeviceId.substring(0, 8)}';
    }
  }

  Future<void> updateMyName(String name) async {
    _myName = name;
    notifyListeners();
  }

  Future<void> startServices() async {
    await startAdvertising();
    await startDiscovery();
  }

  void _startPendingRetryLoop() {
    _pendingRetryTimer?.cancel();
    _pendingRetryTimer =
        Timer.periodic(const Duration(seconds: 20), (_) => _flushAllPending());
  }

  Future<void> ensureServicesRunning() async {
    if (!_isAdvertising) {
      await startAdvertising();
    }
    if (!_isDiscovering) {
      await startDiscovery();
    }
  }

  final Map<String, ConnectionInfo> _connectionInfo = {};

  String _buildEndpointName() {
    final phonePart = (_myPhone ?? '').trim();
    return '$_myName|$_myDeviceId|$phonePart';
  }

  Future<void> startAdvertising() async {
    if (_isAdvertising) return;

    try {
      await Nearby().startAdvertising(
        _buildEndpointName(),
        _strategy,
        onConnectionInitiated: (String endpointId, ConnectionInfo info) {
          _connectionInfo[endpointId] = info;
          _acceptConnection(endpointId, info);
        },
        onConnectionResult: (String endpointId, Status status) {
          if (status == Status.CONNECTED) {
            final info = _connectionInfo[endpointId];
            if (info != null) {
              final contactId = _extractContactId(info.endpointName);
              _connectedDevices[endpointId] = contactId;
              _deviceIdToEndpoint[contactId] = endpointId;
              onContactStatusChanged?.call(contactId, true);
              _updateContactOnlineStatus(contactId, true);
              _flushPending(contactId);
              print('✅ Connected to: ${info.endpointName}');
              notifyListeners();
            }
          }
        },
        onDisconnected: (String endpointId) {
          final contactId = _connectedDevices[endpointId];
          if (contactId != null) {
            _connectedDevices.remove(endpointId);
            _deviceIdToEndpoint.remove(contactId);
            _connectionInfo.remove(endpointId);
            onContactStatusChanged?.call(contactId, false);
            _updateContactOnlineStatus(contactId, false);
            ensureServicesRunning();
            notifyListeners();
          }
        },
        serviceId: _serviceId,
      );

      _isAdvertising = true;
      notifyListeners();
      print('📡 Advertising started');
    } catch (e) {
      print('❌ Advertising error: $e');
    }
  }

  Future<void> startDiscovery() async {
    if (_isDiscovering) return;

    try {
      await Nearby().startDiscovery(
        _buildEndpointName(),
        _strategy,
        onEndpointFound: (String endpointId, String name, String serviceId) {
          print('🔍 Found device: $name');
          if (serviceId == _serviceId) {
            _requestConnection(endpointId, name);
          }
        },
        onEndpointLost: (endpointId) {
          final contactId = _connectedDevices[endpointId];
          if (contactId != null) {
            _connectedDevices.remove(endpointId);
            _deviceIdToEndpoint.remove(contactId);
            onContactStatusChanged?.call(contactId, false);
            _updateContactOnlineStatus(contactId, false);
            notifyListeners();
          }
        },
        serviceId: _serviceId,
      );

      _isDiscovering = true;
      notifyListeners();
      print('🔍 Discovery started');
    } catch (e) {
      print('❌ Discovery error: $e');
    }
  }

  Future<void> _requestConnection(String endpointId, String deviceName) async {
    try {
      await Nearby().requestConnection(
        _buildEndpointName(),
        endpointId,
        onConnectionInitiated: (String id, ConnectionInfo info) {
          _acceptConnection(id, info);
        },
        onConnectionResult: (String id, Status status) {
          if (status == Status.CONNECTED) {
            final contactId = _extractContactId(deviceName);
            _connectedDevices[id] = contactId;
            _deviceIdToEndpoint[contactId] = id;
            onContactStatusChanged?.call(contactId, true);
            _updateContactOnlineStatus(contactId, true);
            _flushPending(contactId);
            notifyListeners();
          }
        },
        onDisconnected: (String id) {
          final contactId = _connectedDevices[id];
          if (contactId != null) {
            _connectedDevices.remove(id);
            _deviceIdToEndpoint.remove(contactId);
            onContactStatusChanged?.call(contactId, false);
            _updateContactOnlineStatus(contactId, false);
            ensureServicesRunning();
            notifyListeners();
          }
        },
      );
    } catch (e) {
      print('❌ Connection request error: $e');
    }
  }

  Future<void> _acceptConnection(String endpointId, ConnectionInfo info) async {
    try {
      await Nearby().acceptConnection(
        endpointId,
        onPayLoadRecieved: (String endpointId, Payload payload) {
          _handlePayload(endpointId, payload);
        },
      );

      final contactId = _extractContactId(info.endpointName);
      _connectedDevices[endpointId] = contactId;
      _deviceIdToEndpoint[contactId] = endpointId;

      // Auto-add contact if not exists
      await _autoAddContact(contactId, info.endpointName);

      print('✅ Accepted connection from: ${info.endpointName}');
    } catch (e) {
      print('❌ Accept connection error: $e');
    }
  }

  Future<void> _autoAddContact(String contactId, String fullName) async {
    final existing = await _db.getContact(contactId);
    if (existing == null) {
      final name = _extractContactName(fullName);
      final contact = Contact(
        id: contactId,
        name: name,
        lastSeen: DateTime.now(),
        isOnline: true,
        createdAt: DateTime.now(),
      );
      await _db.insertContact(contact);
      print('👤 Auto-added contact: $name');
    }
  }

  void _handlePayload(String endpointId, Payload payload) {
    final contactId = _connectedDevices[endpointId];
    if (contactId == null) return;

    try {
      if (payload.type == PayloadType.BYTES) {
        final data = String.fromCharCodes(payload.bytes!);
        final json = jsonDecode(data) as Map<String, dynamic>;

        if (json['type'] == 'message') {
          _handleTextMessage(json, contactId);
        } else if (json['type'] == 'status_update') {
          _handleStatusUpdate(json, contactId);
        }
      } else if (payload.type == PayloadType.FILE) {
        _handleFileTransfer(payload, contactId);
      }
    } catch (e) {
      print('❌ Payload handling error: $e');
    }
  }

  Future<void> _handleTextMessage(
      Map<String, dynamic> json, String contactId) async {
    final message = Message(
      id: json['id'] as String,
      chatId: contactId,
      senderId: contactId,
      receiverId: _myDeviceId,
      content: json['content'] as String,
      type: MessageType.text,
      status: MessageStatus.delivered,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      isMe: false,
    );

    await _db.insertMessage(message);
    onMessageReceived?.call(message);

    // Send delivery confirmation
    await _sendStatusUpdate(contactId, message.id, MessageStatus.delivered);

    print('📨 Message received from: $contactId');
  }

  Future<void> _handleStatusUpdate(
      Map<String, dynamic> json, String contactId) async {
    final messageId = json['messageId'] as String;
    final status = MessageStatus.values[json['status'] as int];

    await _db.updateMessageStatus(messageId, status);
    onMessageStatusChanged?.call(contactId, status);
    print('✓ Status update: $messageId -> $status');
  }

  Future<void> _handleFileTransfer(Payload payload, String contactId) async {
    // File transfer handling (for future implementation)
    print('📎 File received from: $contactId');
  }

  Future<bool> sendMessage(String contactId, String content) async {
    final message = Message(
      id: _uuid.v4(),
      chatId: contactId,
      senderId: _myDeviceId,
      receiverId: contactId,
      content: content,
      type: MessageType.text,
      status: MessageStatus.sending,
      timestamp: DateTime.now(),
      isMe: true,
    );

    // Save to database
    await _db.insertMessage(message);

    final sent = await _sendPayloadForMessage(contactId, message);
    if (sent) {
      print('✅ Message sent to: $contactId');
      return true;
    }

    print('⏳ Queued message for: $contactId (waiting for link)');
    return true;
  }

  Future<bool> _sendPayloadForMessage(String contactId, Message message) async {
    final payload = {
      'type': 'message',
      'id': message.id,
      'content': message.content,
      'timestamp': message.timestamp.millisecondsSinceEpoch,
    };

    try {
      final sent = await _trySendPayload(contactId, payload);
      if (sent) {
        final updatedMessage = message.copyWith(status: MessageStatus.sent);
        await _db.updateMessage(updatedMessage);
        onMessageStatusChanged?.call(contactId, MessageStatus.sent);
        return true;
      }
    } catch (e) {
      print('❌ Send error: $e');
    }

    // Keep as sending; retry when contact comes online.
    return false;
  }

  Future<bool> _trySendPayload(
      String contactId, Map<String, dynamic> payload) async {
    final endpointId = _deviceIdToEndpoint[contactId];
    final hasLan = _lanContacts.contains(contactId);
    final hasBt = _btContacts.contains(contactId);

    bool sent = false;

    if (hasLan) {
      sent = await _lanTransport.send(contactId, payload);
    }

    if (!sent && hasBt) {
      sent = await _btTransport.send(contactId, payload);
    }

    if (!sent && endpointId != null) {
      await Nearby().sendBytesPayload(
        endpointId,
        Uint8List.fromList(utf8.encode(jsonEncode(payload))),
      );
      sent = true;
    }

    return sent;
  }

  Future<void> _sendStatusUpdate(
      String contactId, String messageId, MessageStatus status) async {
    final endpointId = _deviceIdToEndpoint[contactId];
    final hasLan = _lanContacts.contains(contactId);
    final hasBt = _btContacts.contains(contactId);
    if (endpointId == null && !hasLan && !hasBt) return;

    final payload = {
      'type': 'status_update',
      'messageId': messageId,
      'status': status.index,
    };

    try {
      bool sent = false;
      if (hasLan) {
        sent = await _lanTransport.send(contactId, payload);
      }
      if (!sent && hasBt) {
        sent = await _btTransport.send(contactId, payload);
      }
      if (!sent && endpointId != null) {
        await Nearby().sendBytesPayload(
          endpointId,
          Uint8List.fromList(utf8.encode(jsonEncode(payload))),
        );
      }
    } catch (e) {
      print('❌ Status update error: $e');
    }
  }

  Future<void> _updateContactOnlineStatus(
      String contactId, bool isOnline) async {
    final contact = await _db.getContact(contactId);
    if (contact != null) {
      final updated = contact.copyWith(
        isOnline: isOnline,
        lastSeen: DateTime.now(),
      );
      await _db.updateContact(updated);
    }
  }

  String _extractContactId(String fullName) {
    // Format: "Name|DeviceID|Phone?"
    final parts = fullName.split('|');
    return parts.length > 1 ? parts[1] : fullName;
  }

  String _extractContactName(String fullName) {
    final parts = fullName.split('|');
    return parts.isNotEmpty ? parts[0] : fullName;
  }

  bool isContactOnline(String contactId) {
    return _deviceIdToEndpoint.containsKey(contactId) ||
        _lanContacts.contains(contactId) ||
        _btContacts.contains(contactId);
  }

  Future<void> stopServices() async {
    try {
      await Nearby().stopAdvertising();
      await Nearby().stopDiscovery();
      await _lanTransport.stop();
      await _btTransport.stop();
      _isAdvertising = false;
      _isDiscovering = false;
      _connectedDevices.clear();
      _deviceIdToEndpoint.clear();
      _lanContacts.clear();
      _btContacts.clear();
      notifyListeners();
    } catch (e) {
      print('❌ Stop services error: $e');
    }
  }

  @override
  void dispose() {
    _pendingRetryTimer?.cancel();
    _lanTransport.stop();
    _btTransport.stop();
    stopServices();
    super.dispose();
  }

  // LAN transport callbacks
  void _handleLanConnected(String contactId, String? displayName) {
    _lanContacts.add(contactId);
    _deviceIdToEndpoint.putIfAbsent(contactId, () => 'lan-$contactId');
    onContactStatusChanged?.call(contactId, true);
    _updateContactOnlineStatus(contactId, true);
    _autoAddContact(contactId, '${displayName ?? contactId}|$contactId|');
    _flushPending(contactId);
    ensureServicesRunning();
    notifyListeners();
  }

  void _handleLanDisconnected(String contactId) {
    _lanContacts.remove(contactId);
    if (_deviceIdToEndpoint[contactId]?.startsWith('lan-') ?? false) {
      _deviceIdToEndpoint.remove(contactId);
    }
    onContactStatusChanged?.call(contactId, false);
    _updateContactOnlineStatus(contactId, false);
    ensureServicesRunning();
    notifyListeners();
  }

  void _handleLanJson(String contactId, Map<String, dynamic> json) {
    final type = json['type'];
    if (type == 'message') {
      _handleTextMessage(json, contactId);
    } else if (type == 'status_update') {
      _handleStatusUpdate(json, contactId);
    }
  }

  // Bluetooth transport callbacks
  void _handleBtConnected(String contactId, String? displayName) {
    _btContacts.add(contactId);
    _deviceIdToEndpoint.putIfAbsent(contactId, () => 'bt-$contactId');
    onContactStatusChanged?.call(contactId, true);
    _updateContactOnlineStatus(contactId, true);
    _autoAddContact(contactId, '${displayName ?? contactId}|$contactId|');
    _flushPending(contactId);
    ensureServicesRunning();
    notifyListeners();
  }

  void _handleBtDisconnected(String contactId) {
    _btContacts.remove(contactId);
    if (_deviceIdToEndpoint[contactId]?.startsWith('bt-') ?? false) {
      _deviceIdToEndpoint.remove(contactId);
    }
    onContactStatusChanged?.call(contactId, false);
    _updateContactOnlineStatus(contactId, false);
    ensureServicesRunning();
    notifyListeners();
  }

  void _handleBtJson(String contactId, Map<String, dynamic> json) {
    final type = json['type'];
    if (type == 'message') {
      _handleTextMessage(json, contactId);
    } else if (type == 'status_update') {
      _handleStatusUpdate(json, contactId);
    }
  }

  Future<void> _flushPending(String contactId) async {
    final pending = await _db.getPendingOutbound(contactId);
    for (final message in pending) {
      final sent = await _sendPayloadForMessage(contactId, message);
      if (!sent) {
        break; // Stop if current transport still unavailable; will retry later.
      }
    }
  }

  Future<void> _flushAllPending() async {
    final contacts = await _db.getAllContacts();
    for (final contact in contacts) {
      await _flushPending(contact.id);
    }
  }
}
