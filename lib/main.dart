import 'package:flutter/material.dart';
import 'screens/sos_screen_optimized.dart';

void main() {
  runApp(const SOSApp());
}

class SOSApp extends StatelessWidget {
  const SOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '🆘 SOS Emergency',
      theme: ThemeData(
        primarySwatch: Colors.red,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
      ),
      home: const SOSScreenImproved(),
      debugShowCheckedModeBanner: false,
    );
  }
}
