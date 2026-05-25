class BluetoothDeviceInfo {
  String platformName;
  String address;
  bool isConnected;
  bool heatWorking;
  bool ledWorking;

  BluetoothDeviceInfo({
    required this.platformName,
    required this.address,
    this.isConnected = false,
    this.heatWorking = false,
    this.ledWorking = false,
  });
}