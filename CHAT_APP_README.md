# 📱 WiFi Chat - Offline Messaging App

<div align="center">

### Peer-to-Peer Messaging Without Internet

_Connect, Chat, and Share — All Offline using WiFi Direct & Bluetooth_

**Tech Stack:** Flutter 3+, Dart 3+, SQLite, Nearby Connections API

</div>

---

## 🎯 Overview

**WiFi Chat** is a fully-featured offline messaging application inspired by Telegram's UI/UX. It enables real-time peer-to-peer communication over WiFi Direct and Bluetooth without requiring internet connectivity.

### ✨ Key Features

#### 💬 Core Messaging

- **Real-time messaging** with instant delivery
- **Message status indicators** (Sending, Sent, Delivered, Read)
- **Telegram-style UI** with message bubbles and timestamps
- **Unread message counters** on chat list
- **Contact online status** indicators
- **Message history** stored locally

#### 📊 Data Management

- **SQLite local database** - All data stored on device
- **No remote servers** - Complete privacy
- **Contact management** - Add, search, and organize contacts
- **Auto-discovery** - Finds nearby devices automatically
- **Persistent storage** - Messages saved across app restarts

#### 🔌 Connectivity

- **WiFi Direct (Android P2P)** for fast connections
- **Bluetooth fallback** for compatibility
- **Auto-reconnection** - Maintains connections automatically
- **Endpoint caching** - Fast reconnection to known devices
- **Multi-device support** - Connect to multiple users simultaneously

#### 🎨 User Interface

- **Material Design 3** with Telegram-inspired theme
- **Chat list** showing last message, time, and unread count
- **Contact list** with online status and search
- **Clean message bubbles** with proper spacing
- **Smooth animations** and transitions

---

## 🏗️ Architecture

### Database Schema

```sql
-- Contacts Table
CREATE TABLE contacts (
  id TEXT PRIMARY KEY,           -- Device ID
  name TEXT NOT NULL,
  avatarPath TEXT,
  bio TEXT,
  lastSeen INTEGER NOT NULL,
  isOnline INTEGER DEFAULT 0,
  createdAt INTEGER NOT NULL
);

-- Messages Table
CREATE TABLE messages (
  id TEXT PRIMARY KEY,           -- UUID
  chatId TEXT NOT NULL,          -- Contact ID
  senderId TEXT NOT NULL,
  receiverId TEXT NOT NULL,
  content TEXT NOT NULL,
  type INTEGER NOT NULL,         -- 0=text, 1=image, 2=file
  status INTEGER NOT NULL,       -- 0=sending, 1=sent, 2=delivered, 3=read
  timestamp INTEGER NOT NULL,
  isMe INTEGER NOT NULL,
  fileName TEXT,
  fileSize INTEGER,
  FOREIGN KEY (chatId) REFERENCES contacts (id)
);
```

### Project Structure

```
lib/
├── main.dart                      # App entry point
├── models/
│   ├── contact.dart              # Contact model
│   ├── message.dart              # Message model with status
│   ├── chat.dart                 # Chat view model
│   └── wifi_direct_device.dart   # Legacy (unused)
├── screens/
│   ├── chat_list_screen.dart     # Main screen - all chats
│   ├── chat_screen.dart          # 1-on-1 conversation
│   └── contacts_screen.dart      # Contact management
├── services/
│   ├── messaging_service.dart    # P2P messaging logic
│   └── device_id_service.dart    # Device identification
└── database/
    └── database_helper.dart      # SQLite operations
```

---

## 🚀 Getting Started

### Prerequisites

```bash
✓ Flutter SDK 3.1+
✓ Dart SDK 3.1+
✓ Android Studio or VS Code
✓ Physical device (Android 5.0+)
```

> ⚠️ **Note:** WiFi Direct requires real hardware. Emulators won't work for P2P testing.

### Installation

1️⃣ **Clone repository**

```bash
git clone https://github.com/hegdeshashank100/wifi-chat.git
cd wifi-chat
```

2️⃣ **Install dependencies**

```bash
flutter pub get
```

3️⃣ **Run on device**

```bash
flutter run
```

### Required Permissions

The app requests these permissions:

- Location (required for WiFi Direct discovery)
- Bluetooth
- Bluetooth Advertise
- Bluetooth Connect
- Bluetooth Scan
- Nearby WiFi Devices

---

## 📖 How to Use

### First Time Setup

1. **Launch app** on both devices
2. **Grant permissions** when prompted
3. App automatically starts **advertising and discovering**

### Adding Contacts

#### Method 1: From Nearby Devices

1. Open **Contacts** screen (tap + button)
2. See **"Nearby Devices"** section
3. Tap **Add** next to discovered device
4. Enter a name for the contact

#### Method 2: Manual Entry

1. Open **Contacts** screen
2. Tap **+ icon** in top-right
3. Enter **Contact Name** and **Device ID**
4. Tap **Add**

### Sending Messages

1. Tap on a contact from **Chat List** or **Contacts**
2. Type message in input field
3. Tap **send button**
4. Watch message status update (✓, ✓✓)

### Message Status Icons

| Icon      | Status    | Meaning                 |
| --------- | --------- | ----------------------- |
| 🕐        | Sending   | Message being sent      |
| ✓         | Sent      | Message sent to network |
| ✓✓        | Delivered | Received by recipient   |
| ✓✓ (blue) | Read      | Opened by recipient     |
| ⚠️        | Failed    | Send failed (offline)   |

---

## 🔧 Technical Details

### Messaging Protocol

Messages are sent as JSON payloads over Nearby Connections:

```json
{
  "type": "message",
  "id": "uuid-v4",
  "content": "Hello!",
  "timestamp": 1733587200000
}
```

Status updates:

```json
{
  "type": "status_update",
  "messageId": "uuid-v4",
  "status": 2
}
```

### Connection Strategy

- **Strategy**: `P2P_POINT_TO_POINT` for fastest 1-on-1 connections
- **Service ID**: `com.example.wifi_chat`
- **Device Name Format**: `Name|DeviceID`

### Performance Optimizations

1. **Endpoint Caching** - Reconnect to known devices instantly
2. **Database Indexing** - Fast message queries
3. **Connection Pooling** - Reuse established connections
4. **Lazy Loading** - Load messages on demand

---

## 📱 Screens Overview

### 1. Chat List Screen

- Shows all conversations
- Last message preview
- Unread count badges
- Online status indicators
- Pull-to-refresh

### 2. Chat Screen

- Telegram-style message bubbles
- Date separators
- Message status indicators
- Real-time updates
- Auto-scroll to bottom

### 3. Contacts Screen

- Searchable contact list
- Nearby devices section
- Add contact dialog
- Online status
- Quick chat access

---

## 🔒 Privacy & Security

### Data Storage

- **100% Local** - All data stored on device
- **No cloud sync** - No remote servers
- **SQLite encryption** - Can be added
- **No tracking** - No analytics or telemetry

### Network

- **Local network only** - No internet required
- **Direct P2P** - No intermediary servers
- **Unencrypted** by default - Can add encryption
- **No authentication** - Anyone nearby can connect

### Recommendations

- Use in trusted environments
- Consider adding E2E encryption for sensitive data
- Implement device verification for production use

---

## 🎨 Customization

### Theme Colors

Change primary color in `main.dart`:

```dart
colorScheme: ColorScheme.fromSeed(
  seedColor: const Color(0xFF0088CC), // Telegram blue
),
```

### Database Location

Database file: `wifi_chat.db` in app's database directory

### Service ID

Change for private networks in `messaging_service.dart`:

```dart
final String _serviceId = "com.yourcompany.app";
```

---

## 🐛 Troubleshooting

### Devices Not Connecting

1. **Check permissions** - All must be granted
2. **Enable Location** - Required for WiFi Direct
3. **Same WiFi network** - Devices should be nearby
4. **Restart app** - Try on both devices
5. **Check logs** - Look for error messages

### Messages Not Sending

1. **Verify online status** - Contact must be online
2. **Check connection** - Green dot = online
3. **Retry message** - Tap retry if failed
4. **Clear and reconnect** - Restart discovery

### Database Issues

```bash
# Clear app data
flutter clean
flutter pub get

# Or uninstall and reinstall app
```

---

## 🔮 Future Enhancements

### Planned Features

- [ ] Image sharing
- [ ] File attachments
- [ ] Voice messages
- [ ] Group chats
- [ ] End-to-end encryption
- [ ] Message search
- [ ] Custom avatars
- [ ] Dark mode
- [ ] Message reactions
- [ ] Typing indicators

---

## 📄 License

This project is open source and available under the MIT License.

---

## 👨‍💻 Developer

**Shashank Hegde**

- GitHub: [@hegdeshashank100](https://github.com/hegdeshashank100)

---

## 🙏 Credits

- **Nearby Connections** - Google's WiFi Direct API
- **Telegram** - UI/UX inspiration
- **Flutter Team** - Amazing framework

---

## 📞 Support

For issues and questions:

1. Check [Troubleshooting](#-troubleshooting) section
2. Search existing issues on GitHub
3. Create new issue with logs and device info

---

<div align="center">

**Made with ❤️ using Flutter**

_Connecting people without internet, one message at a time_

</div>
