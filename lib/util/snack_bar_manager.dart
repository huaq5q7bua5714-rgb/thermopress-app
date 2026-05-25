import 'package:get/get.dart';
import 'package:flutter/material.dart';

class SnackBarManager {
  factory SnackBarManager() => instance;

  static final SnackBarManager instance = SnackBarManager._internal();

  SnackBarManager._internal();


  String _lastMessage = '';

  int _lastDuration = 0;

  int _lastTime = 0;

  void showSnackBar(String title, String message, {Color? backgroundColor, Duration? duration}) {
    var currentTime = DateTime.now().millisecondsSinceEpoch;
    // 相同消息持续时间内重复提交时，返回
    if (currentTime - _lastTime < _lastDuration * 1000 && _lastMessage == message) {
      return;
    }

    dismissSnackBar();

    Get.snackbar(
      title,
      message,
      backgroundColor: backgroundColor ?? Colors.black12,
      duration: duration ?? Duration(seconds: 2), // 提示框持续时间
    );

    _lastDuration = duration?.inSeconds ?? 2;
    _lastTime = DateTime.now().millisecondsSinceEpoch;
    _lastMessage = message;
  }

  void dismissSnackBar() {
    Get.closeCurrentSnackbar();
  }
}
