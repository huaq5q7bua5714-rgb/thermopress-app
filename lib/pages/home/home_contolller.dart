import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:poct_app/data/measurement_models.dart';
import 'package:poct_app/pages/router/measurement_result_page.dart';
import 'package:poct_app/util/curve_analyzer.dart';
import 'package:poct_app/util/reference_engine.dart';
import 'package:poct_app/widget/measurement_setup_dialog.dart';

import 'package:poct_app/util/ble_manager.dart';
import 'package:poct_app/util/permission_util.dart';
import 'package:poct_app/util/ua200_receiver.dart';

import '../../data/bluetooth_device_info.dart';
import '../../inter/ble_callback.dart';
import '../../util/snack_bar_manager.dart';
import '../../widget/loading_dialog.dart';
import '../../pages/measurement_page.dart';
import '../../pages/workspace_page.dart';
import '../../pages/bluetooth_set_page.dart';
import 'package:poct_app/pages/home/patient_controller.dart';

/// One sample point: time + temperature + force
class DataPoint {
  final DateTime time;
  final double temperature;
  final double force;

  DataPoint(this.time, this.temperature, this.force);
}

class HomeController extends GetxController with BleCallback {
  // Probe diameter 1.5 cm: area = pi * 0.75 * 0.75.
  static const double _probeAreaCm2 = 1.767;

  /// Bottom navigation pages
  final List<Widget> pageList = const [
    WorkspacePage(),
    MeasurementPage(),
    BluetoothSetPage(),
  ];

  /// Current tab index
  int currentIndex = 0;

  /// Current connected device info
  var bluetoothInfo = BluetoothDeviceInfo(
    platformName: "",
    address: "",
    isConnected: false,
    heatWorking: false,
    ledWorking: false,
  ).obs;

  // ====== Legacy fields kept for compatibility with old UI ======
  var sentTemp = "".obs;
  var sentTime = "".obs;
  var tempData = "".obs;
  var timeData = "".obs;

  /// Discovered devices
  var devices = <BluetoothDeviceInfo>[].obs;

  /// Latest temperature / force
  var latestTemp = 0.0.obs;
  var latestForce = 0.0.obs;

  /// Realtime curve data
  RxList<DataPoint> points = <DataPoint>[].obs;

  /// Recording flag
  RxBool isRecording = false.obs;

  /// ✅ X轴全局基准：一次录制只设置一次，points removeAt 不会影响
  final recordingStartEpochMs = 0.0.obs;

  /// Recorded data for saving
  final List<DataPoint> recordedPoints = [];

  MeasurementSessionDraft? _activeSession;

  /// Max number of cached points for curve display
  static const int maxPoints = 500;

  // ====================== MOCK STREAM (for dev) ======================
  Timer? _mockTimer;
  int _mockTick = 0;

  // 采样频率：10Hz（每 100ms 一个点）
  static const int _mockHz = 10;

  // 是否启用 Mock：当 BLE 未连接时自动启用
  bool get _shouldUseMock => !bluetoothInfo.value.isConnected;

  // ignore: unused_element
  void _startMockStream() {
    _stopMockStream();
    _mockTick = 0;

    final rnd = Random();

    _mockTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) {
        if (!isRecording.value) return;

        // t: seconds
        final t = _mockTick / _mockHz;
        _mockTick++;

        // 温度：36.5 附近缓慢波动 + 微小噪声
        final temp = 36.5 +
            0.6 * sin(t * 2 * pi / 8.0) +
            (rnd.nextDouble() - 0.5) * 0.08;

        // 压力：基线 + 脉冲（模拟按压）+ 微小噪声
        final pulse = max(0.0, sin(t * 2 * pi / 3.0)); // 0..1
        final force = 20.0 +
            120.0 * pow(pulse, 2).toDouble() +
            (rnd.nextDouble() - 0.5) * 2.0;

        _onNewSample(temp, force);
      },
    );

    SnackBarManager.instance.showSnackBar(
      "Mock enabled",
      "BLE not connected. Using internal mock data stream.",
    );
  }

  void _stopMockStream() {
    _mockTimer?.cancel();
    _mockTimer = null;
  }

  // ====== Legacy methods kept to avoid breaking UI ======

  void heatSwitch(bool heatState) {
    SnackBarManager.instance.showSnackBar(
      "Heater removed",
      "Remote heating control is not supported in this version.",
    );
  }

  void ledSwitch(bool ledState) {
    SnackBarManager.instance.showSnackBar(
      "LED removed",
      "LED control is not supported in this version.",
    );
  }

  void sendMessage() {
    SnackBarManager.instance.showSnackBar(
      "Function removed",
      "Please use the new recording & plotting workflow.",
    );
  }

  void changeIndex(int index) {
    currentIndex = index;
    update();
    // Auto scan when switching to Bluetooth tab (index == 1) and list is empty
    if (devices.isEmpty && currentIndex == 2) {
      scanDevices();
    }
  }

  @override
  void onInit() {
    super.onInit();
    PermissionUtil.requestBluetoothConnectPermission();
  }

  // ====================== BLE: Scan / Connect ======================

  /// Scan BLE devices
  void scanDevices() {
    PermissionUtil.requestBluetoothConnectPermission().then((hasPermission) {
      if (hasPermission) {
        devices.clear();
        BleManager.getInstance().setCallback(this);
        BleManager.getInstance().startScan(
          timeout: const Duration(seconds: 10),
        );
      } else {
        SnackBarManager.instance.showSnackBar(
          "Permission denied",
          "Bluetooth permission is required.",
        );
      }
    });
  }

  /// Connect / disconnect device
  Future<void> connectToDevice(
    BuildContext context,
    BluetoothDeviceInfo device,
  ) async {
    if (device.isConnected) {
      // Disconnect
      device.isConnected = false;
      await BleManager.getInstance().disconnect();
      bluetoothInfo.value = device;
      devices.refresh();
      return;
    }

    // Mark all devices as disconnected first
    for (var dev in devices) {
      dev.isConnected = false;
    }

    LoadingDialog.show("正在连接...");

    final dev = BleManager.getInstance().getDeviceFromAddress(device.address);
    if (dev != null) {
      try {
        final bool connected = await BleManager.getInstance().connect(dev);

        if (connected) {
          try {
            await dev.discoverServices();
          } catch (_) {}

          LoadingDialog.hide();
          device.isConnected = true;

          // Move current device to the top of the list
          devices.remove(device);
          devices.insert(0, device);
          bluetoothInfo.value = device;
        } else {
          LoadingDialog.hide();
          SnackBarManager.instance.showSnackBar(
            "连接失败",
            "无法连接设备 ${device.platformName}, 请重试",
          );
        }
      } catch (e) {
        LoadingDialog.hide();
        SnackBarManager.instance.showSnackBar(
          "Connection error",
          "Error: $e",
        );
      }
    } else {
      LoadingDialog.hide();
      SnackBarManager.instance.showSnackBar(
        "Connection error",
        "Device not found.",
      );
    }
  }

  // ====================== MCU COMMANDS ======================
  static const int _cmdStart = 0xAA; // 循环测量
  static const int _cmdStop = 0xFF; // 停止测量

  Future<void> _sendCmdToMcu(int cmd) async {
    if (!bluetoothInfo.value.isConnected) return;

    try {
      await BleManager.getInstance().sendCmdByte(cmd);
    } catch (e) {
      SnackBarManager.instance.showSnackBar(
        "发送命令失败",
        e.toString(),
      );
    }
  }

  // ====================== Recording & Saving ======================

  void toggleRecording() async {
    if (isRecording.value) {
      // ===== Stop & Save =====
      isRecording.value = false;

      // ✅【新增】如果是 BLE 连接状态，通知 MCU 停止测量
      if (!_shouldUseMock) {
        await _sendCmdToMcu(_cmdStop);
      }

      // 停止 mock（如果在用）
      _stopMockStream();

      // 保存 CSV
      final pc = Get.find<PatientController>();
      final p = pc.currentPatient.value;
      final phone = p?.phone ?? 'unknown';

      final path = await _saveToFile(phone); // ✅先拿到文件路径
      MeasurementSummary? summary;
      if (path != null) {
        summary =
            await _save_summary_to_patient(path); // ✅再保存 summary（含 filePath）
      }

      // 清空本次录制缓存（不清 points，方便停下来看图）
      recordedPoints.clear();
      _activeSession = null;
      final savedSummary = summary;
      if (savedSummary != null) {
        Get.to(() => MeasurementResultPage(summary: savedSummary));
      }
      return;
    }

    // ===== Start =====

    // ✅【P0保护】当前账号未创建病人时，禁止开始测量
    final pc = Get.find<PatientController>();
    if (pc.patients.isEmpty || pc.currentPatient.value == null) {
      SnackBarManager.instance.showSnackBar(
        "No patient",
        "Please add a patient first before starting measurement.",
      );
      changeIndex(0); // 可选：跳回 Patients 页
      return;
    }

    // 未连接蓝牙时禁止测量
    if (_shouldUseMock) {
      SnackBarManager.instance.showSnackBar(
        "未连接设备",
        "请先在蓝牙页连接设备后再开始测量。",
      );
      return;
    }

    final selection = await Get.dialog<MeasurementSelection>(
      const MeasurementSetupDialog(),
      barrierDismissible: false,
    );
    if (selection == null) return;

    final sessionStart = DateTime.now();
    _activeSession = MeasurementSessionDraft(
      sessionId: 'S${sessionStart.millisecondsSinceEpoch}',
      startTime: sessionStart,
      bodyRegion: selection.bodyRegion,
      symptomType: selection.symptomType,
      algorithmVersion: CurveAnalyzer.algorithmVersion,
    );

    // ✅✅【新增】设置本次录制的时间零点（非常关键）
    recordingStartEpochMs.value =
        sessionStart.millisecondsSinceEpoch.toDouble();

    // ✅ 关键：清空曲线数据，不然会接着上一次画
    points.clear();

    // （可选）清空 UI 显示的最新值
    latestTemp.value = 0.0;
    latestForce.value = 0.0;

    // 清空本次录制缓存
    recordedPoints.clear();

    isRecording.value = true;

    await _sendCmdToMcu(_cmdStart);

    SnackBarManager.instance.showSnackBar(
      "开始测量",
      "正在通过蓝牙采集数据。",
    );
  }

  /// ✅【新增 2】把 recordedPoints 计算成摘要，保存到 PatientController
  Future<MeasurementSummary?> _save_summary_to_patient(String filePath) async {
    if (recordedPoints.isEmpty) return null;

    final pc = Get.find<PatientController>();
    final p = pc.currentPatient.value;
    if (p == null) {
      Get.log('⚠ No current patient selected, skip summary saving.');
      return null;
    }

    final startTime = recordedPoints.first.time;
    final endTime = recordedPoints.last.time;
    final count = recordedPoints.length;

    double maxForce = recordedPoints.first.force;
    double minForce = recordedPoints.first.force;
    double sumForce = 0;

    double maxTemp = recordedPoints.first.temperature;
    double minTemp = recordedPoints.first.temperature;
    double sumTemp = 0;

    for (final dp in recordedPoints) {
      if (dp.force > maxForce) maxForce = dp.force;
      if (dp.force < minForce) minForce = dp.force;
      sumForce += dp.force;

      if (dp.temperature > maxTemp) maxTemp = dp.temperature;
      if (dp.temperature < minTemp) minTemp = dp.temperature;
      sumTemp += dp.temperature;
    }

    final fallbackStart = recordedPoints.first.time;
    final session = _activeSession ??
        MeasurementSessionDraft(
          sessionId: 'S${fallbackStart.millisecondsSinceEpoch}',
          startTime: fallbackStart,
          bodyRegion: BodyRegion.lumbosacral,
          symptomType: SymptomType.skipped,
          algorithmVersion: CurveAnalyzer.algorithmVersion,
        );

    final analysisPoints = recordedPoints
        .map(
          (p) => MeasurementPoint(
            time: p.time,
            temperature: p.temperature,
            force: p.force,
          ),
        )
        .toList();
    final curve = CurveAnalyzer.analyze(analysisPoints);
    final reference = curve.valid
        ? await ReferenceEngine.evaluate(
            bodyRegion: session.bodyRegion,
            pptForce: curve.pptValue,
            probeAreaCm2: _probeAreaCm2,
          )
        : ReferenceResult.unavailable(note: curve.invalidReason);
    final assessment = SensitizationEngine.evaluate(
      curve: curve,
      reference: reference,
    );

    final summary = MeasurementSummary(
      sessionId: session.sessionId,
      startTime: startTime,
      endTime: endTime,
      count: count,
      bodyRegion: BodyRegions.id(session.bodyRegion),
      symptomType: SymptomTypes.id(session.symptomType),
      algorithmVersion: curve.algorithmVersion,
      probeAreaCm2: _probeAreaCm2,
      maxForce: maxForce,
      minForce: minForce,
      avgForce: sumForce / count,
      maxTemp: maxTemp,
      minTemp: minTemp,
      avgTemp: sumTemp / count,
      filePath: filePath,
      pptValue: curve.pptValue,
      pptPressure: reference.pptPressure,
      pptTimeSec: curve.pptTimeSec,
      pptTemp: curve.pptTemperature,
      peakForce: curve.peakForce,
      riseRate: curve.riseRate,
      slopeChangeScore: curve.slopeChangeScore,
      peakPptRatio: curve.peakPptRatio,
      curveQualityScore: curve.qualityScore,
      curveValid: curve.valid,
      curveInvalidReason: curve.invalidReason,
      referencePercentile: reference.percentile,
      referenceStatus: reference.status,
      referenceSource: reference.source,
      referenceQuality: reference.quality,
      sensitizationLevel: assessment.level,
      suggestionText: assessment.suggestion,
    );

    pc.addMeasurementRecord(p.phone, summary); // ✅新增：写入历史

    Get.log('✅ Summary saved for patient ${p.phone}');
    return summary;
  }

  Future<String?> _saveToFile(String phone) async {
    if (recordedPoints.isEmpty) {
      SnackBarManager.instance.showSnackBar(
        "No data",
        "Nothing to save for this session.",
      );
      return null;
    }

    try {
      final ts = DateTime.now();
      String two(int n) => n.toString().padLeft(2, '0');
      final fileName =
          'record_${phone}_${ts.year}-${two(ts.month)}-${two(ts.day)}_${two(ts.hour)}-${two(ts.minute)}-${two(ts.second)}.csv';

      // ===== 1) 生成 CSV 文本 =====
      final buffer = StringBuffer();
      buffer.writeln('time,temp,force');
      for (final p in recordedPoints) {
        final t = p.time.toIso8601String();
        buffer.writeln('$t,${p.temperature},${p.force}');
      }
      final csvText = buffer.toString();

      File savedFile;
      if (Platform.isAndroid) {
        // ===== 2) 先保存到应用目录（兜底，不需要权限）=====
        final appDir = await getExternalStorageDirectory();
        if (appDir == null) throw Exception('External storage not available');
        final appFile = File('${appDir.path}/$fileName');
        await appFile.writeAsString(csvText, flush: true);
        Get.log('✅ Saved (app dir): ${appFile.path}');

        // ===== 3) 再保存到 Download/ThermoPressData（用户可见）=====
        // 目标目录：/storage/emulated/0/Download/ThermoPressData
        final downloadDir =
            Directory('/storage/emulated/0/Download/ThermoPressData');
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
        savedFile = File('${downloadDir.path}/$fileName');
      } else {
        final documentsDir = await getApplicationDocumentsDirectory();
        final dataDir = Directory('${documentsDir.path}/ThermoPressData');
        if (!await dataDir.exists()) {
          await dataDir.create(recursive: true);
        }
        savedFile = File('${dataDir.path}/$fileName');
      }

      await savedFile.writeAsString(csvText, flush: true);
      Get.log('✅ Saved CSV: ${savedFile.path}');

      // ===== 4) 提示用户（SnackBar + log）=====
      SnackBarManager.instance.showSnackBar(
        "Saved",
        "已保存到：\n${savedFile.path}",
      );
      return savedFile.path;
    } catch (e) {
      Get.log('❌ Save failed: $e');
      SnackBarManager.instance.showSnackBar(
        "Save failed",
        e.toString(),
      );
      return null;
    }
  }

  // ✅ UI 用节流 tick
  final chartTick = 0.obs;
  Timer? _chartTickTimer;
  bool _chartTickPending = false;

  void _requestChartRebuild() {
    if (_chartTickPending) return;
    _chartTickPending = true;
    _chartTickTimer ??= Timer(const Duration(milliseconds: 33), () {
      chartTick.value++; // 15Hz
      _chartTickPending = false;
      _chartTickTimer = null;
    });
  }

  /// When a new sample is received (called inside onDataReceived)
  void _onNewSample(double temp, double force) {
    final now = DateTime.now();

    latestTemp.value = temp;
    latestForce.value = force;

    // Legacy UI: use string
    tempData.value = temp.toStringAsFixed(2);
    timeData.value = force.toStringAsFixed(2);

    final point = DataPoint(now, temp, force);

    if (isRecording.value) {
      recordedPoints.add(point);
    }

    points.add(point);

    // ✅ sliding window（高效裁剪）
    if (points.length > maxPoints) {
      final extra = points.length - maxPoints;
      points.removeRange(0, extra);
    }
    _requestChartRebuild();
  }

  // ====================== BleCallback callbacks ======================

  @override
  void onScanResult(BluetoothDevice device) {
    if (device.platformName.isEmpty) return;

    if (devices.any((dev) => dev.address == device.remoteId.toString())) {
      return;
    }

    Get.log(
        'Discovered device: ${device.platformName}, id: ${device.remoteId}');
    final dev = BluetoothDeviceInfo(
      platformName: device.platformName,
      address: device.remoteId.toString(),
    );
    devices.add(dev);
  }

  @override
  void onConnectSuccess() {
    Get.log('蓝牙已连接');
  }

  @override
  void onDisconnected() async {
    Get.log('蓝牙已断开');

    final wasRecording = isRecording.value; // ✅【新增】记录断开前是否在测量

    // ===== 统一 UI 提示（稍后可能被覆盖）=====
    SnackBarManager.instance.showSnackBar(
      "蓝牙已断开",
      "",
    );

    // ===== 如果正在录制，立刻停止 =====
    if (wasRecording) {
      isRecording.value = false;
      _stopMockStream(); // 不自动切 mock，保持行为可预期
    }

    // ===== ✅【新增】断开时自动保存已测数据 =====
    if (wasRecording && recordedPoints.isNotEmpty) {
      try {
        final pc = Get.find<PatientController>();
        final p = pc.currentPatient.value;
        final phone = p?.phone ?? 'unknown';

        // 1) 保存 CSV
        final path = await _saveToFile(phone);

        // 2) 保存 summary（含文件路径）
        if (path != null) {
          await _save_summary_to_patient(path);
        }

        // 3) 清空本次缓存
        recordedPoints.clear();
        _activeSession = null;

        // 4) 给用户一个明确反馈
        SnackBarManager.instance.showSnackBar(
          "蓝牙已断开",
          "蓝牙已断开 测量数据已经自动保存",
        );
      } catch (e) {
        Get.log('❌ Auto-save on disconnect failed: $e');
      }
    }

    // ===== 重置 BLE 数据解析缓存 =====
    Ua200Receiver.reset();

    // ===== 统一清连接状态（这是唯一权威源）=====
    bluetoothInfo.value.isConnected = false;

    for (final device in devices) {
      device.isConnected = false;
    }

    bluetoothInfo.refresh();
    devices.refresh();
  }

  @override
  void onConnectFailed(String error) {
    Get.log('蓝牙连接失败: $error');
  }

  int _dbg_cnt = 0;
  DateTime _dbg_last = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void onDataReceived(List<int> data) {
    if (_shouldUseMock) {
      // 当前用 mock，就不要处理 BLE 数据
      return;
    }
    //Get.log('Raw data received: $data');
    // ✅ debug 限频，避免卡死
    _dbg_cnt++;
    final now = DateTime.now();
    if (now.difference(_dbg_last).inMilliseconds >= 1000) {
      _dbg_last = now;
      Get.log('BLE notify rate: $_dbg_cnt /s, last_len=${data.length}');
      _dbg_cnt = 0;
    }
    // Example: Ua200Receiver.parseFrame returns {"temp": "...", "force": "..."}
    final parsed = Ua200Receiver.parseFrame(data);
    if (parsed == null) {
      Get.log("Failed to parse frame");
      return;
    }

    final tempStr = parsed['temp'];
    final forceStr = parsed['force'];

    if (tempStr == null || forceStr == null) {
      Get.log("Parsed result missing temp or force: $parsed");
      return;
    }

    final temp = double.tryParse(tempStr);
    final force = double.tryParse(forceStr);

    if (temp == null || force == null) {
      Get.log("Parse double failed: temp=$tempStr, force=$forceStr");
      return;
    }

    _onNewSample(temp, force);
  }

  @override
  void onClose() {
    _stopMockStream();
    super.onClose();
  }
}
