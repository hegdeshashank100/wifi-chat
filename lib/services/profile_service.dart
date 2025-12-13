import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import 'device_id_service.dart';

class ProfileService {
  static const _displayNameKey = 'profile_display_name';
  static const _phoneNumberKey = 'profile_phone_number';
  static const _deviceIdKey = 'device_id';

  Future<bool> hasProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_displayNameKey);
  }

  Future<UserProfile?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final displayName = prefs.getString(_displayNameKey);
    if (displayName == null || displayName.isEmpty) return null;

    // Ensure we always have a device ID stored
    String? deviceId = prefs.getString(_deviceIdKey);
    deviceId ??= await DeviceIdService.getDeviceId();
    await prefs.setString(_deviceIdKey, deviceId);

    final phoneNumber = prefs.getString(_phoneNumberKey);
    return UserProfile(
      deviceId: deviceId,
      displayName: displayName,
      phoneNumber: phoneNumber?.isEmpty == true ? null : phoneNumber,
    );
  }

  Future<UserProfile> saveProfile({
    required String displayName,
    String? phoneNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = await DeviceIdService.getDeviceId();

    await prefs.setString(_displayNameKey, displayName);
    if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
      await prefs.setString(_phoneNumberKey, phoneNumber.trim());
    } else {
      await prefs.remove(_phoneNumberKey);
    }
    await prefs.setString(_deviceIdKey, deviceId);

    return UserProfile(
      deviceId: deviceId,
      displayName: displayName,
      phoneNumber: phoneNumber?.trim().isEmpty == true ? null : phoneNumber,
    );
  }
}
