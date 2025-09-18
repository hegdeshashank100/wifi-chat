class WifiDirectDevice {
  final String deviceName;
  final String deviceAddress;
  final bool isConnected;

  WifiDirectDevice({
    required this.deviceName,
    required this.deviceAddress,
    this.isConnected = false,
  });

  @override
  String toString() {
    return 'WifiDirectDevice(name: $deviceName, address: $deviceAddress, connected: $isConnected)';
  }
}
