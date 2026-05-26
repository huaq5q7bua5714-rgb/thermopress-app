import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:poct_app/pages/home/home_contolller.dart';
import 'package:poct_app/pages/home/patient_controller.dart';
import 'dart:math';

class MeasurementPage extends StatefulWidget {
  const MeasurementPage({super.key});

  @override
  State<MeasurementPage> createState() => _MeasurementPageState();
}

class _MeasurementPageState extends State<MeasurementPage> {
  final controller = Get.find<HomeController>();
  late Worker _recordingWorker;
  // ===================== 浏览模式 viewport（温度 / 力 各一套） =====================
  double _tempViewMinX = 0;
  double _tempViewMaxX = 5;
  double _tempWindow = 5.0;

  double _forceViewMinX = 0;
  double _forceViewMaxX = 5;
  double _forceWindow = 5.0;

  // 捏合手势起始快照
  double _scaleStartTempWindow = 5.0;
  double _scaleStartTempViewMin = 0.0;
  double _scaleStartTempFocalX = 0.0;
  double _scaleStartForceWindow = 5.0;
  double _scaleStartForceViewMin = 0.0;
  double _scaleStartForceFocalX = 0.0;

  // ===================== Live Status 悬浮窗位置 =====================
  static const double _floatMargin = 8;
  static const double _floatMaxWidth = 340;
  static const double _floatEstimatedHeight = 190;

  final GlobalKey _liveStatsKey = GlobalKey();
  double _floatLeft = 12;
  double _floatTop = 12;

  @override
  void initState() {
    super.initState();

    _recordingWorker = ever<bool>(controller.isRecording, (recording) {
      if (!mounted) return;
      // ✅ Stop 时：重置浮窗位置（同时录制=false 就会自动隐藏浮窗）
      if (!recording) {
        setState(() {
          _resetFloatingPos();
        });
      }
      if (!recording && controller.points.isNotEmpty) {
        final pts = controller.points;
        final baseEpoch = controller.recordingStartEpochMs.value;
        final lastX =
            (pts.last.time.millisecondsSinceEpoch - baseEpoch) / 1000.0;

        setState(() {
          _tempViewMinX = max(0.0, lastX - _tempWindow);
          _tempViewMaxX = lastX;
          _forceViewMinX = max(0.0, lastX - _forceWindow);
          _forceViewMaxX = lastX;
        });
      }
    });
  }

  @override
  void dispose() {
    _recordingWorker.dispose();
    super.dispose();
  }

  void _resetFloatingPos() {
    _floatLeft = 16;
    _floatTop = 16;
  }

  Size _liveStatsSize(Size bounds) {
    final renderBox =
        _liveStatsKey.currentContext?.findRenderObject() as RenderBox?;
    final measuredSize = renderBox?.hasSize == true ? renderBox!.size : null;

    final fallbackWidth =
        min(_floatMaxWidth, max(0.0, bounds.width - _floatMargin * 2));
    return Size(
      measuredSize?.width ?? fallbackWidth,
      measuredSize?.height ?? _floatEstimatedHeight,
    );
  }

  void _clampFloatingPos(Size bounds) {
    final cardSize = _liveStatsSize(bounds);

    final maxLeft =
        max(_floatMargin, bounds.width - cardSize.width - _floatMargin);
    final maxTop =
        max(_floatMargin, bounds.height - cardSize.height - _floatMargin);

    _floatLeft = _floatLeft.clamp(_floatMargin, maxLeft);
    _floatTop = _floatTop.clamp(_floatMargin, maxTop);
  }

  // ===================== 捏合/平移手势（独立温度/力） =====================
  void _onScaleStart(ScaleStartDetails details, bool isTemp) {
    if (isTemp) {
      _scaleStartTempWindow = _tempWindow;
      _scaleStartTempViewMin = _tempViewMinX;
      _scaleStartTempFocalX = details.localFocalPoint.dx;
    } else {
      _scaleStartForceWindow = _forceWindow;
      _scaleStartForceViewMin = _forceViewMinX;
      _scaleStartForceFocalX = details.localFocalPoint.dx;
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details, bool isTemp) {
    if (controller.isRecording.value) return;
    final pts = controller.points;
    if (pts.isEmpty) return;

    final baseEpochMs = controller.recordingStartEpochMs.value;
    final maxAll =
        (pts.last.time.millisecondsSinceEpoch - baseEpochMs) / 1000.0;
    if (maxAll <= 0) return;

    final startWindow = isTemp ? _scaleStartTempWindow : _scaleStartForceWindow;
    final startViewMin =
        isTemp ? _scaleStartTempViewMin : _scaleStartForceViewMin;
    final startFocalX = isTemp ? _scaleStartTempFocalX : _scaleStartForceFocalX;

    // 图表数据区宽度（近似：屏幕宽 - 外边距 - 内边距 - Y轴标签）
    final chartWidth = MediaQuery.of(context).size.width - 44 - 32 - 8;
    if (chartWidth <= 0) return;

    // 捏合缩放：新窗口宽度
    final newWindow = (startWindow / details.scale).clamp(1.0, maxAll);

    // 保持手指焦点下的数据坐标不变
    final focalDataX = startViewMin + (startFocalX / chartWidth) * startWindow;
    double newMin =
        focalDataX - (details.localFocalPoint.dx / chartWidth) * newWindow;
    double newMax = newMin + newWindow;

    if (newMin < 0) {
      newMin = 0;
      newMax = newWindow;
    }
    if (newMax > maxAll) {
      newMax = maxAll;
      newMin = (maxAll - newWindow).clamp(0.0, maxAll);
    }

    setState(() {
      if (isTemp) {
        _tempWindow = newWindow;
        _tempViewMinX = newMin;
        _tempViewMaxX = newMax;
      } else {
        _forceWindow = newWindow;
        _forceViewMinX = newMin;
        _forceViewMaxX = newMax;
      }
    });
  }

  // ===================== Chart builder =====================
  LineChart _buildChart({
    required List<FlSpot> spots,
    required String unit,
    required Color color,
    required bool isTemp,
  }) {
    final recording = controller.isRecording.value;
    final window = isTemp ? _tempWindow : _forceWindow;
    final lastX = spots.isNotEmpty ? spots.last.x : 0.0;

    final minX = recording
        ? max(0.0, lastX - window).toDouble()
        : (isTemp ? _tempViewMinX : _forceViewMinX);

    final maxX = recording
        ? lastX.toDouble()
        : (isTemp ? _tempViewMaxX : _forceViewMaxX);

    double minY, maxY;
    if (spots.isEmpty) {
      minY = 0;
      maxY = 1;
    } else {
      const pad = 2.0;
      final vals = spots.map((s) => s.y);
      minY = vals.reduce(min) - pad;
      maxY = vals.reduce(max) + pad;
    }

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,

        clipData: const FlClipData.all(),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: true),

        // ==================== ✅【新增】自定义 Tooltip ====================
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              if (touchedSpots.isEmpty) return [];

              final spot = touchedSpots.first;

              final valueLine = '${spot.y.toStringAsFixed(1)} $unit';
              final timeLine = '${spot.x.toStringAsFixed(1)} s';

              return [
                LineTooltipItem(
                  '$valueLine\n$timeLine',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ];
            },
          ),
        ),

        // ===============================================================

        titlesData: FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (v, _) => Text(
                '${v.toStringAsFixed(1)}s',
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (v, _) => Text(
                '${v.toInt()}$unit',
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
        ),

        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 2,
            color: color,
            dotData: FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  // ===================== 图表卡片（捏合缩放 + 单指平移） =====================
  Widget _buildChartCard({
    required List<FlSpot> spots,
    required String unit,
    required Color color,
    required bool isTemp,
    required bool recording,
  }) {
    return GestureDetector(
      onScaleStart: recording ? null : (d) => _onScaleStart(d, isTemp),
      onScaleUpdate: recording ? null : (d) => _onScaleUpdate(d, isTemp),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            height: 220,
            child: _buildChart(
              spots: spots,
              unit: unit,
              color: color,
              isTemp: isTemp,
            ),
          ),
        ),
      ),
    );
  }

  // ===================== UI 小组件：Live Status =====================
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStatsCard({
    required bool hasData,
    required double currentForce,
    required double maxForce,
    required double minForce,
    required double avgForce,
    required double currentTemp,
    required double maxTemp,
    required double minTemp,
    required double avgTemp,
  }) {
    String fmt(double v) => v.toStringAsFixed(1);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '实时信息',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // ===== Temperature (LEFT) =====
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '温度',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildStatRow(
                          '当前值', hasData ? '${fmt(currentTemp)}°C' : '--'),
                      _buildStatRow(
                          '最大值', hasData ? '${fmt(maxTemp)}°C' : '--'),
                      _buildStatRow(
                          '最小值', hasData ? '${fmt(minTemp)}°C' : '--'),
                      _buildStatRow(
                          '平均值', hasData ? '${fmt(avgTemp)}°C' : '--'),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // ===== Pressure (RIGHT) =====
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '压力',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildStatRow(
                          '当前值', hasData ? '${fmt(currentForce)}N' : '--'),
                      _buildStatRow(
                          '最大值', hasData ? '${fmt(maxForce)}N' : '--'),
                      _buildStatRow(
                          '最小值', hasData ? '${fmt(minForce)}N' : '--'),
                      _buildStatRow(
                          '平均值', hasData ? '${fmt(avgForce)}N' : '--'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===================== Build =====================
  @override
  Widget build(BuildContext context) {
    final pc = Get.find<PatientController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Obx(() {
          final p = pc.currentPatient.value;
          return Text(
            p?.name ?? '测量',
            style: const TextStyle(fontWeight: FontWeight.w600),
          );
        }),
        actions: [
          Obx(() {
            final recording = controller.isRecording.value;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: recording ? Colors.redAccent : Colors.blue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: controller.toggleRecording,
                child: Text(
                  recording ? '停止并保存' : '开始测量',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            );
          }),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Obx(() {
            // ✅ 这一行放在 Obx 回调最上面
            final _ = controller.chartTick.value;
            final pts = controller.points;
            final hasData = pts.isNotEmpty;

            double currentForce = controller.latestForce.value;
            double currentTemp = controller.latestTemp.value;

            double maxForce = 0;
            double minForce = 0;
            double avgForce = 0;

            double maxTemp = 0;
            double minTemp = 0;
            double avgTemp = 0;

            if (hasData) {
              maxForce = pts.map((e) => e.force).reduce(max);
              minForce = pts.map((e) => e.force).reduce(min);
              avgForce =
                  pts.map((e) => e.force).reduce((a, b) => a + b) / pts.length;

              maxTemp = pts.map((e) => e.temperature).reduce(max);
              minTemp = pts.map((e) => e.temperature).reduce(min);
              avgTemp = pts.map((e) => e.temperature).reduce((a, b) => a + b) /
                  pts.length;
            }

            if (!hasData) {
              return const Center(
                child: Text(
                  '无数据 请点击开始测量',
                  style: TextStyle(color: Colors.black54),
                ),
              );
            }

            final baseEpochMs = controller.recordingStartEpochMs.value;

            final tempSpots = pts
                .map((p) => FlSpot(
                      (p.time.millisecondsSinceEpoch - baseEpochMs) / 1000.0,
                      p.temperature,
                    ))
                .toList();

            final forceSpots = pts
                .map((p) => FlSpot(
                      (p.time.millisecondsSinceEpoch - baseEpochMs) / 1000.0,
                      p.force,
                    ))
                .toList();

            return LayoutBuilder(
              builder: (context, constraints) {
                final stackSize = Size(
                  constraints.maxWidth.isFinite
                      ? constraints.maxWidth
                      : MediaQuery.of(context).size.width,
                  constraints.maxHeight.isFinite
                      ? constraints.maxHeight
                      : MediaQuery.of(context).size.height,
                );

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // ===== 背景：曲线页面（仍可滚动）=====
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ===== Temperature chart =====
                          _buildChartCard(
                            spots: tempSpots,
                            unit: '°C',
                            color: Colors.orange,
                            isTemp: true,
                            recording: controller.isRecording.value,
                          ),

                          const SizedBox(height: 16),

                          // ===== Force chart =====
                          _buildChartCard(
                            spots: forceSpots,
                            unit: 'N',
                            color: Colors.blue,
                            isTemp: false,
                            recording: controller.isRecording.value,
                          ),

                          // ✅ 原来的 Live Status 不再放在滚动里了（避免重复）
                          // ✅ 给底部留点空间，避免悬浮窗挡住内容
                          const SizedBox(height: 140),
                        ],
                      ),
                    ),

                    // ===== 前景：Live Status 悬浮窗（Start 出现，Stop 自动隐藏）=====
                    Obx(() {
                      if (!controller.isRecording.value) {
                        return const SizedBox.shrink();
                      }

                      return Positioned(
                        left: _floatLeft,
                        top: _floatTop,
                        child: GestureDetector(
                          onPanUpdate: (d) {
                            setState(() {
                              _floatLeft += d.delta.dx;
                              _floatTop += d.delta.dy;
                              _clampFloatingPos(stackSize);
                            });
                          },
                          onPanEnd: (_) {
                            setState(() {
                              _clampFloatingPos(stackSize);
                            });
                          },
                          child: Material(
                            key: _liveStatsKey,
                            color: Colors.transparent,
                            elevation: 8,
                            borderRadius: BorderRadius.circular(16),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: _floatMaxWidth,
                              ),
                              child: _buildLiveStatsCard(
                                hasData: hasData,
                                currentForce: currentForce,
                                maxForce: maxForce,
                                minForce: minForce,
                                avgForce: avgForce,
                                currentTemp: currentTemp,
                                maxTemp: maxTemp,
                                minTemp: minTemp,
                                avgTemp: avgTemp,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
