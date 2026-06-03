import 'dart:io';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:poct_app/pages/home/patient_controller.dart';

class MeasurementResultPage extends StatefulWidget {
  final MeasurementSummary summary;

  const MeasurementResultPage({
    super.key,
    required this.summary,
  });

  @override
  State<MeasurementResultPage> createState() => _MeasurementResultPageState();
}

class _MeasurementResultPageState extends State<MeasurementResultPage> {
  bool _loading = true;
  List<FlSpot> _forceSpots = [];

  @override
  void initState() {
    super.initState();
    _loadCsv();
  }

  Future<void> _loadCsv() async {
    final path = widget.summary.filePath;
    if (path.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    try {
      final file = File(path);
      if (!await file.exists()) {
        setState(() => _loading = false);
        return;
      }

      final lines = await file.readAsLines();
      DateTime? start;
      final spots = <FlSpot>[];
      for (int i = 1; i < lines.length; i++) {
        final parts = lines[i].split(',');
        if (parts.length < 3) continue;
        final time = DateTime.tryParse(parts[0].trim());
        final force = double.tryParse(parts[2].trim());
        if (time == null || force == null) continue;
        start ??= time;
        final sec = time.difference(start).inMilliseconds / 1000.0;
        spots.add(FlSpot(sec, force));
      }
      setState(() {
        _forceSpots = spots;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  String _fmt(double value, [int digits = 1]) => value.toStringAsFixed(digits);

  Widget _metric(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 3),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultCard() {
    final s = widget.summary;
    final percentile = s.referenceStatus == 'ok'
        ? '第 ${_fmt(s.referencePercentile, 0)} 百分位'
        : '暂无参考';
    final pressure =
        s.pptPressure > 0 ? '${_fmt(s.pptPressure, 1)} N/cm²' : '--';
    final mlRisk = s.hasMlRisk
        ? '${s.mlRiskLabel} ${_fmt(s.mlRiskScore * 100, 0)}%'
        : '--';
    final mlConfidence =
        s.hasMlRisk ? '${_fmt(s.mlConfidence * 100, 0)}%' : '--';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.sensitizationLabel,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _levelColor(s.sensitizationLevel),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${s.siteLabel} · ${s.symptomTypeLabel}',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1.85,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                _metric('PPT', s.hasPpt ? '${_fmt(s.pptValue, 1)} N' : '--'),
                _metric('标准化压力', pressure),
                _metric('参考位置', percentile),
                _metric('曲线质量', '${_fmt(s.curveQualityScore, 0)} / 100'),
                _metric('敏化风险分层', mlRisk),
                _metric('评估可信度', mlConfidence),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              s.suggestionText.isEmpty
                  ? '本次结果已保存，可在患者历史中回看。'
                  : s.suggestionText,
              style: const TextStyle(
                  fontSize: 13, color: Colors.black87, height: 1.4),
            ),
            if (s.hasMlRisk && s.mlReasonText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '机器学习判别依据：${s.mlReasonText}',
                style: TextStyle(
                  fontSize: 13,
                  color: _mlRiskColor(s.mlRiskLevel),
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chartCard() {
    if (_loading) {
      return const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_forceSpots.isEmpty) {
      return const SizedBox.shrink();
    }

    final ys = _forceSpots.map((e) => e.y);
    final minY = max(0.0, ys.reduce(min) - 2);
    final maxY = ys.reduce(max) + 2;
    final bars = <LineChartBarData>[
      LineChartBarData(
        spots: _forceSpots,
        isCurved: false,
        barWidth: 2,
        color: Colors.blue,
        dotData: const FlDotData(show: false),
      ),
    ];

    if (widget.summary.hasPpt) {
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

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '压力曲线与PPT标记',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 230,
              child: LineChart(
                LineChartData(
                  minX: _forceSpots.first.x,
                  maxX: _forceSpots.last.x,
                  minY: minY,
                  maxY: maxY,
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                  titlesData: FlTitlesData(
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (v, _) => Text(
                          '${v.toStringAsFixed(0)}s',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (v, _) => Text(
                          '${v.toStringAsFixed(0)}N',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                  lineBarsData: bars,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _levelColor(String level) {
    switch (level) {
      case 'marked_low':
        return Colors.redAccent;
      case 'low':
        return Colors.deepOrange;
      case 'mild_low':
        return Colors.orange;
      case 'reference_range':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }

  Color _mlRiskColor(String level) {
    switch (level) {
      case 'high':
        return Colors.redAccent;
      case 'medium':
        return Colors.deepOrange;
      case 'low':
        return Colors.green;
      case 'uncertain':
        return Colors.blueGrey;
      default:
        return Colors.black54;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        title: const Text('测量结果'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _resultCard(),
            const SizedBox(height: 14),
            _chartCard(),
          ],
        ),
      ),
    );
  }
}
