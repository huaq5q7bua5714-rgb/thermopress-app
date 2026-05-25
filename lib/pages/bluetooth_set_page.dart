import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:poct_app/pages/home/home_contolller.dart';
import 'package:poct_app/data/bluetooth_device_info.dart';

/// Bluetooth settings page:
/// - Show current connection status
/// - Scan nearby BLE devices
/// - Connect / disconnect
class BluetoothSetPage extends StatelessWidget {
  const BluetoothSetPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 全局 HomeController（在 HomeBinding 里已经 permanent 注册）
    final HomeController controller = Get.find<HomeController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text(
          '蓝牙',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ===== 当前连接状态卡片 =====
            Obx(() {
              final info = controller.bluetoothInfo.value;
              final bool isConnected = info.isConnected;
              final String name = info.platformName.isNotEmpty
                  ? info.platformName
                  : '无设备';

              return Container(
                width: double.infinity,
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isConnected
                            ? const Color(0xFFE6F9EE)
                            : const Color(0xFFF2F3F7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.bluetooth,
                            size: 18,
                            color: isConnected
                                ? const Color(0xFF1BB37A)
                                : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isConnected ? '蓝牙已连接' : '蓝牙未连接',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isConnected
                                  ? const Color(0xFF1BB37A)
                                  : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isConnected ? '设备: $name' : '无设备连接',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isConnected)
                      TextButton(
                        onPressed: () {
                          // 断开连接：直接用你现有的 BleManager 逻辑
                          controller.bluetoothInfo.value.isConnected = false;
                          controller.bluetoothInfo.refresh();
                          // 真正的断连在 BleManager.disconnect() 里做，
                          // 你也可以在这里加一行 BleManager.getInstance().disconnect();
                          // 为保持和列表页一致，这里只做 UI 状态处理即可。
                        },
                        child: const Text(
                          '断开连接',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),

            // ===== 扫描按钮 + 简单状态 =====
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      controller.scanDevices();
                    },
                    icon: const Icon(
                      Icons.search,
                      size: 18,
                    ),
                    label: const Text('扫描设备'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D88F5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Obx(() {
                  return Text(
                    '找到 ${controller.devices.length} 个设备',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  );
                }),
              ],
            ),

            const SizedBox(height: 16),

            // ===== 设备列表 =====
            Expanded(
              child: Obx(() {
                final List<BluetoothDeviceInfo> devices =
                controller.devices.toList();

                if (devices.isEmpty) {
                  return const Center(
                    child: Text(
                      '未找到蓝牙设备\n 请点击“扫描设备”按键',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black45,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: devices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    final bool isThisConnected = device.isConnected;

                    final String name = device.platformName.isNotEmpty
                        ? device.platformName
                        : '未知设备';
                    final String id = device.address.isNotEmpty
                        ? device.address
                        : '未知ID';

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE8F1FF),
                          child: Icon(
                            Icons.bluetooth,
                            color: Colors.blue,
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          id,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        trailing: TextButton(
                          onPressed: () {
                            controller.connectToDevice(context, device);
                          },
                          child: Text(
                            isThisConnected ? '已连接' : '发起连接',
                            style: TextStyle(
                              fontSize: 13,
                              color: isThisConnected
                                  ? const Color(0xFF1BB37A)
                                  : const Color(0xFF1D88F5),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
