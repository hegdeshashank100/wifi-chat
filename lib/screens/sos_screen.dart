// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:nearby_connections/nearby_connections.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_foreground_task/flutter_foreground_task.dart';

// // Background task handler for SOS scanning
// @pragma('vm:entry-point')
// void startCallback() {
//   FlutterForegroundTask.setTaskHandler(SOSBackgroundHandler());
// }

// class SOSBackgroundHandler extends TaskHandler {
//   @override
//   Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
//     print('🔄 SOS Background service started');
//   }

//   @override
//   void onRepeatEvent(DateTime timestamp) {
//     // This runs every few seconds to actively scan for SOS signals
//     print(
//         '🔄 Background SOS scan active: ${DateTime.now().toString().substring(11, 19)}');

//     FlutterForegroundTask.updateService(
//       notificationTitle: '🆘 SOS Scanner Active',
//       notificationText:
//           'Scanning for emergency signals - ${DateTime.now().toString().substring(11, 19)}',
//     );

//     // Try to trigger a discovery scan if possible
//     FlutterForegroundTask.sendDataToTask({'action': 'scan'});
//   }

//   @override
//   Future<void> onDestroy(DateTime timestamp) async {
//     print('🛑 SOS Background service stopped');
//   }
// }

// class SOSScreen extends StatefulWidget {
//   const SOSScreen({super.key});

//   @override
//   State<SOSScreen> createState() => _SOSScreenState();
// }

// class _SOSScreenState extends State<SOSScreen> {
//   final Strategy strategy = Strategy.P2P_CLUSTER;
//   final String serviceId = "com.example.sos_emergency";

//   late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

//   bool _isSOSActive = false;
//   bool _isAdvertising = false;
//   bool _isDiscovering = false;
//   bool _backgroundServiceRunning = false;
//   List<String> _connectedDevices = [];
//   List<String> _messages = [];
//   String _currentLocation = 'Getting location...';
//   String _myDeviceId = '';
//   Timer? _discoveryTimer;
//   Timer? _connectionHealthTimer;

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
//       print('🚨 Error initializing SOS app: $e');
//       // Continue without crashing - some features may not work
//     }
//   }

//   Future<void> _initializeForegroundTask() async {
//     try {
//       FlutterForegroundTask.init(
//         androidNotificationOptions: AndroidNotificationOptions(
//           channelId: 'sos_foreground_service',
//           channelName: 'SOS Foreground Service',
//           channelDescription:
//               'This notification appears when SOS service is running.',
//           onlyAlertOnce: true,
//         ),
//         iosNotificationOptions: const IOSNotificationOptions(),
//         foregroundTaskOptions: ForegroundTaskOptions(
//           eventAction: ForegroundTaskEventAction.repeat(
//               3000), // More frequent: every 3 seconds
//           autoRunOnBoot: true,
//           allowWakeLock: true,
//           allowWifiLock: true,
//         ),
//       );

//       // Listen for data from background task
//       FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
//     } catch (e) {
//       print('🚨 Error initializing foreground task: $e');
//     }
//   }

//   void _onReceiveTaskData(Object data) {
//     print('📡 Received task data: $data');
//     if (data is Map && data['action'] == 'scan') {
//       // Trigger a discovery scan from background
//       _restartDiscovery();
//     }
//   }

//   Future<void> _initializeNotifications() async {
//     try {
//       flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

//       const AndroidInitializationSettings initializationSettingsAndroid =
//           AndroidInitializationSettings('@mipmap/ic_launcher');

//       const InitializationSettings initializationSettings =
//           InitializationSettings(
//         android: initializationSettingsAndroid,
//       );

//       await flutterLocalNotificationsPlugin.initialize(
//         initializationSettings,
//         onDidReceiveNotificationResponse: (details) {
//           // Handle notification tap
//           if (details.payload == 'sos_alert') {
//             _showEmergencyAlert(
//                 details.input ?? 'SOS Alert received', 'Nearby Device');
//           }
//         },
//       );

//       // Create notification channel
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
//       print('🚨 Error initializing notifications: $e');
//     }
//   }

//   Future<void> _initializeSOSSystem() async {
//     await _requestPermissions();
//     await _getCurrentLocation();
//     _myDeviceId = 'SOS_Device_${Random().nextInt(10000)}';
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
//         return;
//       }

//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission == LocationPermission.denied) {
//           _currentLocation = 'Location permission denied';
//           return;
//         }
//       }

//       Position position = await Geolocator.getCurrentPosition();
//       setState(() {
//         _currentLocation = 'Lat: ${position.latitude.toStringAsFixed(4)}, '
//             'Lng: ${position.longitude.toStringAsFixed(4)}';
//       });
//     } catch (e) {
//       _currentLocation = 'Location error: $e';
//     }
//   }

//   void _startSOSServices() {
//     _startAdvertising();
//     _startDiscovery();

//     // More frequent discovery every 10 seconds for better detection
//     _discoveryTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
//       if (mounted) {
//         print('🔄 Restarting discovery cycle...');
//         _restartDiscovery();
//       }
//     });

//     // Connection health check every 30 seconds
//     _connectionHealthTimer =
//         Timer.periodic(const Duration(seconds: 30), (timer) {
//       if (mounted) {
//         _checkConnectionHealth();
//       }
//     });
//   }

//   void _checkConnectionHealth() {
//     print('🏥 Connection health check: ${_connectedDevices.length} devices');

//     // If no devices connected for a while, try restarting services
//     if (_connectedDevices.isEmpty) {
//       print('⚠️ No connections detected, attempting service restart...');
//       _restartServices();
//     }
//   }

//   Future<void> _restartServices() async {
//     try {
//       print('🔄 Restarting SOS services...');

//       // Stop current services
//       await Nearby().stopAdvertising();
//       await Nearby().stopDiscovery();

//       await Future.delayed(const Duration(milliseconds: 1000));

//       // Restart services
//       await _startAdvertising();
//       await _startDiscovery();

//       print('✅ SOS services restarted');
//     } catch (e) {
//       print('❌ Error restarting services: $e');
//     }
//   }

//   Future<void> _restartDiscovery() async {
//     try {
//       // Stop current discovery
//       await Nearby().stopDiscovery();
//       await Future.delayed(const Duration(milliseconds: 500));

//       // Restart discovery
//       await _startDiscovery();
//     } catch (e) {
//       print('❌ Error restarting discovery: $e');
//     }
//   }

//   Future<void> _toggleBackgroundService() async {
//     if (_backgroundServiceRunning) {
//       // Stop background service
//       try {
//         await FlutterForegroundTask.stopService();
//         setState(() {
//           _backgroundServiceRunning = false;
//         });
//         _showMessage('🛑 Background SOS service stopped', Colors.orange);
//         print('🛑 Background service stopped successfully');
//       } catch (e) {
//         print('❌ Error stopping background service: $e');
//         _showMessage('❌ Error stopping background service', Colors.red);
//       }
//     } else {
//       // Start background service
//       try {
//         // Check if service can be started
//         bool isIgnoringBatteryOptimizations =
//             await FlutterForegroundTask.isIgnoringBatteryOptimizations;

//         if (!isIgnoringBatteryOptimizations) {
//           await FlutterForegroundTask.requestIgnoreBatteryOptimization();
//         }

//         ServiceRequestResult result = await FlutterForegroundTask.startService(
//           serviceId: 100,
//           notificationTitle: '🆘 SOS Scanner Active',
//           notificationText: 'Monitoring for emergency signals in background',
//           callback: startCallback,
//         );

//         print("Foreground service started: $result ✅");

//         // Assume success if no exception thrown
//         setState(() {
//           _backgroundServiceRunning = true;
//         });
//         _showMessage('✅ Background SOS service started', Colors.green);

//         // Also restart discovery to ensure fresh connections
//         _restartDiscovery();
//       } catch (e) {
//         print("Failed to start foreground service: $e ❌");
//         _showMessage('❌ Failed to start background SOS service', Colors.red);
//       }
//     }
//   }

//   Future<void> _startAdvertising() async {
//     if (_isAdvertising) {
//       print('⚠️ Already advertising, skipping...');
//       return;
//     }

//     try {
//       print(
//           '📢 Starting advertising with name: $_myDeviceId, serviceId: $serviceId');

//       await Nearby().startAdvertising(
//         _myDeviceId,
//         strategy,
//         onConnectionInitiated: (String id, ConnectionInfo info) {
//           print('📡 Connection initiated from: ${info.endpointName} (id: $id)');
//           print(
//               '📡 Connection info - isIncoming: ${info.isIncomingConnection}');
//           _acceptConnection(id, info);
//         },
//         onConnectionResult: (String id, Status status) {
//           print('🔗 Connection result for $id: $status');
//           if (status == Status.CONNECTED) {
//             setState(() {
//               if (!_connectedDevices.contains(id)) {
//                 _connectedDevices.add(id);
//               }
//             });
//             print(
//                 '✅ Device connected: $id (Total: ${_connectedDevices.length})');
//             _showMessage('✅ Connected to emergency device', Colors.green);
//           } else {
//             print('❌ Connection failed: $id - $status');
//             _showMessage('❌ Connection failed to device', Colors.red);
//           }
//         },
//         onDisconnected: (String id) {
//           setState(() {
//             _connectedDevices.remove(id);
//           });
//           print(
//               '🔌 Device disconnected: $id (Remaining: ${_connectedDevices.length})');
//           _showMessage('🔌 Device disconnected', Colors.orange);
//         },
//         serviceId: serviceId,
//       );

//       setState(() => _isAdvertising = true);
//       print('📢 Started advertising as: $_myDeviceId');
//       _showMessage('📢 Broadcasting emergency signal', Colors.blue);
//     } catch (e) {
//       print('❌ Advertising error: $e');

//       // Handle specific error case
//       if (e.toString().contains('STATUS_ALREADY_ADVERTISING')) {
//         print('✅ Already advertising (treating as success)');
//         setState(() => _isAdvertising = true);
//         _showMessage('📢 Already broadcasting emergency signal', Colors.blue);
//       } else {
//         _showMessage('❌ Failed to start broadcasting', Colors.red);
//         setState(() => _isAdvertising = false);
//       }
//     }
//   }

//   Future<void> _startDiscovery() async {
//     if (_isDiscovering) {
//       print('⚠️ Already discovering, skipping...');
//       return;
//     }

//     try {
//       print('🔍 Starting discovery...');

//       await Nearby().startDiscovery(
//         _myDeviceId,
//         strategy,
//         onEndpointFound: (String id, String name, String serviceId) {
//           print('🔍 Found device: $name ($id) - ServiceId: $serviceId');

//           // Only connect to devices with matching service ID
//           if (serviceId == this.serviceId) {
//             print('✅ Valid SOS device found, attempting connection...');
//             // Auto-connect to discovered SOS devices
//             _requestConnection(id, name);
//           } else {
//             print('⚠️ Device found but wrong service ID: $serviceId');
//           }
//         },
//         onEndpointLost: (endpointId) {
//           print('📵 Lost device: $endpointId');
//           setState(() {
//             _connectedDevices.remove(endpointId);
//           });
//           _showMessage('📵 Lost connection to device', Colors.orange);
//         },
//         serviceId: serviceId,
//       );

//       setState(() => _isDiscovering = true);
//       print('🔍 Discovery started successfully');
//     } catch (e) {
//       print('❌ Discovery error: $e');

//       // Handle specific error case
//       if (e.toString().contains('STATUS_ALREADY_DISCOVERING')) {
//         print('✅ Already discovering (treating as success)');
//         setState(() => _isDiscovering = true);
//       } else {
//         setState(() => _isDiscovering = false);
//       }
//     }
//   }

//   Future<void> _requestConnection(String endpointId, String deviceName) async {
//     try {
//       // Check if already connected to prevent duplicate connections
//       if (_connectedDevices.contains(endpointId)) {
//         print('⚠️ Already connected to: $deviceName ($endpointId)');
//         return;
//       }

//       print('🤝 Requesting connection to: $deviceName (id: $endpointId)');

//       await Nearby().requestConnection(
//         _myDeviceId,
//         endpointId,
//         onConnectionInitiated: (String id, ConnectionInfo info) {
//           print('🔗 Connection initiated with: ${info.endpointName} (id: $id)');
//           print(
//               '🔗 Connection info - isIncoming: ${info.isIncomingConnection}');
//           _acceptConnection(id, info);
//         },
//         onConnectionResult: (String id, Status status) {
//           print('🔗 Connection result for $deviceName ($id): $status');
//           if (status == Status.CONNECTED) {
//             setState(() {
//               if (!_connectedDevices.contains(id)) {
//                 _connectedDevices.add(id);
//               }
//             });
//             print(
//                 '✅ Successfully connected to: $deviceName (id: $id) - Total: ${_connectedDevices.length}');
//             _showMessage('✅ Connected to $deviceName', Colors.green);
//           } else {
//             print('❌ Connection failed to: $deviceName - $status');
//             _showMessage('❌ Failed to connect to $deviceName', Colors.red);
//           }
//         },
//         onDisconnected: (String id) {
//           setState(() {
//             _connectedDevices.remove(id);
//           });
//           print(
//               '🔌 Disconnected from: $deviceName (Remaining: ${_connectedDevices.length})');
//           _showMessage('🔌 Disconnected from $deviceName', Colors.orange);
//         },
//       );
//     } catch (e) {
//       print('❌ Connection request error to $deviceName: $e');
//       _showMessage('❌ Error connecting to $deviceName', Colors.red);
//     }
//   }

//   Future<void> _acceptConnection(String endpointId, ConnectionInfo info) async {
//     try {
//       await Nearby().acceptConnection(
//         endpointId,
//         onPayLoadRecieved: (String endpointId, Payload payload) {
//           if (payload.type == PayloadType.BYTES) {
//             final receivedData = String.fromCharCodes(payload.bytes!);
//             print('📨 Received: $receivedData');

//             if (receivedData.contains('🆘') ||
//                 receivedData.contains('SOS') ||
//                 receivedData.contains('FORWARDED')) {
//               setState(() {
//                 _messages.insert(0, 'EMERGENCY RECEIVED: $receivedData');
//               });

//               // Show system notification for SOS
//               _showSOSNotification(receivedData, info.endpointName);

//               // Show in-app alert
//               _showEmergencyAlert(receivedData, info.endpointName);
//             }
//           }
//         },
//       );
//       print('🤝 Accepted connection from: ${info.endpointName}');
//     } catch (e) {
//       print('❌ Accept connection error: $e');
//     }
//   }

//   Future<void> _showSOSNotification(String message, String fromDevice) async {
//     const AndroidNotificationDetails androidPlatformChannelSpecifics =
//         AndroidNotificationDetails(
//       'sos_alerts',
//       'SOS Emergency Alerts',
//       channelDescription: 'Critical alerts for SOS emergencies',
//       importance: Importance.max,
//       priority: Priority.high,
//       showWhen: true,
//       enableVibration: true,
//       playSound: true,
//       actions: [
//         AndroidNotificationAction(
//           'help_action',
//           'I CAN HELP',
//           icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
//           showsUserInterface: true,
//         ),
//         AndroidNotificationAction(
//           'forward_action',
//           'FORWARD SOS',
//           icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
//           showsUserInterface: false,
//         ),
//       ],
//     );

//     const NotificationDetails platformChannelSpecifics =
//         NotificationDetails(android: androidPlatformChannelSpecifics);

//     await flutterLocalNotificationsPlugin.show(
//       DateTime.now().millisecondsSinceEpoch.remainder(100000),
//       '🆘 EMERGENCY ALERT from $fromDevice',
//       message,
//       platformChannelSpecifics,
//       payload: 'sos_alert',
//     );
//   }

//   Future<void> _broadcastSOS() async {
//     if (_isSOSActive) return;

//     setState(() => _isSOSActive = true);

//     try {
//       await _getCurrentLocation(); // Update location

//       final sosMessage = '''🆘 EMERGENCY SOS ALERT 🆘
// I NEED HELP URGENTLY!
// Location: $_currentLocation
// Time: ${DateTime.now().toString().substring(0, 19)}
// Device: $_myDeviceId
// This is an automated emergency broadcast.
// Please respond if you can assist!''';

//       if (_connectedDevices.isEmpty) {
//         _showMessage(
//             '⚠️ No connected devices. Broadcasting anyway...', Colors.orange);
//       }

//       // Send SOS to ALL connected devices
//       int successCount = 0;
//       for (String deviceId in _connectedDevices) {
//         try {
//           await Nearby().sendBytesPayload(
//               deviceId, Uint8List.fromList(utf8.encode(sosMessage)));
//           successCount++;
//           print('✅ SOS sent to: $deviceId');
//         } catch (e) {
//           print('❌ Failed to send SOS to $deviceId: $e');
//         }
//       }

//       setState(() {
//         _messages.insert(0, 'SOS BROADCASTED: $sosMessage');
//       });

//       if (successCount > 0) {
//         _showMessage(
//             '🆘 SOS sent to $successCount connected devices!', Colors.red);
//       } else {
//         _showMessage(
//             '📡 SOS broadcast attempted. Searching for nearby devices...',
//             Colors.blue);
//       }
//     } catch (e) {
//       _showMessage('❌ SOS Error: $e', Colors.red);
//     } finally {
//       setState(() => _isSOSActive = false);
//     }
//   }

//   Future<void> _forwardSOS(String sosMessage, String originalSender) async {
//     // Forward the SOS message to all connected devices EXCEPT the original sender
//     final forwardedMessage = '''🔄 FORWARDED SOS ALERT 🔄
// Original from: $originalSender
// Forwarded by: $_myDeviceId
// Location: $_currentLocation
// Time: ${DateTime.now().toString().substring(0, 19)}

// Original Message:
// $sosMessage''';

//     int forwardCount = 0;
//     for (String deviceId in _connectedDevices) {
//       // Don't forward back to the original sender or devices with similar names
//       if (originalSender.contains(_myDeviceId.split('_').last) ||
//           deviceId.contains(originalSender.split('_').last)) {
//         print('🚫 Skipping forward to original sender: $deviceId');
//         continue;
//       }

//       try {
//         await Nearby().sendBytesPayload(
//             deviceId, Uint8List.fromList(utf8.encode(forwardedMessage)));
//         forwardCount++;
//         print('📤 Forwarded SOS to: $deviceId');
//       } catch (e) {
//         print('❌ Failed to forward SOS to $deviceId: $e');
//       }
//     }

//     _showMessage('📤 SOS forwarded to $forwardCount devices', Colors.blue);
//   }

//   void _showEmergencyAlert(String message, String fromDevice) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         backgroundColor: Colors.red[50],
//         title: Row(
//           children: [
//             Icon(Icons.warning, color: Colors.red, size: 30),
//             const SizedBox(width: 8),
//             Expanded(
//               child: Text(
//                 '🆘 EMERGENCY ALERT',
//                 style:
//                     TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
//               ),
//             ),
//           ],
//         ),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text('From: $fromDevice',
//                   style: const TextStyle(fontWeight: FontWeight.bold)),
//               const SizedBox(height: 8),
//               Text(message, style: const TextStyle(fontSize: 16)),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: Text('DISMISS',
//                 style:
//                     TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
//             onPressed: () {
//               Navigator.of(context).pop();
//               _forwardSOS(message, fromDevice);
//             },
//             child: const Text('FORWARD SOS',
//                 style: TextStyle(
//                     color: Colors.white, fontWeight: FontWeight.bold)),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//             onPressed: () {
//               Navigator.of(context).pop();
//               _sendHelpResponse(fromDevice);
//             },
//             child: const Text('I CAN HELP',
//                 style: TextStyle(
//                     color: Colors.white, fontWeight: FontWeight.bold)),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _sendHelpResponse(String targetDevice) async {
//     try {
//       final response = '''ℹ️ HELP RESPONSE ℹ️
// I received your SOS alert and I can help!
// My location: $_currentLocation
// Time: ${DateTime.now().toString().substring(0, 19)}
// From: $_myDeviceId
// I'm coming to assist you!''';

//       // Send response to all connected devices (broadcast response)
//       for (String deviceId in _connectedDevices) {
//         await Nearby().sendBytesPayload(
//             deviceId, Uint8List.fromList(utf8.encode(response)));
//       }

//       _showMessage(
//           '✅ Help response sent to all connected devices', Colors.green);
//     } catch (e) {
//       _showMessage('❌ Failed to send help response', Colors.red);
//     }
//   }

//   void _showMessage(String message, Color color) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content:
//             Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
//         backgroundColor: color,
//         duration: const Duration(seconds: 4),
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
//           Icon(
//             _connectedDevices.isNotEmpty ? Icons.wifi : Icons.wifi_off,
//             color:
//                 _connectedDevices.isNotEmpty ? Colors.white : Colors.red[300],
//           ),
//           Text('${_connectedDevices.length}',
//               style: const TextStyle(fontSize: 12)),
//           const SizedBox(width: 16),
//         ],
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Status Bar
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(12),
//               color: _connectedDevices.isNotEmpty
//                   ? Colors.green.withOpacity(0.1)
//                   : Colors.blue.withOpacity(0.1),
//               child: Column(
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(
//                         _isAdvertising && _isDiscovering
//                             ? Icons.radar
//                             : Icons.wifi_off,
//                         color: _isAdvertising && _isDiscovering
//                             ? Colors.green
//                             : Colors.orange,
//                         size: 18,
//                       ),
//                       const SizedBox(width: 6),
//                       Expanded(
//                         child: Text(
//                           _connectedDevices.isNotEmpty
//                               ? 'Connected: ${_connectedDevices.length} devices'
//                               : _isAdvertising && _isDiscovering
//                                   ? 'Ready - Scanning nearby devices...'
//                                   : 'Initializing SOS...',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 14,
//                             color: _connectedDevices.isNotEmpty
//                                 ? Colors.green[700]
//                                 : Colors.blue[700],
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 3),
//                   Text(_currentLocation,
//                       style: TextStyle(fontSize: 11, color: Colors.grey[600])),
//                   Text('ID: ${_myDeviceId.split('_').last}',
//                       style: TextStyle(fontSize: 9, color: Colors.grey[500])),
//                 ],
//               ),
//             ),

//             // Background Service Toggle
//             Container(
//               margin: const EdgeInsets.all(12),
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: _backgroundServiceRunning
//                     ? Colors.green[50]
//                     : Colors.grey[50],
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(
//                     color:
//                         _backgroundServiceRunning ? Colors.green : Colors.grey),
//               ),
//               child: Row(
//                 children: [
//                   Icon(
//                     _backgroundServiceRunning
//                         ? Icons.play_circle
//                         : Icons.pause_circle,
//                     color:
//                         _backgroundServiceRunning ? Colors.green : Colors.grey,
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       _backgroundServiceRunning
//                           ? '✅ Background SOS monitoring active'
//                           : '⏸️ Background monitoring paused',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: _backgroundServiceRunning
//                             ? Colors.green[700]
//                             : Colors.grey[700],
//                       ),
//                     ),
//                   ),
//                   Switch(
//                     value: _backgroundServiceRunning,
//                     onChanged: (value) => _toggleBackgroundService(),
//                     activeColor: Colors.green,
//                   ),
//                 ],
//               ),
//             ),

//             // Main Content Area
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                 child: Column(
//                   children: [
//                     const SizedBox(height: 8),

//                     // Title Section
//                     Icon(Icons.emergency, size: 60, color: Colors.red),
//                     const SizedBox(height: 12),
//                     Text(
//                       'Emergency SOS System',
//                       style: TextStyle(
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.red[700],
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 6),
//                     Text(
//                       'Broadcasts SOS to ALL nearby devices\nworks in background with notifications',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(fontSize: 13, color: Colors.grey[600]),
//                     ),

//                     const SizedBox(height: 15),

//                     // Large SOS Button
//                     GestureDetector(
//                       onTap: _broadcastSOS,
//                       child: AnimatedContainer(
//                         duration: const Duration(milliseconds: 200),
//                         width: 140,
//                         height: 140,
//                         decoration: BoxDecoration(
//                           color: _isSOSActive ? Colors.red[300] : Colors.red,
//                           shape: BoxShape.circle,
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.red.withOpacity(0.4),
//                               blurRadius: 25,
//                               spreadRadius: 8,
//                             ),
//                           ],
//                         ),
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             if (_isSOSActive)
//                               const CircularProgressIndicator(
//                                   color: Colors.white, strokeWidth: 4)
//                             else
//                               const Icon(Icons.emergency,
//                                   color: Colors.white, size: 45),
//                             const SizedBox(height: 6),
//                             Text(
//                               _isSOSActive
//                                   ? 'SENDING SOS...'
//                                   : 'SOS\nEMERGENCY',
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                               textAlign: TextAlign.center,
//                             ),
//                             if (!_isSOSActive) ...[
//                               const SizedBox(height: 3),
//                               const Text(
//                                 'Tap for Help',
//                                 style: TextStyle(
//                                     color: Colors.white70, fontSize: 11),
//                               ),
//                             ],
//                           ],
//                         ),
//                       ),
//                     ),

//                     const SizedBox(height: 15),

//                     // Action Buttons
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                       children: [
//                         Expanded(
//                           child: ElevatedButton.icon(
//                             onPressed: () {
//                               _showMessage(
//                                   '🔄 Restarting SOS services...', Colors.blue);
//                               _restartServices();
//                             },
//                             icon: const Icon(Icons.refresh, size: 18),
//                             label: const Text('Refresh'),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.blue,
//                               foregroundColor: Colors.white,
//                               padding: const EdgeInsets.symmetric(vertical: 10),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: ElevatedButton.icon(
//                             onPressed: () {
//                               // Show connected devices
//                               showDialog(
//                                 context: context,
//                                 builder: (context) => AlertDialog(
//                                   title: Text(
//                                       'Connected Devices (${_connectedDevices.length})'),
//                                   content: SizedBox(
//                                     width: double.maxFinite,
//                                     height: 200,
//                                     child: _connectedDevices.isEmpty
//                                         ? const Center(
//                                             child: Text(
//                                                 'No devices connected\n\nMake sure other devices have the app open and are nearby.',
//                                                 textAlign: TextAlign.center))
//                                         : ListView.builder(
//                                             itemCount: _connectedDevices.length,
//                                             itemBuilder: (context, index) {
//                                               final deviceId =
//                                                   _connectedDevices[index];
//                                               return ListTile(
//                                                 leading: const Icon(
//                                                     Icons.phone_android,
//                                                     color: Colors.green),
//                                                 title:
//                                                     Text('Device ${index + 1}'),
//                                                 subtitle: Text(
//                                                     '${deviceId.length > 12 ? deviceId.substring(0, 12) : deviceId}...'),
//                                               );
//                                             },
//                                           ),
//                                   ),
//                                   actions: [
//                                     TextButton(
//                                       onPressed: () => Navigator.pop(context),
//                                       child: const Text('Close'),
//                                     ),
//                                   ],
//                                 ),
//                               );
//                             },
//                             icon: const Icon(Icons.devices, size: 18),
//                             label: const Text('Show Devices'),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.green,
//                               foregroundColor: Colors.white,
//                               padding: const EdgeInsets.symmetric(vertical: 10),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),

//                     const SizedBox(height: 10),
//                   ],
//                 ),
//               ),
//             ),

//             // Messages List
//             if (_messages.isNotEmpty)
//               Container(
//                 height: 120,
//                 margin: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(12),
//                   boxShadow: [
//                     BoxShadow(
//                         color: Colors.grey.withOpacity(0.2), blurRadius: 4)
//                   ],
//                 ),
//                 child: Column(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: const BoxDecoration(
//                         color: Colors.blue,
//                         borderRadius: BorderRadius.only(
//                           topLeft: Radius.circular(12),
//                           topRight: Radius.circular(12),
//                         ),
//                       ),
//                       child: Row(
//                         children: [
//                           const Icon(Icons.message,
//                               color: Colors.white, size: 16),
//                           const SizedBox(width: 6),
//                           Text(
//                             'Emergency Messages (${_messages.length})',
//                             style: const TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 13),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Expanded(
//                       child: ListView.builder(
//                         padding: const EdgeInsets.all(6),
//                         itemCount: _messages.length,
//                         itemBuilder: (context, index) {
//                           final msg = _messages[index];
//                           final isEmergency =
//                               msg.contains('🆘') || msg.contains('EMERGENCY');

//                           return Container(
//                             margin: const EdgeInsets.symmetric(vertical: 2),
//                             padding: const EdgeInsets.all(6),
//                             decoration: BoxDecoration(
//                               color: isEmergency
//                                   ? Colors.red[50]
//                                   : Colors.grey[50],
//                               borderRadius: BorderRadius.circular(6),
//                               border: Border.all(
//                                   color: isEmergency
//                                       ? Colors.red[200]!
//                                       : Colors.grey[200]!),
//                             ),
//                             child: Text(
//                               msg,
//                               style: const TextStyle(fontSize: 10),
//                               maxLines: 2,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _discoveryTimer?.cancel();
//     _connectionHealthTimer?.cancel();
//     FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);
//     FlutterForegroundTask.stopService();
//     Nearby().stopDiscovery();
//     Nearby().stopAdvertising();
//     super.dispose();
//   }
// }
