<div align="center">

# 📱 WiFi Chat

### Peer-to-Peer Messaging Without Internet

*Connect, Chat, and Share — All Offline*

---

**Tech stack:** Flutter 3+, Dart 3+ · Android · iOS  


</div>

---

## 🎯 About

**WiFi Chat** is a Flutter-powered mobile app for **real-time peer-to-peer messaging** over a **local WiFi network** — no internet needed.

Use it in:

- Classrooms
- Events and conferences
- Remote areas
- Offices that want local-only chat

Your messages and files stay inside the local network.

---

## ✨ Features

### 💬 Core Messaging

- Real-time message delivery
- Multi-user chat in the same room
- Connection status indicators
- Message history
- Auto-reconnection on network changes

### 🛠️ Advanced Features

- File and image sharing
- Automatic device discovery
- WiFi Direct (Android P2P)
- MultipeerConnectivity (iOS)
- Material Design 3 based UI

### 🎯 Perfect For

| Education | Events | Travel | Enterprise |
|:--------:|:------:|:------:|:----------:|
| Classroom collaboration | Event coordination | Remote area communication | Secure internal chat |

---

## 🚀 Getting Started

### 📋 Prerequisites

Make sure you have:

```bash
✓ Flutter SDK 3.0+
✓ Dart SDK 3.0+
✓ Android Studio or VS Code
✓ Physical device (Android 5.0+ / iOS 10+)
```

> ⚠️ **Note:** WiFi Direct requires real hardware. Emulators will not work for P2P tests.

---

## 📥 Installation

### Step-by-step setup

1️⃣ **Clone the repository**

```bash
git clone https://github.com/hegdeshashank100/wifi-chat.git
cd wifi_chat
```

2️⃣ **Install dependencies**

```bash
flutter pub get
```

3️⃣ **Verify your setup**

```bash
flutter doctor
```

4️⃣ **Connect device and run**

```bash
flutter run
```

### New to Flutter?

Useful official resources:

- First app tutorial: https://docs.flutter.dev/get-started/codelab  
- Cookbook examples: https://docs.flutter.dev/cookbook  
- Layout basics: https://docs.flutter.dev/ui/layout

---

## 📱 Platform Support

| Platform | Technology              | Min Version              | Status            |
|:--------:|-------------------------|:------------------------:|:-----------------:|
| Android  | WiFi Direct (P2P)       | API 21 (Android 5.0)     | ✅ Fully supported |
| iOS      | MultipeerConnectivity   | iOS 10.0+                | ✅ Fully supported |

---

## 🛠️ Technical Architecture

### Technology Stack

```text
┌─────────────────────────────────────────────────────────┐
│                 Flutter 3.0+ / Dart 3.0+                │
├─────────────────────────────────────────────────────────┤
│  UI Layer          │  Material Design 3                 │
│  State Management  │  Provider / Riverpod               │
│  Communication     │  TCP/UDP sockets                   │
│  Android P2P       │  WiFi Direct API                   │
│  iOS P2P           │  MultipeerConnectivity framework   │
└─────────────────────────────────────────────────────────┘
```

<details>
<summary><b>🔧 Key Dependencies (pubspec.yaml)</b></summary>

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Connectivity & P2P
  flutter_p2p_connection: ^latest      # WiFi Direct for Android
  wifi_direct_plugin: ^latest          # Alternative P2P plugin
  nearby_service: ^latest              # Cross-platform connectivity

  # State management
  provider: ^latest                    # Or Riverpod, if you prefer
```

</details>

### 🔄 Data Flow

```mermaid
graph LR
    A[🔍 Discovery] --> B[🤝 Connection]
    B --> C[🏠 Host / Client Setup]
    C --> D[💬 Message Exchange]
    D --> E[📤 File & Data Transfer]
```

1. Scan for nearby devices  
2. Establish a P2P connection (WiFi Direct / MultipeerConnectivity)  
3. Negotiate host/client roles  
4. Exchange messages and transfer files over TCP/UDP sockets  

---

## 📖 Usage Guide

### 🏠 Acting as Host

1. Open the app and choose **Create Room**
2. Wait for nearby devices to discover your room
3. Accept incoming connection requests
4. Start chatting and sharing files

### 📲 Acting as Client

1. Open the app and choose **Join Room**
2. Select a visible host from the device list
3. Send a connection request
4. Start chatting once connected

---

## ⚙️ Configuration

### 🤖 Android Permissions

Add the following to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.NEARBY_WIFI_DEVICES"/>
```

On Android 13+ you may also need to request `NEARBY_WIFI_DEVICES` at runtime.

### 🍎 iOS Permissions

Add to `ios/Runner/Info.plist`:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>WiFi Chat needs access to the local network to discover and connect with nearby devices for peer-to-peer messaging.</string>

<key>NSBonjourServices</key>
<array>
  <string>_wifi-chat._tcp</string>
  <string>_wifi-chat._udp</string>
</array>

<key>UIBackgroundModes</key>
<array>
  <string>fetch</string>
  <string>remote-notification</string>
</array>
```

Make sure your Bonjour service names match whatever you configure in the app.

---

## 📂 Project Structure

```text
wifi_chat/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── models/                      # Data models
│   │   ├── message.dart
│   │   ├── user.dart
│   │   └── device.dart
│   ├── services/                    # Business logic & platform APIs
│   │   ├── wifi_service.dart        # WiFi Direct handling
│   │   ├── socket_service.dart      # Socket communication
│   │   └── storage_service.dart     # Local storage (e.g., Hive/shared_prefs)
│   ├── providers/                   # State management (Provider/Riverpod)
│   │   ├── chat_provider.dart
│   │   └── connection_provider.dart
│   ├── screens/                     # UI screens
│   │   ├── home_screen.dart
│   │   ├── chat_screen.dart
│   │   └── device_list_screen.dart
│   └── widgets/                     # Reusable UI components
│       ├── message_bubble.dart
│       ├── device_card.dart
│       └── connection_status.dart
├── android/                         # Android config and native code
├── ios/                             # iOS config and native code
└── pubspec.yaml                     # Flutter dependencies
```

---

## 💡 Use Cases

| Scenario    | Description                                      |
|------------|--------------------------------------------------|
| Education  | Share notes and collaborate in classrooms offline |
| Events     | Coordinate staff and teams at conferences         |
| Travel     | Stay connected in areas with poor or no internet  |
| Privacy    | Keep conversations local with no cloud storage    |

---

## 🐛 Troubleshooting

<details>
<summary><b>🔧 Common Issues & Fixes</b></summary>

### ❌ Connection fails on Android

- Ensure **Location services** are enabled (Android requires this for WiFi Direct)
- Grant all requested permissions in system settings
- Confirm WiFi is turned on

### ❌ Devices do not discover each other

- Confirm both devices are on the **same WiFi network** (when not using P2P)
- Restart the app on both devices
- Toggle WiFi off and back on
- Make sure battery saver or VPN is not interfering with local discovery

### ❌ Messages are not sending

- Check that connection status shows **Connected**
- Verify network permissions are granted
- Try disconnecting and reconnecting
- Check that host and client roles are correctly set

</details>

---

## 🤝 Contributing

Contributions are welcome.

1. Fork the project
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit your changes: `git commit -m "Add my feature"`
4. Push to the branch: `git push origin feature/my-feature`
5. Open a Pull Request

### 📝 Development Guidelines

- Follow the official Dart & Flutter style guides  
- Use meaningful commit messages  
- Add comments for non-trivial logic  
- Test on both Android and iOS where possible  
- Update documentation for new features and major changes  

---

## 🔮 Roadmap

Planned improvements:

- [ ] End-to-end encryption  
- [ ] Voice message support  
- [ ] Image compression for media sharing  
- [ ] Group chat with admin controls  
- [ ] Message read receipts  
- [ ] Dark mode theme  
- [ ] Custom notification sounds  
- [ ] Export chat history to file  

---

## 📄 License

This project is licensed under the **MIT License**.  
See the `LICENSE` file for full details.

---

## 👨‍💻 Author

- **Name:** Shashank Hegde  
- **GitHub:** https://github.com/hegdeshashank100  
- **Project repo:** https://github.com/hegdeshashank100/wifi-chat

---

## 🙏 Acknowledgments

Thanks to:

- `flutter_p2p_connection` – WiFi Direct connectivity  
- `wifi_direct_plugin` – P2P communication  
- `nearby_service` – Cross-platform connectivity helpers  
- Flutter documentation and community resources  

---

## 📚 Resources

- Flutter docs: https://docs.flutter.dev  
- WiFi Direct (Android): https://developer.android.com/guide/topics/connectivity/wifip2p  
- MultipeerConnectivity (iOS): https://developer.apple.com/documentation/multipeerconnectivity  
- Dart socket programming: https://api.dart.dev/stable/dart-io/Socket-class.html  

---

## 📞 Support

You can:

- Report bugs: https://github.com/hegdeshashank100/wifi-chat/issues  
- Request features: https://github.com/hegdeshashank100/wifi-chat/issues  
- Ask questions: https://github.com/hegdeshashank100/wifi-chat/discussions  

---

<div align="center">

⭐ If you find this project useful, consider starring the repository.

**Made with ❤️ using Flutter**

<br>

_Last updated: December 2025_

</div>
