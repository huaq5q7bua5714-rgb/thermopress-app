import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionUtil {
  /// 请求蓝牙和位置信息权限
  static Future<bool> requestBluetoothConnectPermission() async {
    if (Platform.isIOS) {
      final status = await Permission.bluetooth.request();
      final granted = _isPermissionGranted(status);
      print(granted ? "iOS 蓝牙权限申请通过" : "iOS 蓝牙权限申请失败: $status");
      return granted;
    }

    if (Platform.isAndroid) {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = deviceInfo.version.sdkInt;
      final permissions = sdkInt >= 31
          ? <Permission>[
              Permission.bluetoothScan,
              Permission.bluetoothConnect,
            ]
          : <Permission>[
              Permission.location,
            ];

      final statuses = await permissions.request();
      final denied = statuses.entries
          .where((entry) => !_isPermissionGranted(entry.value))
          .map((entry) => '${entry.key}: ${entry.value}')
          .join(', ');

      if (denied.isNotEmpty) {
        print("蓝牙权限申请失败: $denied");
        return false;
      }

      print("蓝牙权限申请通过");
      return true;
    }

    return false;
  }

  static bool _isPermissionGranted(PermissionStatus status) {
    return status.isGranted || status.isLimited;
  }

  /// 请求图库和文件读写权限
  Future<bool> checkAndRequestPermissions({required bool skipIfExists}) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return false; // Only Android and iOS platforms are supported
    }

    if (Platform.isAndroid) {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = deviceInfo.version.sdkInt;

      if (skipIfExists) {
        // Read permission is required to check if the file already exists
        return sdkInt >= 33
            ? await Permission.photos.request().isGranted
            : await Permission.storage.request().isGranted;
      } else {
        // No read permission required for Android SDK 29 and above
        return sdkInt >= 29
            ? true
            : await Permission.storage.request().isGranted;
      }
    } else if (Platform.isIOS) {
      // iOS permission for saving images to the gallery
      return skipIfExists
          ? await Permission.photos.request().isGranted
          : await Permission.photosAddOnly.request().isGranted;
    }

    return false; // Unsupported platforms
  }
}
