import 'package:flutter_blue_plus/flutter_blue_plus.dart';

mixin BleCallback {
  // 扫描结果回调
  void onScanResult(BluetoothDevice device);

  // 连接成功回调
  void onConnectSuccess();

  // 断开连接回调
  void onDisconnected();

  // 连接失败回调
  void onConnectFailed(String error);

  // 数据接收回调
  void onDataReceived(List<int> data);
}