class UserProfile {
  final String deviceId;
  final String displayName;
  final String? phoneNumber;

  const UserProfile({
    required this.deviceId,
    required this.displayName,
    this.phoneNumber,
  });
}
