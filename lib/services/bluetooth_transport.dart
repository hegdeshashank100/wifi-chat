import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

/// Bluetooth Classic transport using RFCOMM sockets and a simple line-delimited
/// JSON protocol. Designed for offline peer discovery and messaging.
class BluetoothTransport {
  BluetoothTransport({
    required String deviceId,
    required String displayName,
    required this.onJsonReceived,
    required this.onPeerConnected,
    required this.onPeerDisconnected,
  })  : _deviceId = deviceId,
        _displayName = displayName;

  final String _deviceId;
  final String _displayName;
  final void Function(String contactId, Map<String, dynamic> json)
      onJsonReceived;
  final void Function(String contactId, String? displayName) onPeerConnected;
  final void Function(String contactId) onPeerDisconnected;

  static const Duration _retryDelay = Duration(seconds: 12);
  static const Duration _discoveryDuration = Duration(seconds: 12);
  static const String _namePrefix = 'WiFiChat';

  final Map<String, _BtChannel> _channels = {}; // contactId -> channel
  StreamSubscription<BluetoothDiscoveryResult>? _discoverySub;
  final Set<String> _connecting = <String>{};
  final Map<String, DateTime> _nextRetryAllowed = {};
  bool _stopped = false;
  bool get isRunning => !_stopped;

  Future<void> start() async {
    _stopped = false;
    await _ensureBluetoothOn();
    _startDiscoveryLoop();
  }

  Future<void> stop() async {
    _stopped = true;
    await _discoverySub?.cancel();
    _discoverySub = null;
    for (final c in _channels.values.toList()) {
      await c.close();
    }
    _channels.clear();
  }

  Future<bool> send(String contactId, Map<String, dynamic> json) async {
    final channel = _channels[contactId];
    if (channel == null) return false;
    return channel.send(json);
  }

  Future<void> _ensureBluetoothOn() async {
    final adapter = FlutterBluetoothSerial.instance;
    final state = await adapter.state;
    if (state != BluetoothState.STATE_ON) {
      await adapter.requestEnable();
    }
  }

  void _startDiscoveryLoop() {
    _discoverySub?.cancel();
    _discoverySub = FlutterBluetoothSerial.instance
        .startDiscovery()
        .listen(_handleDiscoveryResult, onError: (_) {});

    // Restart discovery periodically to keep finding peers.
    Future.delayed(_discoveryDuration, () {
      if (_stopped) return;
      _startDiscoveryLoop();
    });
  }

  void _handleDiscoveryResult(BluetoothDiscoveryResult result) {
    if (_stopped) return;
    final device = result.device;
    final address = device.address;
    if (address.isEmpty) return;

    // Skip devices that are clearly not ours (reduces noisy connects to random headsets/TVs).
    final name = device.name;
    final bool looksLikeUs =
        (name != null && name.startsWith(_namePrefix)) || device.isBonded;
    if (!looksLikeUs) return;

    // Avoid connecting to ourselves or already-connected peers.
    if (_channels.values.any((c) => c.address == address)) return;

    // Throttle retries per address.
    final now = DateTime.now();
    final nextAllowed = _nextRetryAllowed[address];
    if (nextAllowed != null && now.isBefore(nextAllowed)) return;

    if (_connecting.contains(address)) return;

    _connectTo(address);
  }

  void _connectTo(String address) async {
    _connecting.add(address);
    try {
      final connection = await BluetoothConnection.toAddress(address)
          .timeout(const Duration(seconds: 8));
      _nextRetryAllowed.remove(address);
      _attachChannel(connection, address);
    } catch (_) {
      // Retry later if not stopped
      if (!_stopped) {
        _nextRetryAllowed[address] = DateTime.now().add(_retryDelay);
        Future.delayed(_retryDelay, () {
          if (!_stopped) _connectTo(address);
        });
      }
    }
    _connecting.remove(address);
  }

  void _attachChannel(BluetoothConnection connection, String remoteAddress) {
    // Expect a hello JSON line first; send ours immediately.
    final socket = connection.input;
    final sink = connection.output;
    final address = remoteAddress;

    // Send our hello
    sink.add(utf8.encode('${jsonEncode({
          'type': 'hello',
          'id': _deviceId,
          'name': _displayName,
        })}\n'));

    String? contactId;
    StreamSubscription<List<int>>? sub;

    sub = socket!.listen((data) {
      final lines = const LineSplitter().convert(utf8.decode(data));
      for (final line in lines) {
        try {
          final json = jsonDecode(line) as Map<String, dynamic>;
          if (contactId == null &&
              json['type'] == 'hello' &&
              json['id'] != null) {
            contactId = json['id'] as String;
            final name = json['name'] as String?;
            if (contactId == _deviceId) {
              connection.finish();
              return;
            }
            // If already connected, drop the duplicate
            if (_channels.containsKey(contactId)) {
              connection.finish();
              return;
            }
            final channel = _BtChannel(
              address: address,
              connection: connection,
              onJson: (m) => onJsonReceived(contactId!, m),
              onClose: () {
                _channels.remove(contactId);
                onPeerDisconnected(contactId!);
              },
            );
            _channels[contactId!] = channel;
            onPeerConnected(contactId!, name);
          } else if (contactId != null) {
            onJsonReceived(contactId!, json);
          }
        } catch (_) {
          // ignore malformed lines
        }
      }
    }, onDone: () {
      sub?.cancel();
      if (contactId != null) {
        _channels.remove(contactId);
        onPeerDisconnected(contactId!);
      }
    }, onError: (_) {
      sub?.cancel();
      if (contactId != null) {
        _channels.remove(contactId);
        onPeerDisconnected(contactId!);
      }
    }, cancelOnError: true);
  }
}

class _BtChannel {
  _BtChannel({
    required this.address,
    required this.connection,
    required this.onJson,
    required this.onClose,
  });

  final String address;
  final BluetoothConnection connection;
  final void Function(Map<String, dynamic>) onJson;
  final VoidCallback onClose;

  Future<bool> send(Map<String, dynamic> json) async {
    try {
      connection.output.add(utf8.encode('${jsonEncode(json)}\n'));
      await connection.output.allSent;
      return true;
    } catch (_) {
      await close();
      return false;
    }
  }

  Future<void> close() async {
    try {
      await connection.close();
    } catch (_) {}
    onClose();
  }
}
