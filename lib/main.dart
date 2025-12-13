import 'package:flutter/material.dart';
import 'screens/chat_list_screen.dart';
import 'screens/login_screen.dart';
import 'services/profile_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final profileService = ProfileService();
  final hasProfile = await profileService.hasProfile();

  runApp(WiFiChatApp(
    profileService: profileService,
    hasProfile: hasProfile,
  ));
}

class WiFiChatApp extends StatelessWidget {
  final ProfileService profileService;
  final bool hasProfile;

  const WiFiChatApp({
    super.key,
    required this.profileService,
    required this.hasProfile,
  });

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
      home: hasProfile
          ? const ChatListScreen()
          : LoginScreen(profileService: profileService),
      debugShowCheckedModeBanner: false,
    );
  }
}
