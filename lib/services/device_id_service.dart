import 'dart:io';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceIdService {
  static const String _deviceIdKey = 'device_id';

  static Future<String> getDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if we already have a device ID
      String? deviceId = prefs.getString(_deviceIdKey);

      if (deviceId == null || deviceId.isEmpty) {
        // Generate new device ID
        deviceId = _generateDeviceId();
        await prefs.setString(_deviceIdKey, deviceId);
        print('📱 Generated new device ID: $deviceId');
      } else {
        print('📱 Using existing device ID: $deviceId');
      }

      return deviceId;
    } catch (e) {
      print('⚠️ Error getting device ID: $e');
      // Fallback to simple generated ID
      return _generateDeviceId();
    }
  }

  static String _generateDeviceId() {
    final random = Random();
    final platformPrefix = Platform.isAndroid
        ? 'AND'
        : Platform.isIOS
            ? 'IOS'
            : 'UNK';
    final randomSuffix = random.nextInt(9999).toString().padLeft(4, '0');
    return 'SOS_${platformPrefix}_$randomSuffix';
  }
}
