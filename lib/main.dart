import 'package:flutter/material.dart';
import 'screens/chat_list_screen.dart';

void main() {
  runApp(const WiFiChatApp());
}

class WiFiChatApp extends StatelessWidget {
  const WiFiChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WiFi Chat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0088CC),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0088CC),
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const ChatListScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
