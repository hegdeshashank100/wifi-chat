import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Lightweight LAN transport that broadcasts presence over UDP and
/// establishes TCP channels for fast offline messaging on the same subnet.
class LanTransport {
  LanTransport({
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

  static const int _udpPort = 40404;
  static const Duration _beaconInterval = Duration(seconds: 3);

  RawDatagramSocket? _udp;
  ServerSocket? _server;
  Timer? _beaconTimer;
  final Map<String, _LanChannel> _channels = {}; // contactId -> channel
  final Map<String, String?> _peerNames = {}; // contactId -> displayName

  bool get isRunning => _udp != null && _server != null;

  Future<void> start() async {
    if (isRunning) return;

    _server = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    _server!.listen(_handleIncomingSocket, onError: (_) {});

    _udp = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _udpPort);
    _udp!.broadcastEnabled = true;
    _udp!.listen(_handleUdpPacket, onError: (_) {});

    _beaconTimer = Timer.periodic(_beaconInterval, (_) => _broadcastHello());
    _broadcastHello();
  }

  Future<void> stop() async {
    _beaconTimer?.cancel();
    _beaconTimer = null;
    _udp?.close();
    _udp = null;
    await _server?.close();
    _server = null;
    for (final channel in _channels.values.toList()) {
      await channel.close();
    }
    _channels.clear();
  }

  Future<bool> send(String contactId, Map<String, dynamic> json) async {
    final channel = _channels[contactId];
    if (channel == null) return false;
    return channel.send(json);
  }

  void _broadcastHello() {
    final udp = _udp;
    final server = _server;
    if (udp == null || server == null) return;

    final payload = jsonEncode({
      'type': 'hello',
      'id': _deviceId,
      'name': _displayName,
      'port': server.port,
    });
    final data = utf8.encode(payload);
    udp.send(data, InternetAddress("255.255.255.255"), _udpPort);
  }

  void _handleUdpPacket(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final datagram = _udp?.receive();
    if (datagram == null) return;

    try {
      final json =
          jsonDecode(utf8.decode(datagram.data)) as Map<String, dynamic>;
      if (json['type'] != 'hello') return;
      final contactId = json['id'] as String?;
      if (contactId == null || contactId == _deviceId) return;
      final port = (json['port'] as num?)?.toInt();
      if (port == null) return;
      final name = json['name'] as String?;

      final remote = datagram.address;
      final key = contactId;
      if (_channels.containsKey(key)) return;
      _peerNames[contactId] = name;
      _connectToPeer(remote, port, contactId);
    } catch (_) {
      // Ignore malformed beacons.
    }
  }

  Future<void> _connectToPeer(
      InternetAddress address, int port, String contactId) async {
    try {
      final socket = await Socket.connect(address, port,
          timeout: const Duration(seconds: 3));
      _attachChannel(socket, contactId);
    } catch (_) {
      // Best-effort; failures are fine.
    }
  }

  void _handleIncomingSocket(Socket socket) async {
    // Expect a hello line first to learn contactId.
    final sub = utf8.decoder
        .bind(socket)
        .transform(const LineSplitter())
        .listen((line) {}, onError: (_) {});

    String? contactId;
    sub.onData((line) {
      if (contactId == null) {
        try {
          final json = jsonDecode(line) as Map<String, dynamic>;
          if (json['type'] == 'hello' && json['id'] is String) {
            contactId = json['id'] as String;
            _peerNames[contactId!] = json['name'] as String?;
            if (contactId == _deviceId) {
              socket.destroy();
              return;
            }
            _attachChannel(socket, contactId!);
            return;
          }
        } catch (_) {
          // fall through
        }
      }
    });
  }

  void _attachChannel(Socket socket, String contactId) {
    // If we already have a channel, close the new one.
    if (_channels.containsKey(contactId)) {
      socket.destroy();
      return;
    }

    // Send our hello once connected to ensure both sides know IDs.
    socket.writeln(jsonEncode({
      'type': 'hello',
      'id': _deviceId,
      'name': _displayName,
      'port': _server?.port,
    }));

    final channel = _LanChannel(
        contactId: contactId,
        socket: socket,
        onJson: (json) => onJsonReceived(contactId, json),
        onClose: () {
          _channels.remove(contactId);
          onPeerDisconnected(contactId);
        });

    _channels[contactId] = channel;
    onPeerConnected(contactId, _peerNames[contactId]);
  }
}

class _LanChannel {
  _LanChannel({
    required this.contactId,
    required this.socket,
    required this.onJson,
    required this.onClose,
  }) {
    _sub = utf8.decoder.bind(socket).transform(const LineSplitter()).listen(
        _handleLine,
        onError: (_) => _handleClose(),
        onDone: _handleClose,
        cancelOnError: true);
  }

  final String contactId;
  final Socket socket;
  final void Function(Map<String, dynamic>) onJson;
  final VoidCallback onClose;
  StreamSubscription<String>? _sub;

  Future<bool> send(Map<String, dynamic> json) async {
    try {
      socket.writeln(jsonEncode(json));
      await socket.flush();
      return true;
    } catch (_) {
      _handleClose();
      return false;
    }
  }

  void _handleLine(String line) {
    try {
      final json = jsonDecode(line) as Map<String, dynamic>;
      onJson(json);
    } catch (_) {
      // ignore malformed lines
    }
  }

  Future<void> close() async => _handleClose();

  void _handleClose() {
    _sub?.cancel();
    _sub = null;
    try {
      socket.destroy();
    } catch (_) {}
    onClose();
  }
}
