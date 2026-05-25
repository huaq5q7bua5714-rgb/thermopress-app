import 'dart:convert';

class Ua200Receiver {
  static String _buffer = '';

  /// 解析一帧数据，格式:
  /// temp,force\r\n   例如: "36.50,12.34\r\n"
  ///
  /// 注意：BLE notify 可能会分包/粘包，因此必须做 buffer 拼接 + 按 '\n' 切帧
  static Map<String, String>? parseFrame(List<int> data) {
    // 1) 追加收到的字节（转成字符串）
    _buffer += utf8.decode(data, allowMalformed: true);

    // 2) 找到一帧结束标志：'\n'
    final idx = _buffer.indexOf('\n');
    if (idx == -1) {
      // 还没收到完整一帧
      return null;
    }

    // 3) 取出一行（去掉末尾 \r）
    String line = _buffer.substring(0, idx);
    line = line.trim(); // 会去掉 \r 和空格

    // 4) 从 buffer 中移除这一帧（包含 \n）
    _buffer = _buffer.substring(idx + 1);

    // 5) 空行直接丢弃
    if (line.isEmpty) return null;

    // 6) 按逗号拆分：temp,force
    final parts = line.split(',');
    if (parts.length != 2) {
      // 协议不匹配，丢弃这一行
      // 但不要清空 buffer，避免丢后续帧
      // （你也可以选择在这里 Get.log）
      return null;
    }

    final temp = parts[0].trim();
    final force = parts[1].trim();

    return {
      'temp': temp,
      'force': force,
    };
  }

  /// （可选）提供一个重置 buffer 的接口：断开/重连时调用更干净
  static void reset() {
    _buffer = '';
  }
}
