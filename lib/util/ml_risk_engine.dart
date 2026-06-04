import 'dart:math';

import 'package:poct_app/data/measurement_models.dart';
import 'package:poct_app/pages/home/patient_controller.dart';

class MlRiskEngine {
  static const String modelVersion = 'ThermoPress SensML';

  static MlRiskResult evaluate({
    required CurveAnalysisResult curve,
    required ReferenceResult reference,
    required Patient patient,
    required MeasurementSessionDraft session,
    required double avgTemp,
    required double maxTemp,
    required double minTemp,
    required List<MeasurementSummary> history,
  }) {
    if (!curve.valid || curve.pptValue <= 0) {
      return MlRiskResult.empty(
        modelVersion: modelVersion,
        reasonText: curve.invalidReason.isEmpty
            ? '曲线无效，暂不进行机器学习辅助评估。'
            : curve.invalidReason,
      );
    }

    final targetAcupointName = reference.matchedAcupointName.isNotEmpty
        ? reference.matchedAcupointName
        : session.acupointName;
    final sameSiteHistory = _sameSiteHistory(
      history,
      session,
      targetAcupointName,
    );

    final pptPressure = reference.pptPressure > 0
        ? reference.pptPressure
        : curve.pptValue / 1.767;
    final percentile = reference.hasReference ? reference.percentile : 50.0;
    final tempRange = maxTemp - minTemp;
    final trendDelta = _trendDelta(pptPressure, sameSiteHistory);

    final features = <_Feature>[
      _Feature(
        'PPT偏低',
        _clamp01((45.0 - pptPressure) / 45.0),
        1.05,
      ),
      _Feature(
        '参考百分位偏低',
        _clamp01((25.0 - percentile) / 25.0),
        1.25,
      ),
      _Feature(
        '温度差异',
        _clamp01(tempRange / 2.5),
        0.12,
      ),
      _Feature(
        '曲线质量',
        _clamp01((curve.qualityScore - 50.0) / 50.0),
        0.35,
      ),
      _Feature(
        '施压速率异常',
        _clamp01((curve.riseRate - 30.0).abs() / 60.0),
        0.30,
      ),
      _Feature(
        '历史下降趋势',
        _clamp01((-trendDelta) / 12.0),
        0.55,
      ),
      _Feature(
        '年龄影响',
        _clamp01((patient.age - 55.0) / 35.0),
        0.20,
      ),
    ];

    var logit = -1.15;
    for (final feature in features) {
      logit += feature.value * feature.weight;
    }

    final score = 1.0 / (1.0 + exp(-logit));
    final confidence = _confidence(
      curveQuality: curve.qualityScore,
      hasReference: reference.hasReference,
      sameSiteCount: sameSiteHistory.length,
    );
    final level = _level(score, confidence);
    final reasons = score < 0.45 ? <String>[] : _topReasons(features);

    return MlRiskResult(
      riskScore: score,
      riskLevel: level,
      confidence: confidence,
      modelVersion: modelVersion,
      reasonText: reasons.isEmpty
          ? 'PPT与参考百分位未显示明显敏化风险，建议结合临床主诉和后续趋势观察。'
          : reasons.join('；'),
      temperatureRange: tempRange,
      trendDelta: trendDelta,
    );
  }

  static List<MeasurementSummary> _sameSiteHistory(
    List<MeasurementSummary> history,
    MeasurementSessionDraft session,
    String targetAcupointName,
  ) {
    return history
        .where((item) =>
            item.curveValid &&
            item.pptPressure > 0 &&
            item.bodyRegion == BodyRegions.id(session.bodyRegion) &&
            _sameAcupoint(item.acupointName, targetAcupointName))
        .toList()
      ..sort((a, b) => b.endTime.compareTo(a.endTime));
  }

  static bool _sameAcupoint(String saved, String current) {
    final savedName = saved.trim().toLowerCase();
    final currentName = current.trim().toLowerCase();
    if (savedName.isEmpty || currentName.isEmpty) return true;
    return savedName == currentName;
  }

  static double _trendDelta(
    double current,
    List<MeasurementSummary> sameSiteHistory,
  ) {
    if (sameSiteHistory.isEmpty) return 0.0;
    return current - sameSiteHistory.first.pptPressure;
  }

  static double _confidence({
    required double curveQuality,
    required bool hasReference,
    required int sameSiteCount,
  }) {
    var confidence = 0.40;
    confidence += _clamp01(curveQuality / 100.0) * 0.30;
    if (hasReference) confidence += 0.12;
    if (sameSiteCount > 0) confidence += 0.08;
    return confidence.clamp(0.0, 0.95).toDouble();
  }

  static String _level(double score, double confidence) {
    if (confidence < 0.45) return 'uncertain';
    if (score >= 0.72) return 'high';
    if (score >= 0.45) return 'medium';
    return 'low';
  }

  static List<String> _topReasons(List<_Feature> features) {
    final ranked = features
        .where((feature) =>
            feature.name != '曲线质量' &&
            feature.value >= 0.35 &&
            feature.value * feature.weight >= 0.15)
        .toList()
      ..sort((a, b) => (b.value * b.weight).compareTo(a.value * a.weight));

    return ranked.take(3).map((feature) {
      if (feature.name == 'PPT偏低') return 'PPT标准化压力偏低';
      if (feature.name == '参考百分位偏低') return '参考百分位处于低位';
      if (feature.name == '温度差异') return '测量期间温度波动较明显';
      if (feature.name == '曲线质量') return '曲线质量较高，结果可信度较好';
      if (feature.name == '施压速率异常') return '施压速率存在异常波动';
      if (feature.name == '历史下降趋势') return '同测点历史PPT呈下降趋势';
      return feature.name;
    }).toList();
  }

  static double _clamp01(double value) => value.clamp(0.0, 1.0).toDouble();
}

class _Feature {
  final String name;
  final double value;
  final double weight;

  const _Feature(this.name, this.value, this.weight);
}
