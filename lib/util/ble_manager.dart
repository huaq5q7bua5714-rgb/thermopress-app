import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:poct_app/util/constants/ble_config.dart';
import 'package:poct_app/util/snack_bar_manager.dart';

import '../inter/ble_callback.dart';

/// Frame header (1 byte) – kept for compatibility, not used in current code.
const int frameHeader = 0xAA;

/// Data types for sending commands – kept from old project.
enum DataType {
  settemp(0xA1), // change heating temperature
  settime(0xA2), // change heating time
  heatcontrol(0xA3), // heater on/off
  ledcontrol(0xA4), // LED on/off

  realtemp(0xB1), // current sensor temperature
  realtime(0xB2); // remaining heating time

  final int value;
  const DataType(this.value);
}

class BleManager {
  static BleManager? _instance;

  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _notifyCharacteristic;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;
  StreamSubscription<List<int>>? _notifySubscription;
  final Map<String, BluetoothDevice> _scannedDevices = {};

  // Callback interface
  BleCallback? _callback;

  // Private constructor
  BleManager._();

  // Singleton
  static BleManager getInstance() {
    _instance ??= BleManager._();
    return _instance!;
  }

  // Set callback
  void setCallback(BleCallback callback) {
    _callback = callback;
  }

  String _normalizeUuid(String uuid) {
    final lower = uuid.toLowerCase();
    const bluetoothBase = '-0000-1000-8000-00805f9b34fb';
    if (lower.startsWith('0000') && lower.endsWith(bluetoothBase)) {
      return lower.substring(4, 8);
    }
    return lower;
  }

  bool _uuidMatches(Guid actual, String expected) {
    return _normalizeUuid(actual.toString()) == _normalizeUuid(expected);
  }

  // Check BLE support
  Future<bool> isSupported() async {
    return await FlutterBluePlus.isSupported;
  }

  // Check if Bluetooth is ON
  Future<bool> isOn() async {
    return await FlutterBluePlus.isOn;
  }

  // Start scan (BLE)
  Future<void> startScan({
    Duration? timeout,
    List<Guid>? withServices,
  }) async {
    if (!(await isOn())) {
      SnackBarManager.instance.showSnackBar(
        "Bluetooth is off",
        "Please enable Bluetooth on your phone.",
      );
    }

    // Stop previous scan
    await stopScan();
    _scannedDevices.clear();

    // Listen to scan results
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        final id = result.device.remoteId.toString();
        _scannedDevices[id] = result.device;
        // Debug print is useful to see what is discovered
        // print("Scan result: ${result.device.platformName} - ${result.device.remoteId}");
        _callback?.onScanResult(result.device);
      }
    });

    print("Starting BLE scan ...");
    await FlutterBluePlus.startScan(
      timeout: timeout ?? const Duration(seconds: 4),
      withServices: withServices ?? [],
    );
  }

  // Stop scan
  Future<void> stopScan() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    await FlutterBluePlus.stopScan();
  }

  // Build device from MAC/ID
  BluetoothDevice? getDeviceFromAddress(String address) {
    final scannedDevice = _scannedDevices[address];
    if (scannedDevice != null) {
      return scannedDevice;
    }

    try {
      final device = BluetoothDevice.fromId(address);
      return device;
    } catch (e) {
      print('Failed to get device from address: $e');
      return null;
    }
  }

  // Connect to device
  Future<bool> connect(BluetoothDevice device) async {
    try {
      print(
          "Connecting to device: ${device.platformName} (${device.remoteId}) ...");

      if (_device != null && _device!.remoteId != device.remoteId) {
        await disconnect();
      }

      await device.connect(
        timeout: const Duration(seconds: 4),
        autoConnect: false,
      );

      _device = device;

      // Listen to connection state changes
      await _connectionStateSubscription?.cancel();
      _connectionStateSubscription =
          device.connectionState.listen((BluetoothConnectionState state) {
        Get.log("Connection state changed: $state");
        if (state == BluetoothConnectionState.disconnected) {
          // Device disconnected
          _callback?.onDisconnected();
          _device = null;
          _writeCharacteristic = null;
          _notifyCharacteristic = null;
        }
      });

      // Discover services
      final services = await device.discoverServices();
      for (final service in services) {
        Get.log('Found service: ${service.uuid}');
        for (final c in service.characteristics) {
          Get.log("  Characteristic: ${c.uuid} "
              "props(r=${c.properties.read}, "
              "w=${c.properties.write}, "
              "n=${c.properties.notify}, "
              "i=${c.properties.indicate})");
        }

        if (_uuidMatches(service.uuid, BleConfig.SERVICE_UUID)) {
          for (final c in service.characteristics) {
            final uuidStr = c.uuid.toString().toLowerCase();

            if (_uuidMatches(c.uuid, BleConfig.WRITE_CHARACTERISTIC_UUID)) {
              _writeCharacteristic = c;
              Get.log("✅ Found WRITE characteristic: $uuidStr");
            }

            if (_uuidMatches(c.uuid, BleConfig.NOTIFY_CHARACTERISTIC_UUID)) {
              _notifyCharacteristic = c;
              Get.log("✅ Found NOTIFY characteristic: $uuidStr");
            }
          }
        }
      }

      if (_writeCharacteristic != null) {
        // For some modules, WRITE and NOTIFY are the same characteristic.
        // Keep this logic to be compatible with your previous working version.
        if (_notifyCharacteristic == null) {
          _notifyCharacteristic = _writeCharacteristic;
          Get.log("ℹ Using WRITE characteristic as NOTIFY as well.");
        }

        await enableNotification();
        _callback?.onConnectSuccess();
        return true;
      } else {
        Get.log(
            "❌ WRITE characteristic not found, please check BleConfig UUIDs.");
        return false;
      }
    } catch (e, stacktrace) {
      Get.log("Service discovery / connect failed: $e");
      Get.log("Stacktrace: $stacktrace");
      _callback?.onConnectFailed(e.toString());
      await disconnect();
      return false;
    }
  }

  // Disconnect
  Future<void> disconnect() async {
    final device = _device;
    final notify = _notifyCharacteristic;

    try {
      if (notify != null && notify.isNotifying) {
        await notify.setNotifyValue(false);
      }
    } catch (e) {
      Get.log("Disable notify failed during disconnect: $e");
    }

    if (device != null) {
      try {
        await device.disconnect();
      } catch (e) {
        Get.log("Device disconnect failed: $e");
      }
    }

    await _notifySubscription?.cancel();
    await _connectionStateSubscription?.cancel();
    _notifySubscription = null;
    _connectionStateSubscription = null;
    _device = null;
    _notifyCharacteristic = null;
    _writeCharacteristic = null;
  }

  // Send data to device
  Future<bool> sendData(List<int> data, DataType type) async {
    if (_writeCharacteristic == null) {
      Get.log("No WRITE characteristic, cannot send data.");
      return false;
    }

    // In your old project you once wrapped data with frameHeader + type,
    // now we just send the raw data as requested.
    await _writeCharacteristic!.write(
      data,
      withoutResponse: true, // enable "write without response"
    );

    print("Sent data: $data (type=${type.value.toRadixString(16)})");
    return true;
  }

  // Enable notifications
  Future<void> enableNotification() async {
    if (_notifyCharacteristic == null) {
      print("No NOTIFY characteristic, cannot enable notifications.");
      return;
    }

    Get.log("Enabling notify on: ${_notifyCharacteristic!.uuid}");
    Get.log("properties: "
        "read=${_notifyCharacteristic!.properties.read}, "
        "write=${_notifyCharacteristic!.properties.write}, "
        "notify=${_notifyCharacteristic!.properties.notify}, "
        "indicate=${_notifyCharacteristic!.properties.indicate}");

    try {
      await _notifyCharacteristic!.setNotifyValue(true);
      Get.log(
          "setNotifyValue(true) called, isNotifying = ${_notifyCharacteristic!.isNotifying}");

      await _notifySubscription?.cancel();
      _notifySubscription = _notifyCharacteristic!.value.listen((value) {
        print("🔵 Notify value: $value");
        _callback?.onDataReceived(value);
      });

      Get.log("Notification listener attached.");
    } catch (e, st) {
      Get.log("Enable notify failed: $e");
      print(st);
    }
  }

  /// ✅【新增】向 MCU 发送单字节命令（如 0xAA / 0xFF）
  Future<void> sendCmdByte(int cmd) async {
    final write = _writeCharacteristic;
    if (write == null) {
      throw Exception("WRITE characteristic not ready");
    }

    final data = <int>[cmd & 0xFF];
    final withoutResponse =
        write.properties.writeWithoutResponse || !write.properties.write;

    try {
      await write
          .write(
            data,
            withoutResponse: withoutResponse,
          )
          .timeout(const Duration(seconds: 2));
    } catch (e) {
      if (withoutResponse && write.properties.write) {
        Get.log("WRITE without response failed, retrying with response: $e");
        await write
            .write(
              data,
              withoutResponse: false,
            )
            .timeout(const Duration(seconds: 2));
      } else {
        rethrow;
      }
    }

    Get.log(
        "📤 CMD sent: 0x${cmd.toRadixString(16).padLeft(2, '0').toUpperCase()}");
  }

  // Check connection state
  bool isConnected() {
    return _device != null && _notifyCharacteristic != null;
  }
}
