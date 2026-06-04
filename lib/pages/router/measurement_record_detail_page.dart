import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:poct_app/pages/home/patient_controller.dart';

class MeasurementRecordDetailPage extends StatefulWidget {
  final MeasurementSummary summary;

  const MeasurementRecordDetailPage({
    Key? key,
    required this.summary,
  }) : super(key: key);

  @override
  State<MeasurementRecordDetailPage> createState() =>
      _MeasurementRecordDetailPageState();
}

class _MeasurementRecordDetailPageState
    extends State<MeasurementRecordDetailPage> {
  bool _loading = true;
  String? _error;

  List<double> _x = [];
  List<DateTime> _time = [];
  List<double> _temp = [];
  List<double> _force = [];

  // 温度窗口
  double _tempViewMinX = 0;
  double _tempViewMaxX = 5;
  double _tempWindow = 5;

  // 力窗口
  double _forceViewMinX = 0;
  double _forceViewMaxX = 5;
  double _forceWindow = 5;

  // 捏合手势起始快照
  double _scaleStartTempWindow = 5.0;
  double _scaleStartTempViewMin = 0.0;
  double _scaleStartTempFocalX = 0.0;
  double _scaleStartForceWindow = 5.0;
  double _scaleStartForceViewMin = 0.0;
  double _scaleStartForceFocalX = 0.0;

  static const double _yPad = 2.0;

  String two(int v) => v.toString().padLeft(2, '0');
  String fmtDt(DateTime dt) =>
      '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';

  @override
  void initState() {
    super.initState();
    _load_csv();
  }

  Future<void> _load_csv() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final file = await _resolveCsvFile(widget.summary.filePath);
      if (file == null) {
        throw '原始CSV文件未找到，仅显示本次测量摘要。';
      }

      final lines = await file.readAsLines();
      if (lines.length <= 1) {
        throw 'CSV为空，仅显示本次测量摘要。';
      }

      final x = <double>[];
      final time = <DateTime>[];
      final temp = <double>[];
      final force = <double>[];

      DateTime? start;

      for (int i = 1; i < lines.length; i++) {
        final parts = lines[i].split(',');
        if (parts.length < 3) continue;

        final tStr = parts[0].trim();
        final teStr = parts[1].trim();
        final foStr = parts[2].trim();

        final dt = DateTime.tryParse(tStr);
        final te = double.tryParse(teStr);
        final fo = double.tryParse(foStr);

        if (dt == null || te == null || fo == null) continue;

        final startTime = start ?? dt;
        start = startTime;
        final sec = dt.difference(startTime).inMilliseconds / 1000.0;

        time.add(dt);
        x.add(sec);
        temp.add(te);
        force.add(fo);
      }

      if (x.isEmpty) {
        throw 'CSV中没有有效采样点，仅显示本次测量摘要。';
      }

      _x = x;
      _time = time;
      _temp = temp;
      _force = force;

      final total = _x.last - _x.first;

      double win = 5.0;
      if (total <= 0) {
        win = 1.0;
      } else if (total < 5.0) {
        win = total;
      }

      _tempWindow = win;
      _tempViewMinX = _x.first;
      _tempViewMaxX = _x.first + _tempWindow;

      _forceWindow = win;
      _forceViewMinX = _x.first;
      _forceViewMaxX = _x.first + _forceWindow;

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  Future<File?> _resolveCsvFile(String savedPath) async {
    final path = savedPath.trim();
    if (path.isEmpty) return null;

    final directFile = File(path);
    if (await directFile.exists()) return directFile;

    // iOS sandbox paths can change after reinstall/update. Keep old records
    // usable by resolving the saved file name in the current Documents folder.
    final fileName = _fileNameFromPath(path);
    if (fileName.isEmpty) return null;

    final documentsDir = await getApplicationDocumentsDirectory();
    final candidates = <File>[
      File('${documentsDir.path}/ThermoPressData/$fileName'),
      File('${documentsDir.path}/$fileName'),
    ];

    if (Platform.isAndroid) {
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        candidates.add(File('${externalDir.path}/$fileName'));
        candidates.add(File('${externalDir.path}/ThermoPressData/$fileName'));
      }
      candidates.add(
        File('/storage/emulated/0/Download/ThermoPressData/$fileName'),
      );
    }

    for (final file in candidates) {
      if (await file.exists()) return file;
    }

    return null;
  }

  String _fileNameFromPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    final parts = normalized.split('/');
    return parts.isEmpty ? '' : parts.last.trim();
  }

  // Y轴刻度间距（约5~7个刻度）
  double _nice_interval(double range) {
    if (range <= 10) return 3;
    if (range <= 20) return 7;
    if (range <= 50) return 15;
    if (range <= 80) return 25;
    if (range <= 120) return 30;
    if (range <= 200) return 60;
    return 100;
  }

  // X轴刻度间距（约4~6个刻度）
  double _nice_x_interval(double windowSec) {
    if (windowSec <= 1) return 0.2;
    if (windowSec <= 2) return 0.5;
    if (windowSec <= 5) return 1;
    if (windowSec <= 15) return 2;
    if (windowSec <= 30) return 5;
    if (windowSec <= 60) return 10;
    if (windowSec <= 150) return 30;
    if (windowSec <= 300) return 60;
    return 120;
  }

  double _floor_to(double v, double step) => (v / step).floorToDouble() * step;
  double _ceil_to(double v, double step) => (v / step).ceilToDouble() * step;

  // 根据当前X视窗内的可见数据自动计算Y轴范围，返回 [minY, maxY, interval]
  List<double> _autoYRange(List<double> y, double viewMinX, double viewMaxX) {
    double lo = double.infinity;
    double hi = double.negativeInfinity;
    for (int i = 0; i < _x.length; i++) {
      if (_x[i] >= viewMinX - 1e-9 && _x[i] <= viewMaxX + 1e-9) {
        if (y[i] < lo) lo = y[i];
        if (y[i] > hi) hi = y[i];
      }
    }
    if (lo == double.infinity) {
      lo = y.reduce((a, b) => a < b ? a : b);
      hi = y.reduce((a, b) => a > b ? a : b);
    }
    final rawMin = lo - _yPad;
    final rawMax = hi + _yPad;
    final step = _nice_interval((rawMax - rawMin).abs());
    final minY = _floor_to(rawMin, step);
    double maxY = _ceil_to(rawMax, step);
    if (maxY - minY < step) maxY = minY + step;
    return [minY, maxY, step];
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
    if (_x.isEmpty) return;
    final minAll = _x.first;
    final maxAll = _x.last;
    final span = maxAll - minAll;
    if (span <= 0) return;

    final chartWidth = MediaQuery.of(context).size.width - 54 - 32 - 8;
    if (chartWidth <= 0) return;

    final startWindow = isTemp ? _scaleStartTempWindow : _scaleStartForceWindow;
    final startViewMin =
        isTemp ? _scaleStartTempViewMin : _scaleStartForceViewMin;
    final startFocalX = isTemp ? _scaleStartTempFocalX : _scaleStartForceFocalX;

    double newMin, newMax, newWindow;

    if (details.pointerCount >= 2) {
      // 双指捏合：缩放X轴，焦点位置对应数据点保持不变
      final hScale =
          details.horizontalScale > 0 ? details.horizontalScale : 1.0;
      newWindow = (startWindow / hScale).clamp(0.5, span);
      final focalDataX =
          startViewMin + (startFocalX / chartWidth) * startWindow;
      newMin =
          focalDataX - (details.localFocalPoint.dx / chartWidth) * newWindow;
    } else {
      // 单指：从手势起点计算绝对偏移量，避免逐帧累积误差
      newWindow = startWindow;
      final deltaPixels = startFocalX - details.localFocalPoint.dx;
      newMin = startViewMin + (deltaPixels / chartWidth) * newWindow;
    }

    newMax = newMin + newWindow;
    if (newMin < minAll) {
      newMin = minAll;
      newMax = minAll + newWindow;
    }
    if (newMax > maxAll) {
      newMax = maxAll;
      newMin = (maxAll - newWindow).clamp(minAll, maxAll);
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

  LineChartBarData _line(List<double> y, Color color) {
    final spots = <FlSpot>[];
    for (int i = 0; i < _x.length; i++) {
      spots.add(FlSpot(_x[i], y[i]));
    }

    return LineChartBarData(
      spots: spots,
      isCurved: false,
      barWidth: 2,
      color: color,
      dotData: const FlDotData(show: false),
    );
  }

  LineChartData _chart({
    required String title,
    required List<double> y,
    required String unitSuffix,
    required Color color,
    required double minY,
    required double maxY,
    required double yInterval,
    required double viewMinX,
    required double viewMaxX,
  }) {
    final bars = <LineChartBarData>[_line(y, color)];
    if (unitSuffix == 'N' && widget.summary.hasPpt) {
      bars.add(
        LineChartBarData(
          spots: [FlSpot(widget.summary.pptTimeSec, widget.summary.pptValue)],
          isCurved: false,
          barWidth: 0,
          color: Colors.redAccent,
          dotData: const FlDotData(show: true),
        ),
      );
    }

    return LineChartData(
      minX: viewMinX,
      maxX: viewMaxX,
      minY: minY,
      maxY: maxY,
      clipData: const FlClipData.all(),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        drawHorizontalLine: true,
        getDrawingHorizontalLine: (value) => const FlLine(
          color: Color(0xFFBDBDBD),
          strokeWidth: 1,
          dashArray: [6, 6],
        ),
        getDrawingVerticalLine: (value) => const FlLine(
          color: Color(0xFFBDBDBD),
          strokeWidth: 1,
          dashArray: [6, 6],
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: const Border.fromBorderSide(
          BorderSide(color: Color(0xFFBDBDBD), width: 1),
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 54,
            interval: yInterval,
            getTitlesWidget: (value, meta) {
              if (value < minY - 1e-6 || value > maxY + 1e-6) {
                return const SizedBox.shrink();
              }
              return Text(
                '${value.toStringAsFixed(0)}$unitSuffix',
                style: const TextStyle(fontSize: 11),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 26,
            interval: _nice_x_interval(viewMaxX - viewMinX),
            getTitlesWidget: (value, meta) {
              final step = _nice_x_interval(viewMaxX - viewMinX);
              if ((value % step).abs() > step * 0.05)
                return const SizedBox.shrink();
              final label = step < 1
                  ? '${value.toStringAsFixed(1)}s'
                  : '${value.round()}s';
              return Text(label, style: const TextStyle(fontSize: 11));
            },
          ),
        ),
      ),
      lineBarsData: bars,
      lineTouchData: LineTouchData(
        enabled: true,
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (spots) {
            if (spots.isEmpty) return [];
            final s = spots.first;
            final idx = s.spotIndex;
            if (idx < 0 || idx >= _time.length) return [];

            final dt = _time[idx];
            final v = y[idx];

            return [
              LineTooltipItem(
                '$title\n${fmtDt(dt)}\n${v.toStringAsFixed(2)}$unitSuffix',
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ];
          },
        ),
      ),
    );
  }

  Widget _buildDetailChartCard({
    required bool isTemp,
    required String title,
    required List<double> y,
    required String unitSuffix,
    required Color color,
    required double viewMinX,
    required double viewMaxX,
  }) {
    final yr = _autoYRange(y, viewMinX, viewMaxX);
    return GestureDetector(
      onScaleStart: (d) => _onScaleStart(d, isTemp),
      onScaleUpdate: (d) => _onScaleUpdate(d, isTemp),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            height: 220,
            child: LineChart(
              _chart(
                title: title,
                y: y,
                unitSuffix: unitSuffix,
                color: color,
                minY: yr[0],
                maxY: yr[1],
                yInterval: yr[2],
                viewMinX: viewMinX,
                viewMaxX: viewMaxX,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat_line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: Colors.black54)),
          Text(value,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.summary.filePath;
    final hasRawCurve = _error == null && _x.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        title: const SizedBox.shrink(),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ✅ Summary card：温度先写，力后写；字段齐全
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('开始时间: ${fmtDt(widget.summary.startTime)}',
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.black54)),
                          const SizedBox(height: 4),
                          Text('结束时间: ${fmtDt(widget.summary.endTime)}',
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.black54)),
                          const SizedBox(height: 8),
                          Text('采样点数: ${widget.summary.count}',
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.black54)),
                          if (widget.summary.hasPpt) ...[
                            const SizedBox(height: 12),
                            const Text('智能评估',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.teal)),
                            const SizedBox(height: 6),
                            _stat_line('测量部位', widget.summary.siteLabel),
                            if (widget.summary.acupointMeridian.isNotEmpty)
                              _stat_line('经络', widget.summary.acupointMeridian),
                            _stat_line('主诉类型', widget.summary.symptomTypeLabel),
                            _stat_line('PPT',
                                '${widget.summary.pptValue.toStringAsFixed(1)} N'),
                            _stat_line('标准化压力',
                                '${widget.summary.pptPressure.toStringAsFixed(1)} N/cm²'),
                            _stat_line(
                              '参考百分位',
                              widget.summary.referenceStatus == 'ok'
                                  ? '第 ${widget.summary.referencePercentile.toStringAsFixed(0)} 百分位'
                                  : '暂无参考',
                            ),
                            _stat_line(
                                '参考策略', widget.summary.referenceModeLabel),
                            _stat_line(
                                '敏化提示', widget.summary.sensitizationLabel),
                            _stat_line('曲线质量',
                                '${widget.summary.curveQualityScore.toStringAsFixed(0)} / 100'),
                            if (widget.summary.hasMlRisk) ...[
                              const SizedBox(height: 8),
                              const Text('机器学习辅助评估',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.indigo)),
                              const SizedBox(height: 6),
                              _stat_line(
                                '敏化风险分层',
                                '${widget.summary.mlRiskLabel} '
                                    '${(widget.summary.mlRiskScore * 100).toStringAsFixed(0)}%',
                              ),
                              _stat_line(
                                '评估可信度',
                                '${(widget.summary.mlConfidence * 100).toStringAsFixed(0)}%',
                              ),
                              _stat_line('算法模型', widget.summary.mlModelVersion),
                              if (widget.summary.mlReasonText.isNotEmpty)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    '主要影响因素：${widget.summary.mlReasonText}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                            ],
                          ],
                          const SizedBox(height: 12),
                          const Text('温度',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.orange)),
                          const SizedBox(height: 6),
                          _stat_line('最大值',
                              '${widget.summary.maxTemp.toStringAsFixed(1)} °C'),
                          _stat_line('最小值',
                              '${widget.summary.minTemp.toStringAsFixed(1)} °C'),
                          _stat_line('平均值',
                              '${widget.summary.avgTemp.toStringAsFixed(1)} °C'),
                          const SizedBox(height: 12),
                          const Text('压力',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.blue)),
                          const SizedBox(height: 6),
                          _stat_line('最大值',
                              '${widget.summary.maxForce.toStringAsFixed(1)} N'),
                          _stat_line('最小值',
                              '${widget.summary.minForce.toStringAsFixed(1)} N'),
                          _stat_line('平均值',
                              '${widget.summary.avgForce.toStringAsFixed(1)} N'),
                          const SizedBox(height: 10),
                          Text(
                            path.isEmpty ? 'CSV文件: 无' : 'CSV文件: $path',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black45),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  if (!hasRawCurve)
                    _buildNoticeCard(_error ?? '原始曲线文件不可用')
                  else ...[
                    // 温度图
                    _buildDetailChartCard(
                      isTemp: true,
                      title: '温度',
                      y: _temp,
                      unitSuffix: '°C',
                      color: const Color(0xFFF4A460),
                      viewMinX: _tempViewMinX,
                      viewMaxX: _tempViewMaxX,
                    ),

                    const SizedBox(height: 14),

                    // 压力图
                    _buildDetailChartCard(
                      isTemp: false,
                      title: '压力',
                      y: _force,
                      unitSuffix: 'N',
                      color: const Color(0xFF4A90E2),
                      viewMinX: _forceViewMinX,
                      viewMaxX: _forceViewMaxX,
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildNoticeCard(String message) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: Colors.orange),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
