// import 'dart:async';
// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:nearby_connections/nearby_connections.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_foreground_task/flutter_foreground_task.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:wifi_chat/services/device_id_service.dart';

// // Background task handler for SOS scanning
// @pragma('vm:entry-point')
// void startCallback() {
//   FlutterForegroundTask.setTaskHandler(SOSBackgroundHandler());
// }

// class SOSBackgroundHandler extends TaskHandler {
//   @override
//   Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
//     print('🆘 SOS Background service started');
//   }

//   @override
//   void onRepeatEvent(DateTime timestamp) {
//     // OPTIMIZED: This runs every 3 seconds for ultra-fast scanning
//     print(
//         '🔍 Background SOS scan active: ${DateTime.now().toString().substring(11, 19)}');

//     FlutterForegroundTask.updateService(
//       notificationTitle: '🆘 Emergency SOS Active',
//       notificationText:
//           'Ultra-fast scanning: ${DateTime.now().toString().substring(11, 19)}',
//     );

//     FlutterForegroundTask.sendDataToTask({'action': 'scan'});
//   }

//   @override
//   Future<void> onDestroy(DateTime timestamp) async {
//     print('🛑 SOS Background service stopped');
//   }
// }

// class SOSScreenImproved extends StatefulWidget {
//   const SOSScreenImproved({super.key});

//   @override
//   State<SOSScreenImproved> createState() => _SOSScreenImprovedState();
// }

// class _SOSScreenImprovedState extends State<SOSScreenImproved> {
//   // OPTIMIZED: Use P2P_POINT_TO_POINT for fastest discovery
//   final Strategy strategy = Strategy.P2P_POINT_TO_POINT;
//   final String serviceId = "com.example.sos_emergency";

//   late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

//   bool _isSOSActive = false;
//   bool _isAdvertising = false;
//   bool _isDiscovering = false;
//   bool _backgroundServiceRunning = false;
//   final Map<String, String> _connectedDevices = {};
//   final Map<String, String> _cachedEndpoints = {}; // OPTIMIZED: Cache endpoints
//   final List<String> _messages = [];
//   final Set<String> _connectionAttempts = {};
//   final Set<String> _receivedSosIds = {}; // OPTIMIZED: Prevent SOS duplicates
//   String _currentLocation = 'Getting location...';
//   String _myDeviceId = '';
//   String? _lastReceivedSos; // OPTIMIZED: Store last SOS for forwarding
//   Timer? _discoveryTimer;
//   Timer? _discoveryTimeoutTimer; // OPTIMIZED: Discovery timeout (6s max)
//   Timer? _connectionHealthTimer;
//   Timer? _locationUpdateTimer; // OPTIMIZED: Controlled location updates

//   @override
//   void initState() {
//     super.initState();
//     _initializeApp();
//   }

//   Future<void> _initializeApp() async {
//     try {
//       await _initializeNotifications();
//       await _initializeForegroundTask();
//       await _initializeSOSSystem();
//     } catch (e) {
//       print('❌ Error initializing SOS app: $e');
//       _showMessage('Error initializing app. Some features may not work.');
//     }
//   }

//   Future<void> _initializeForegroundTask() async {
//     try {
//       FlutterForegroundTask.init(
//         androidNotificationOptions: AndroidNotificationOptions(
//           channelId: 'sos_foreground_service',
//           channelName: 'SOS Foreground Service',
//           channelDescription: 'Emergency SOS monitoring service',
//           onlyAlertOnce: true,
//         ),
//         iosNotificationOptions: const IOSNotificationOptions(),
//         foregroundTaskOptions: ForegroundTaskOptions(
//           // OPTIMIZED: Very fast scanning every 3 seconds
//           eventAction: ForegroundTaskEventAction.repeat(3000),
//           autoRunOnBoot: true,
//           allowWakeLock: true,
//           allowWifiLock: true,
//         ),
//       );

//       FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
//     } catch (e) {
//       print('❌ Error initializing foreground task: $e');
//     }
//   }

//   void _onReceiveTaskData(Object data) {
//     if (data is Map && data['action'] == 'scan') {
//       _restartDiscovery();
//     }
//   }

//   Future<void> _initializeNotifications() async {
//     try {
//       flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

//       const AndroidInitializationSettings initializationSettingsAndroid =
//           AndroidInitializationSettings('@mipmap/ic_launcher');

//       const InitializationSettings initializationSettings =
//           InitializationSettings(android: initializationSettingsAndroid);

//       await flutterLocalNotificationsPlugin.initialize(
//         initializationSettings,
//         onDidReceiveNotificationResponse: (details) {
//           if (details.payload == 'sos_alert') {
//             _showEmergencyAlert(
//                 details.input ?? 'SOS Alert received', 'Nearby Device');
//           }
//         },
//       );

//       // Create high-priority notification channel
//       const AndroidNotificationChannel channel = AndroidNotificationChannel(
//         'sos_alerts',
//         'SOS Emergency Alerts',
//         description: 'Critical alerts for SOS emergencies',
//         importance: Importance.max,
//         playSound: true,
//         enableVibration: true,
//       );

//       await flutterLocalNotificationsPlugin
//           .resolvePlatformSpecificImplementation<
//               AndroidFlutterLocalNotificationsPlugin>()
//           ?.createNotificationChannel(channel);
//     } catch (e) {
//       print('❌ Error initializing notifications: $e');
//     }
//   }

//   Future<void> _initializeSOSSystem() async {
//     await _requestPermissions();
//     await _getCurrentLocation();
//     _myDeviceId = await DeviceIdService.getDeviceId();
//     await _loadCachedEndpoints();
//     setState(() {});
//     _startSOSServices();
//   }

//   Future<void> _requestPermissions() async {
//     final permissions = [
//       Permission.location,
//       Permission.bluetooth,
//       Permission.bluetoothAdvertise,
//       Permission.bluetoothConnect,
//       Permission.bluetoothScan,
//       Permission.nearbyWifiDevices,
//     ];

//     for (final permission in permissions) {
//       if (await permission.isDenied) {
//         await permission.request();
//       }
//     }
//   }

//   Future<void> _getCurrentLocation() async {
//     try {
//       if (!await Geolocator.isLocationServiceEnabled()) {
//         _currentLocation = 'Location services disabled';
//         setState(() {});
//         return;
//       }

//       Position position = await Geolocator.getCurrentPosition();
//       setState(() {
//         _currentLocation = 'Lat: ${position.latitude.toStringAsFixed(4)}, '
//             'Lng: ${position.longitude.toStringAsFixed(4)}';
//       });
//     } catch (e) {
//       _currentLocation = 'Location error: $e';
//       setState(() {});
//     }
//   }

//   // OPTIMIZED: Load cached endpoints for instant reconnection
//   Future<void> _loadCachedEndpoints() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final cachedJson = prefs.getString('cached_endpoints');

//       if (cachedJson != null) {
//         final cached = Map<String, String>.from(json.decode(cachedJson));
//         _cachedEndpoints.addAll(cached);
//         print('📂 Loaded ${cached.length} cached endpoints');
//       }
//     } catch (e) {
//       print('⚠️ Error loading cached endpoints: $e');
//     }
//   }

//   void _startSOSServices() {
//     // OPTIMIZED: Start both advertising AND discovery simultaneously for faster connection
//     _startAdvertising();
//     _startDiscovery();

//     // OPTIMIZED: Ultra-fast discovery cycle (5 seconds for immediate detection)
//     _discoveryTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
//       if (mounted) {
//         print('� Ultra-fast discovery restart...');
//         _restartDiscovery();
//       }
//     });

//     // Connection health check (more frequent)
//     _connectionHealthTimer =
//         Timer.periodic(const Duration(seconds: 30), (timer) {
//       if (mounted) _checkConnectionHealth();
//     });

//     // OPTIMIZED: Location updates only when devices connected (every 2 seconds)
//     _locationUpdateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
//       if (mounted && _connectedDevices.isNotEmpty) {
//         _getCurrentLocation();
//       }
//     });
//   }

//   void _checkConnectionHealth() {
//     print('💓 Connection health: ${_connectedDevices.length} devices');

//     if (_connectedDevices.isEmpty && (_isAdvertising || _isDiscovering)) {
//       print('🔄 Restarting services for better connectivity...');
//       _restartServices();
//     }
//   }

//   Future<void> _restartServices() async {
//     try {
//       await Nearby().stopAdvertising();
//       await Nearby().stopDiscovery();
//       await Future.delayed(const Duration(milliseconds: 800));
//       await _startAdvertising();
//       await _startDiscovery();
//       print('✅ Services restarted successfully');
//     } catch (e) {
//       print('❌ Error restarting services: $e');
//     }
//   }

//   Future<void> _restartDiscovery() async {
//     try {
//       await Nearby().stopDiscovery();
//       await Future.delayed(const Duration(milliseconds: 300));
//       await _startDiscovery();
//     } catch (e) {
//       print('❌ Error restarting discovery: $e');
//     }
//   }

//   Future<void> _toggleBackgroundService() async {
//     if (_backgroundServiceRunning) {
//       try {
//         await FlutterForegroundTask.stopService();
//         setState(() => _backgroundServiceRunning = false);
//         _showMessage('🛑 Background service stopped');
//       } catch (e) {
//         _showMessage('❌ Error stopping background service');
//       }
//     } else {
//       try {
//         bool isIgnoringBatteryOptimizations =
//             await FlutterForegroundTask.isIgnoringBatteryOptimizations;

//         if (!isIgnoringBatteryOptimizations) {
//           await FlutterForegroundTask.requestIgnoreBatteryOptimization();
//         }

//         await FlutterForegroundTask.startService(
//           serviceId: 100,
//           notificationTitle: '🆘 Emergency SOS Active',
//           notificationText: 'Ultra-fast emergency monitoring active',
//           callback: startCallback,
//         );

//         setState(() => _backgroundServiceRunning = true);
//         _showMessage('✅ Background service started');
//         _restartDiscovery();
//       } catch (e) {
//         _showMessage('❌ Failed to start background service');
//       }
//     }
//   }

//   Future<void> _startAdvertising() async {
//     if (_isAdvertising) return;

//     try {
//       await Nearby().startAdvertising(
//         _myDeviceId,
//         strategy,
//         onConnectionInitiated: (String id, ConnectionInfo info) {
//           _acceptConnection(id, info);
//         },
//         onConnectionResult: (String id, Status status) {
//           if (status == Status.CONNECTED) {
//             setState(() => _connectedDevices[id] = 'Emergency Device');
//             _cacheEndpoint(id, 'Emergency Device');
//             _showMessage('✅ Connected to emergency device');
//           }
//         },
//         onDisconnected: (String id) {
//           setState(() => _connectedDevices.remove(id));
//           _showMessage('📵 Device disconnected');
//         },
//         serviceId: serviceId,
//       );

//       setState(() => _isAdvertising = true);
//       print('📡 Started advertising successfully');
//     } catch (e) {
//       if (e.toString().contains('STATUS_ALREADY_ADVERTISING')) {
//         setState(() => _isAdvertising = true);
//       }
//     }
//   }

//   Future<void> _startDiscovery() async {
//     if (_isDiscovering) return;

//     // OPTIMIZED: Try cached endpoints first for instant reconnection
//     if (_cachedEndpoints.isNotEmpty) {
//       print(
//           '🚀 Instant reconnection attempt to ${_cachedEndpoints.length} cached devices...');
//       await _tryConnectToCachedEndpoints();

//       // If cache connection successful, delay full discovery
//       if (_connectedDevices.isNotEmpty) {
//         print('✅ Cache hit! Delaying full discovery by 3 seconds');
//         await Future.delayed(const Duration(seconds: 3));
//       }
//     }

//     try {
//       print('⚡ Ultra-fast discovery starting (6s max timeout)...');

//       await Nearby().startDiscovery(
//         _myDeviceId,
//         strategy,
//         onEndpointFound: (String id, String name, String serviceId) {
//           print('🎯 Found device: $name ($id)');
//           if (serviceId == this.serviceId) {
//             print('✅ Valid SOS device - connecting immediately!');
//             _cacheEndpoint(id, name);
//             _requestConnection(id, name);
//           }
//         },
//         onEndpointLost: (endpointId) {
//           print('📵 Lost device: $endpointId');
//           setState(() => _connectedDevices.remove(endpointId));
//         },
//         serviceId: serviceId,
//       );

//       setState(() => _isDiscovering = true);

//       // OPTIMIZED: Aggressive 6-second timeout for speed
//       _discoveryTimeoutTimer?.cancel();
//       _discoveryTimeoutTimer = Timer(const Duration(seconds: 6), () {
//         if (mounted && _isDiscovering) {
//           print('⏰ Discovery timeout (6s) - stopping for optimal performance');
//           _stopDiscovery();
//         }
//       });
//     } catch (e) {
//       print('❌ Discovery error: $e');
//       if (e.toString().contains('STATUS_ALREADY_DISCOVERING')) {
//         print('✅ Already discovering (continuing)');
//         setState(() => _isDiscovering = true);
//       }
//     }
//   }

//   Future<void> _stopDiscovery() async {
//     try {
//       await Nearby().stopDiscovery();
//       setState(() => _isDiscovering = false);
//       _discoveryTimeoutTimer?.cancel();
//     } catch (e) {
//       print('⚠️ Error stopping discovery: $e');
//     }
//   }

//   // OPTIMIZED: Cache successful endpoints
//   Future<void> _cacheEndpoint(String endpointId, String deviceName) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       _cachedEndpoints[endpointId] = deviceName;
//       await prefs.setString('cached_endpoints', json.encode(_cachedEndpoints));
//       print('💾 Cached: $deviceName');
//     } catch (e) {
//       print('⚠️ Error caching endpoint: $e');
//     }
//   }

//   // OPTIMIZED: Try cached endpoints first
//   Future<void> _tryConnectToCachedEndpoints() async {
//     for (final entry in _cachedEndpoints.entries) {
//       if (!_connectedDevices.containsKey(entry.key)) {
//         print('🔄 Trying cached: ${entry.value}');
//         _requestConnection(entry.key, entry.value);
//       }
//     }
//   }

//   Future<void> _requestConnection(String endpointId, String deviceName) async {
//     if (_connectedDevices.containsKey(endpointId) ||
//         _connectionAttempts.contains(endpointId)) return;

//     _connectionAttempts.add(endpointId);

//     try {
//       await Nearby().requestConnection(
//         _myDeviceId,
//         endpointId,
//         onConnectionInitiated: (String id, ConnectionInfo info) {
//           _acceptConnection(id, info);
//         },
//         onConnectionResult: (String id, Status status) {
//           _connectionAttempts.remove(id);
//           if (status == Status.CONNECTED) {
//             setState(() => _connectedDevices[id] = deviceName);
//             _showMessage('✅ Connected to $deviceName');
//           }
//         },
//         onDisconnected: (String id) {
//           setState(() => _connectedDevices.remove(id));
//           _connectionAttempts.remove(id);
//         },
//       );
//     } catch (e) {
//       _connectionAttempts.remove(endpointId);
//       if (e.toString().contains('STATUS_ALREADY_CONNECTED_TO_ENDPOINT')) {
//         setState(() => _connectedDevices[endpointId] = deviceName);
//       }
//     }
//   }

//   Future<void> _acceptConnection(String endpointId, ConnectionInfo info) async {
//     try {
//       await Nearby().acceptConnection(
//         endpointId,
//         onPayLoadRecieved: (String endpointId, Payload payload) {
//           if (payload.type == PayloadType.BYTES) {
//             final receivedData = String.fromCharCodes(payload.bytes!);
//             _handleReceivedSOS(receivedData, info.endpointName);
//           }
//         },
//       );

//       setState(() => _connectedDevices[endpointId] = info.endpointName);
//       print('✅ Accepted connection from: ${info.endpointName}');
//     } catch (e) {
//       print('❌ Accept connection error: $e');
//     }
//   }

//   // OPTIMIZED: Handle received SOS with duplicate prevention and forwarding support
//   void _handleReceivedSOS(String receivedData, String fromDevice) {
//     String displayMessage = receivedData;
//     String? sosId;

//     // Try parsing as optimized JSON SOS
//     try {
//       final data = json.decode(receivedData);
//       if (data is Map) {
//         sosId = data['id']?.toString();

//         // OPTIMIZED: Prevent duplicate SOS processing
//         if (sosId != null && _receivedSosIds.contains(sosId)) {
//           print('🚫 Duplicate SOS blocked: $sosId');
//           return;
//         }

//         if (sosId != null) {
//           _receivedSosIds.add(sosId);
//         }

//         if (data['type'] == 'SOS') {
//           final time = DateTime.fromMillisecondsSinceEpoch(data['time']);
//           displayMessage = '''🆘 EMERGENCY RECEIVED 🆘
// ${data['message'] ?? data['msg']}
// Origin: ${data['origin'] ?? data['id']}
// Via: $fromDevice
// Location: ${data['location'] ?? data['loc']}
// Time: ${time.toString().substring(0, 19)}''';
//         }
//       }
//     } catch (e) {
//       // Legacy text format - generate unique ID
//       sosId = 'legacy_${DateTime.now().millisecondsSinceEpoch}';
//       if (_receivedSosIds.contains(sosId)) return;
//       _receivedSosIds.add(sosId);
//     }

//     // Store for potential forwarding
//     _lastReceivedSos = receivedData;

//     setState(() {
//       _messages.insert(0, 'EMERGENCY RECEIVED: $displayMessage');
//     });

//     _showSOSNotification(displayMessage, fromDevice);
//     _showEmergencyAlert(displayMessage, fromDevice);

//     print('📨 SOS processed: $sosId from $fromDevice');
//   }

//   Future<void> _showSOSNotification(String message, String fromDevice) async {
//     const AndroidNotificationDetails androidDetails =
//         AndroidNotificationDetails(
//       'sos_alerts',
//       'SOS Emergency Alerts',
//       channelDescription: 'Critical SOS alerts',
//       importance: Importance.max,
//       priority: Priority.high,
//       ongoing: true,
//       autoCancel: false,
//       colorized: true,
//       color: Color(0xFFFF0000),
//       enableVibration: true,
//       playSound: true,
//       actions: [
//         AndroidNotificationAction('help', '🆘 I Can Help',
//             showsUserInterface: true),
//         AndroidNotificationAction('forward', '📢 Forward Alert',
//             showsUserInterface: false),
//       ],
//     );

//     await flutterLocalNotificationsPlugin.show(
//       DateTime.now().millisecondsSinceEpoch.remainder(100000),
//       '🚨 EMERGENCY from $fromDevice',
//       message.length > 100 ? '${message.substring(0, 100)}...' : message,
//       const NotificationDetails(android: androidDetails),
//       payload: 'sos_alert',
//     );
//   }

//   Future<void> _broadcastSOS() async {
//     if (_isSOSActive) return;

//     setState(() => _isSOSActive = true);

//     try {
//       await _getCurrentLocation();

//       // OPTIMIZED: Ultra-lightweight JSON payload with unique ID for multi-hop
//       final sosId =
//           'sos_${_myDeviceId}_${DateTime.now().millisecondsSinceEpoch}';
//       final sosData = {
//         'id': sosId, // Unique SOS ID for duplicate prevention
//         'type': 'SOS',
//         'origin': _myDeviceId,
//         'message': 'URGENT HELP NEEDED!',
//         'location': _currentLocation,
//         'timestamp': DateTime.now().millisecondsSinceEpoch,
//       };

//       final sosMessage = json.encode(sosData);
//       print('📤 SOS payload: ${sosMessage.length} bytes, ID: $sosId');

//       // Add to our own received list to prevent echo
//       _receivedSosIds.add(sosId);

//       if (_connectedDevices.isEmpty) {
//         _showMessage(
//             '⚠️ No devices connected - broadcasting when devices found...');
//       }

//       int successCount = 0;
//       for (String deviceId in _connectedDevices.keys) {
//         try {
//           await Nearby().sendBytesPayload(
//               deviceId, Uint8List.fromList(utf8.encode(sosMessage)));
//           successCount++;
//           print('🚀 SOS sent to: ${_connectedDevices[deviceId]}');
//         } catch (e) {
//           print('❌ Failed to send SOS to $deviceId: $e');
//         }
//       }

//       final displayMessage = '''🆘 EMERGENCY SOS BROADCAST 🆘
// ID: $sosId
// I NEED HELP URGENTLY!
// Location: $_currentLocation
// Time: ${DateTime.now().toString().substring(0, 19)}
// Device: $_myDeviceId''';

//       setState(() {
//         _messages.insert(0, 'SOS BROADCASTED: $displayMessage');
//       });

//       if (successCount > 0) {
//         _showMessage(
//             '🆘 SOS sent to $successCount devices! Multi-hop enabled.');
//       } else {
//         _showMessage('🆘 SOS ready - will broadcast when devices connect');
//       }
//     } catch (e) {
//       _showMessage('❌ SOS Error: $e');
//     } finally {
//       setState(() => _isSOSActive = false);
//     }
//   }

//   // Multi-hop forwarding method
//   Future<void> _forwardLastSOS() async {
//     if (_lastReceivedSos == null ||
//         _lastReceivedSos!.isEmpty ||
//         _connectedDevices.isEmpty) {
//       _showMessage('❌ No SOS to forward or no devices connected');
//       return;
//     }

//     final sosToForward = _lastReceivedSos!;

//     try {
//       int forwardCount = 0;
//       for (String deviceId in _connectedDevices.keys) {
//         try {
//           await Nearby().sendBytesPayload(
//               deviceId, Uint8List.fromList(utf8.encode(sosToForward)));
//           forwardCount++;
//         } catch (e) {
//           print('❌ Failed to forward SOS to $deviceId: $e');
//         }
//       }

//       _showMessage('📡 SOS forwarded to $forwardCount devices');
//       setState(() {
//         _messages.insert(0,
//             'FORWARDED SOS to $forwardCount devices at ${DateTime.now().toString().substring(11, 19)}');
//       });
//     } catch (e) {
//       _showMessage('❌ Forward error: $e');
//     }
//   }

//   void _showEmergencyAlert(String message, String fromDevice) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         backgroundColor: Colors.red[50],
//         title: Row(
//           children: [
//             const Icon(Icons.emergency, color: Colors.red, size: 32),
//             const SizedBox(width: 12),
//             Expanded(
//                 child: Text('🚨 EMERGENCY from $fromDevice',
//                     style: const TextStyle(
//                         color: Colors.red, fontWeight: FontWeight.bold))),
//           ],
//         ),
//         content: SingleChildScrollView(
//           child: Text(message, style: const TextStyle(fontSize: 16)),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _sendHelpResponse(fromDevice);
//             },
//             child: const Text('🆘 I Can Help',
//                 style: TextStyle(
//                     color: Colors.green, fontWeight: FontWeight.bold)),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _sendHelpResponse(String targetDevice) async {
//     try {
//       final response = '''✅ HELP RESPONSE ✅
// I can assist you!
// My location: $_currentLocation
// Time: ${DateTime.now().toString().substring(0, 19)}
// From: $_myDeviceId
// I'm coming to help!''';

//       for (String deviceId in _connectedDevices.keys) {
//         await Nearby().sendBytesPayload(
//             deviceId, Uint8List.fromList(utf8.encode(response)));
//       }

//       _showMessage('✅ Help response sent to all devices');
//     } catch (e) {
//       _showMessage('❌ Failed to send help response');
//     }
//   }

//   void _showMessage(String message) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content:
//             Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
//         backgroundColor: Colors.blue,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('🆘 Emergency SOS'),
//         backgroundColor: Colors.red,
//         foregroundColor: Colors.white,
//         actions: [
//           Icon(_connectedDevices.isNotEmpty ? Icons.wifi : Icons.wifi_off),
//           const SizedBox(width: 16),
//         ],
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Status Card
//             Container(
//               margin: const EdgeInsets.all(16),
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.green[50],
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: Colors.green, width: 2),
//               ),
//               child: Row(
//                 children: [
//                   const Icon(Icons.check_circle, color: Colors.green, size: 24),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text('Connected: ${_connectedDevices.length} devices',
//                             style: const TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.green)),
//                         Text(_currentLocation,
//                             style: TextStyle(color: Colors.grey[700])),
//                         Text(
//                             'ID: ${_myDeviceId.length > 15 ? _myDeviceId.substring(0, 15) : _myDeviceId}...',
//                             style: TextStyle(
//                                 color: Colors.grey[600], fontSize: 12)),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             // Background Service Toggle
//             Container(
//               margin: const EdgeInsets.symmetric(horizontal: 16),
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: _backgroundServiceRunning
//                     ? Colors.green[50]
//                     : Colors.grey[100],
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(
//                   color: _backgroundServiceRunning ? Colors.green : Colors.grey,
//                   width: 2,
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   Icon(
//                     _backgroundServiceRunning
//                         ? Icons.play_circle_filled
//                         : Icons.pause_circle_filled,
//                     color:
//                         _backgroundServiceRunning ? Colors.green : Colors.grey,
//                     size: 24,
//                   ),
//                   const SizedBox(width: 12),
//                   const Expanded(
//                     child: Text('Background SOS monitoring active',
//                         style: TextStyle(fontWeight: FontWeight.bold)),
//                   ),
//                   Switch(
//                     value: _backgroundServiceRunning,
//                     onChanged: (_) => _toggleBackgroundService(),
//                     activeColor: Colors.green,
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 24),

//             // Forward SOS Button (if we have a received SOS and connections)
//             if (_lastReceivedSos != null &&
//                 _lastReceivedSos!.isNotEmpty &&
//                 _connectedDevices.isNotEmpty)
//               Container(
//                 margin: const EdgeInsets.symmetric(horizontal: 16),
//                 width: double.infinity,
//                 height: 50,
//                 child: ElevatedButton(
//                   onPressed: _forwardLastSOS,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.orange.shade700,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   child: const Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(Icons.forward, color: Colors.white),
//                       SizedBox(width: 8),
//                       Text(
//                         '📡 FORWARD LAST SOS',
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//             const SizedBox(height: 16),

//             // Emergency SOS Button
//             Expanded(
//               child: Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Icon(Icons.medical_services,
//                         size: 80, color: Colors.red),
//                     const SizedBox(height: 16),
//                     const Text('Emergency SOS System',
//                         style: TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.red)),
//                     const SizedBox(height: 8),
//                     const Text(
//                         'Broadcasts SOS to ALL nearby devices\nworks in background with notifications',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(fontSize: 14, color: Colors.grey)),
//                     const SizedBox(height: 32),

//                     // Main SOS Button
//                     GestureDetector(
//                       onTap: _broadcastSOS,
//                       child: Container(
//                         width: 200,
//                         height: 200,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: Colors.red,
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.red.withOpacity(0.3),
//                               blurRadius: 20,
//                               spreadRadius: 10,
//                             ),
//                           ],
//                         ),
//                         child: _isSOSActive
//                             ? const Center(
//                                 child: CircularProgressIndicator(
//                                   valueColor: AlwaysStoppedAnimation<Color>(
//                                       Colors.white),
//                                 ),
//                               )
//                             : const Column(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Icon(Icons.medical_services,
//                                       color: Colors.white, size: 48),
//                                   SizedBox(height: 8),
//                                   Text('SOS\nEMERGENCY',
//                                       textAlign: TextAlign.center,
//                                       style: TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 20,
//                                         fontWeight: FontWeight.bold,
//                                       )),
//                                 ],
//                               ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             // Emergency Messages Panel
//             if (_messages.isNotEmpty) ...[
//               const Divider(),
//               Container(
//                 height: 150,
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         const Icon(Icons.message, color: Colors.blue),
//                         const SizedBox(width: 8),
//                         Text('Emergency Messages (${_messages.length})',
//                             style: const TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.blue)),
//                       ],
//                     ),
//                     const SizedBox(height: 8),
//                     Expanded(
//                       child: ListView.builder(
//                         itemCount: _messages.length,
//                         itemBuilder: (context, index) {
//                           final message = _messages[index];
//                           return Container(
//                             margin: const EdgeInsets.only(bottom: 8),
//                             padding: const EdgeInsets.all(8),
//                             decoration: BoxDecoration(
//                               color: Colors.red[50],
//                               borderRadius: BorderRadius.circular(8),
//                               border: Border.all(color: Colors.red[200]!),
//                             ),
//                             child: Text(
//                               message.length > 100
//                                   ? '${message.substring(0, 100)}...'
//                                   : message,
//                               style: const TextStyle(fontSize: 12),
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _discoveryTimer?.cancel();
//     _discoveryTimeoutTimer?.cancel();
//     _connectionHealthTimer?.cancel();
//     _locationUpdateTimer?.cancel();
//     FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);
//     FlutterForegroundTask.stopService();
//     Nearby().stopDiscovery();
//     Nearby().stopAdvertising();
//     super.dispose();
//   }
// }
