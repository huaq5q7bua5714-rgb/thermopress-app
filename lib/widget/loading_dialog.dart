import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

class LoadingDialog {
  static void show([String? msg]) {
    Get.dialog(
      PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16), // 减小内边距
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min, // 设置为最小宽度
              children: [
                SizedBox(
                  width: 24, // 减小加载图标尺寸
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0, // 可以适当减小进度条宽度
                  ),
                ),
                SizedBox(width: 12), // 减小间距
                Text(
                  msg ?? "加载中...",
                  style: TextStyle(fontSize: 14, color: Colors.black), // 可以适当调整字体大小
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  static void hide() {
    if (Get.isDialogOpen ?? false) {
      Get.back(closeOverlays: true);
    }
  }
}