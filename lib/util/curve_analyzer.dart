import 'dart:math';

import 'package:poct_app/data/measurement_models.dart';

class CurveAnalyzer {
  static const String algorithmVersion = 'ppt_v1_stop_window';

  static CurveAnalysisResult analyze(List<MeasurementPoint> samples) {
    final clean = samples
        .where((p) =>
            p.force.isFinite &&
            p.temperature.isFinite &&
            !p.force.isNaN &&
            !p.temperature.isNaN)
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));

    if (clean.length < 8) {
      return CurveAnalysisResult.invalid(
        '采样点过少，无法分析',
        algorithmVersion: algorithmVersion,
      );
    }

    final start = clean.first.time;
    final seconds = clean
        .map((p) => p.time.difference(start).inMilliseconds / 1000.0)
        .toList();
    final duration = seconds.last - seconds.first;
    if (duration < 1.0) {
      return CurveAnalysisResult.invalid(
        '测量时长过短',
        algorithmVersion: algorithmVersion,
      );
    }

    final rawForce = clean.map((p) => p.force).toList();
    final smoothForce = _movingAverage(rawForce, 5);

    final peakForce = smoothForce.reduce(max);
    final peakIndex = smoothForce.indexOf(peakForce);
    if (peakForce < 2.0) {
      return CurveAnalysisResult.invalid(
        '压力峰值过低，未形成有效按压',
        algorithmVersion: algorithmVersion,
      );
    }

    final baselineValues = <double>[];
    for (int i = 0; i < clean.length; i++) {
      if (seconds[i] <= 0.5) baselineValues.add(smoothForce[i]);
    }
    final baseline = baselineValues.isEmpty
        ? smoothForce.first
        : baselineValues.reduce((a, b) => a + b) / baselineValues.length;
    final contactThreshold = baseline + max(0.5, (peakForce - baseline) * 0.05);

    var contactIndex = 0;
    for (int i = 0; i < smoothForce.length; i++) {
      if (smoothForce[i] >= contactThreshold) {
        contactIndex = i;
        break;
      }
    }

    final lastTime = seconds.last;
    final windowStart = max(seconds.first, lastTime - 0.5);
    var pptIndex = peakIndex;
    var pptValue = double.negativeInfinity;
    for (int i = 0; i < smoothForce.length; i++) {
      if (seconds[i] >= windowStart && smoothForce[i] > pptValue) {
        pptValue = smoothForce[i];
        pptIndex = i;
      }
    }

    if (!pptValue.isFinite || pptValue <= baseline + 0.5) {
      return CurveAnalysisResult.invalid(
        '停止前未检测到有效PPT峰值',
        algorithmVersion: algorithmVersion,
      );
    }

    final contactSec = seconds[contactIndex];
    final pptSec = seconds[pptIndex];
    final riseDuration = max(0.001, pptSec - contactSec);
    final riseRate = (pptValue - smoothForce[contactIndex]) / riseDuration;
    final slopeBefore = _meanSlope(seconds, smoothForce, pptSec - 0.4, pptSec);
    final slopeAfter = _meanSlope(seconds, smoothForce, pptSec, pptSec + 0.4);
    final slopeChangeScore =
        (slopeBefore - slopeAfter).abs() / max(0.01, slopeBefore.abs());
    final peakPptRatio = peakForce / max(0.01, pptValue);
    final qualityScore = _qualityScore(
      clean.length,
      duration,
      riseRate,
      peakForce,
      pptValue,
      rawForce,
      smoothForce,
      pptIndex,
    );

    return CurveAnalysisResult(
      valid: qualityScore >= 50,
      invalidReason: qualityScore >= 50 ? '' : '曲线质量较低，请重新测量',
      algorithmVersion: algorithmVersion,
      pptIndex: pptIndex,
      pptValue: pptValue,
      pptTimeSec: pptSec,
      pptTemperature: clean[pptIndex].temperature,
      peakForce: peakForce,
      contactStartSec: contactSec,
      riseRate: riseRate,
      slopeChangeScore: slopeChangeScore,
      peakPptRatio: peakPptRatio,
      qualityScore: qualityScore,
    );
  }

  static List<double> _movingAverage(List<double> values, int window) {
    if (values.isEmpty || window <= 1) return List<double>.from(values);
    final radius = window ~/ 2;
    return List<double>.generate(values.length, (i) {
      var sum = 0.0;
      var count = 0;
      for (int j = i - radius; j <= i + radius; j++) {
        if (j >= 0 && j < values.length) {
          sum += values[j];
          count++;
        }
      }
      return sum / count;
    });
  }

  static double _meanSlope(
    List<double> x,
    List<double> y,
    double start,
    double end,
  ) {
    final slopes = <double>[];
    for (int i = 1; i < x.length; i++) {
      if (x[i] < start || x[i] > end) continue;
      final dx = x[i] - x[i - 1];
      if (dx <= 0) continue;
      slopes.add((y[i] - y[i - 1]) / dx);
    }
    if (slopes.isEmpty) return 0;
    return slopes.reduce((a, b) => a + b) / slopes.length;
  }

  static double _qualityScore(
    int count,
    double duration,
    double riseRate,
    double peakForce,
    double pptValue,
    List<double> rawForce,
    List<double> smoothForce,
    int pptIndex,
  ) {
    var score = 100.0;

    if (count < 15) score -= 20;
    if (duration < 2.0) score -= 15;
    if (riseRate < 0.2) score -= 12;
    if (riseRate > 80) score -= 15;
    if (peakForce < 5.0) score -= 10;
    if (pptIndex < rawForce.length * 0.25) score -= 10;

    var residual = 0.0;
    for (int i = 0; i < rawForce.length; i++) {
      residual += (rawForce[i] - smoothForce[i]).abs();
    }
    residual /= rawForce.length;
    if (residual > max(1.0, pptValue * 0.08)) score -= 15;

    return score.clamp(0.0, 100.0).toDouble();
  }
}
