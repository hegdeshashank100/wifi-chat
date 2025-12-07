# 📱 WiFi Chat

A Flutter mobile application that enables peer-to-peer real-time messaging between devices over local WiFi networks without requiring internet connectivity [web:12][web:15]. Perfect for offline communication in classrooms, events, or areas with limited connectivity.

![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green)
![License](https://img.shields.io/badge/License-MIT-blue)

## ✨ Features

### Core Functionality
- 🔌 **Offline Messaging** - Chat without internet access using WiFi Direct technology [web:12][web:15]
- 📡 **Peer-to-Peer** - Direct device-to-device communication with no server required [web:12][web:19]
- 🔍 **Auto Discovery** - Automatically find nearby devices on the same network [web:15][web:18]
- ⚡ **Real-time Chat** - Instant message delivery with live connection status [web:15]
- 👥 **Multi-user Support** - Connect and chat with multiple users simultaneously [web:12]
- 📤 **File Sharing** - Transfer images and files between connected devices [web:15][web:17]
- 🔐 **Secure & Private** - All data stays within your local network

### Technical Highlights
- Built with Flutter for smooth cross-platform performance [attached_file:1]
- WiFi Direct (Android) and MultipeerConnectivity (iOS) implementation [web:15][web:18]
- TCP/UDP socket communication for reliable message transmission [web:20]
- Material Design UI with responsive layouts [attached_file:1]

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** (3.0 or higher) - [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Dart SDK** (3.0+)
- **Android Studio** or **VS Code** with Flutter extensions
- **Physical Device** (Android 5.0+ or iOS 10+) - WiFi Direct requires actual hardware

### Installation

1. **Clone the repository**
git clone https://github.com/hegdeshashank100/wifi-chat.git
cd wifi_chat

text

2. **Install dependencies**
flutter pub get

text

3. **Check your Flutter setup**
flutter doctor

text

4. **Connect your device and run**
flutter run

text

### First Time Setup

If this is your first Flutter project, check out these resources from the Flutter documentation [attached_file:1]:

- 📚 [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- 🍳 [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
- 📖 [Flutter fundamentals](https://docs.flutter.dev/)
- 🎨 [Building layouts in Flutter](https://docs.flutter.dev/ui/layout)

## 📋 Platform Support

| Platform | Technology | Minimum Version | Status |
|----------|-----------|-----------------|--------|
| **Android** | WiFi Direct (P2P) [web:12][web:15] | API 21 (Android 5.0) | ✅ Fully Supported |
| **iOS** | MultipeerConnectivity [web:15][web:18] | iOS 10.0+ | ✅ Fully Supported |

## 🛠️ Technical Architecture

### Technology Stack
- **Framework**: Flutter 3.0+ / Dart 3.0+ [attached_file:1]
- **Android Connectivity**: WiFi P2P (WiFi Direct) [web:12][web:15]
- **iOS Connectivity**: MultipeerConnectivity Framework [web:15][web:18]
- **Communication Protocol**: TCP/UDP Sockets [web:20]
- **State Management**: Provider / Riverpod (recommended)
- **UI Design**: Material Design 3 [attached_file:1]

### Key Dependencies
dependencies:
flutter:
sdk: flutter
flutter_p2p_connection: ^latest # WiFi Direct for Android
wifi_direct_plugin: ^latest # Alternative P2P plugin
nearby_service: ^latest # Cross-platform nearby connectivity

text

### How It Works

1. **Discovery Phase**: App scans for nearby devices using WiFi Direct [web:12][web:15]
2. **Connection**: User selects a device and establishes P2P connection [web:12]
3. **Host/Client Model**: One device acts as host, others connect as clients [web:12][web:15]
4. **Message Exchange**: Real-time bidirectional communication over established socket [web:15][web:20]
5. **Data Transfer**: Supports text messages and binary file transfers [web:15][web:17]

## 📱 Usage

### Starting a Chat Session

**As Host:**
1. Open the app and tap "Create Room"
2. Wait for nearby devices to discover your room
3. Accept connection requests from other users

**As Client:**
1. Open the app and tap "Join Room"
2. Select a visible host from the list
3. Send connection request and start chatting

## 🔧 Configuration

### Android Permissions

Add to `android/app/src/main/AndroidManifest.xml`:

<manifest> <!-- WiFi Direct Permissions --> <uses-permission android:name="android.permission.ACCESS_WIFI_STATE" /> <uses-permission android:name="android.permission.CHANGE_WIFI_STATE" /> <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" /> <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" /> <uses-permission android:name="android.permission.NEARBY_WIFI_DEVICES" android:usesPermissionFlags="neverForLocation" />
text
<!-- Android 13+ -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<uses-feature android:name="android.hardware.wifi.direct" android:required="true"/>
</manifest> ```
iOS Permissions
Add to ios/Runner/Info.plist:

text
<dict>
    <!-- Local Network Permission -->
    <key>NSLocalNetworkUsageDescription</key>
    <string>WiFi Chat needs access to local network to discover and connect with nearby devices for peer-to-peer messaging</string>
    
    <!-- Bonjour Services -->
    <key>NSBonjourServices</key>
    <array>
        <string>_wifi-chat._tcp</string>
        <string>_wifi-chat._udp</string>
    </array>
    
    <!-- Background Modes (Optional) -->
    <key>UIBackgroundModes</key>
    <array>
        <string>fetch</string>
        <string>remote-notification</string>
    </array>
</dict>
📂 Project Structure
text
wifi_chat/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── models/                   # Data models
│   │   ├── message.dart
│   │   ├── user.dart
│   │   └── device.dart
│   ├── services/                 # Business logic
│   │   ├── wifi_service.dart    # WiFi Direct handling
│   │   ├── socket_service.dart  # Socket communication
│   │   └── storage_service.dart # Local data storage
│   ├── providers/               # State management
│   │   ├── chat_provider.dart
│   │   └── connection_provider.dart
│   ├── screens/                 # UI screens
│   │   ├── home_screen.dart
│   │   ├── chat_screen.dart
│   │   └── device_list_screen.dart
│   └── widgets/                 # Reusable widgets
│       ├── message_bubble.dart
│       ├── device_card.dart
│       └── connection_status.dart
├── android/                     # Android specific code
├── ios/                        # iOS specific code
└── pubspec.yaml               # Dependencies
💡 Use Cases
🎓 Education: Share notes and collaborate in classrooms without internet [web:12][web:17]

🎪 Events: Coordinate with team members at conferences or festivals

✈️ Travel: Stay connected with companions in remote areas

🏢 Enterprise: Secure internal communication in sensitive environments

🎮 Gaming: Local multiplayer chat for mobile games

🔒 Privacy: Private conversations with no cloud storage or tracking

🐛 Troubleshooting
Common Issues
Connection fails on Android:

Ensure Location services are enabled (required for WiFi Direct)

Grant all necessary permissions in app settings

Check that WiFi is turned on

Devices not discovering each other:

Make sure both devices are on the same WiFi network

Restart the app on both devices

Toggle WiFi off and on

Messages not sending:

Verify the connection status indicator shows "Connected"

Check network permissions are granted

Try disconnecting and reconnecting

🤝 Contributing
Contributions make the open-source community an amazing place to learn and create! Any contributions are greatly appreciated.

Fork the Project

Create your Feature Branch (git checkout -b feature/AmazingFeature)

Commit your Changes (git commit -m 'Add some AmazingFeature')

Push to the Branch (git push origin feature/AmazingFeature)

Open a Pull Request

Development Guidelines
Follow Flutter's official style guide [attached_file:1]

Write meaningful commit messages

Add comments for complex logic

Test on both Android and iOS devices

Update documentation for new features

📄 License
This project is licensed under the MIT License - see the LICENSE file for details.

👨‍💻 Author
Shashank Hegde

GitHub: @hegdeshashank100

Project: wifi-chat

🙏 Acknowledgments
Special thanks to the Flutter community and these amazing packages:

flutter_p2p_connection - WiFi Direct connectivity [web:12]

wifi_direct_plugin - P2P communication [web:15]

nearby_service - Cross-platform nearby connectivity [web:18]

Flutter Documentation - Comprehensive guides and tutorials [attached_file:1]

📚 Resources
Flutter Learning Resources
Flutter Documentation [attached_file:1]

Flutter Cookbook

Building Layouts

Understanding Constraints

Adding Interactivity

Related Technologies
WiFi Direct Overview [web:15]

MultipeerConnectivity (iOS)

Socket Programming in Dart [web:20]

📞 Support
If you encounter any issues or have questions:

🐛 Report a Bug

💡 Request a Feature

📧 Contact: Create an issue

🔮 Roadmap
 End-to-end encryption for messages

 Voice message support

 Image compression before transfer

 Group chat rooms with admin controls

 Message read receipts

 Dark mode theme

 Custom notification sounds

 Export chat history

<div align="center">
⭐ Star this repository if you find it helpful!

Made with ❤️ using Flutter

Report Bug · Request Feature

</div>
