class MeasurementPoint {
  final DateTime time;
  final double temperature;
  final double force;

  const MeasurementPoint({
    required this.time,
    required this.temperature,
    required this.force,
  });
}

enum BodyRegion {
  headFace,
  neckShoulder,
  thoracicBack,
  lumbosacral,
  abdomen,
  upperLimb,
  knee,
  lowerLimbDistal,
}

class BodyRegions {
  static String id(BodyRegion region) {
    switch (region) {
      case BodyRegion.headFace:
        return 'head_face';
      case BodyRegion.neckShoulder:
        return 'neck_shoulder';
      case BodyRegion.thoracicBack:
        return 'thoracic_back';
      case BodyRegion.lumbosacral:
        return 'lumbosacral';
      case BodyRegion.abdomen:
        return 'abdomen';
      case BodyRegion.upperLimb:
        return 'upper_limb';
      case BodyRegion.knee:
        return 'knee';
      case BodyRegion.lowerLimbDistal:
        return 'lower_limb_distal';
    }
  }

  static String label(BodyRegion region) {
    switch (region) {
      case BodyRegion.headFace:
        return '头面部';
      case BodyRegion.neckShoulder:
        return '颈肩部';
      case BodyRegion.thoracicBack:
        return '胸背部';
      case BodyRegion.lumbosacral:
        return '腰骶部';
      case BodyRegion.abdomen:
        return '腹部';
      case BodyRegion.upperLimb:
        return '上肢';
      case BodyRegion.knee:
        return '膝关节周围';
      case BodyRegion.lowerLimbDistal:
        return '下肢远端';
    }
  }

  static BodyRegion fromId(String? id) {
    for (final region in BodyRegion.values) {
      if (BodyRegions.id(region) == id) return region;
    }
    return BodyRegion.lumbosacral;
  }
}

enum SymptomType {
  skipped,
  gastrointestinal,
  kneeJoint,
  lowBack,
  dysmenorrhea,
  other,
}

class SymptomTypes {
  static String id(SymptomType symptom) {
    switch (symptom) {
      case SymptomType.skipped:
        return 'skipped';
      case SymptomType.gastrointestinal:
        return 'gastrointestinal';
      case SymptomType.kneeJoint:
        return 'knee_joint';
      case SymptomType.lowBack:
        return 'low_back';
      case SymptomType.dysmenorrhea:
        return 'dysmenorrhea';
      case SymptomType.other:
        return 'other';
    }
  }

  static String label(SymptomType symptom) {
    switch (symptom) {
      case SymptomType.skipped:
        return '跳过';
      case SymptomType.gastrointestinal:
        return '胃肠';
      case SymptomType.kneeJoint:
        return '膝关节';
      case SymptomType.lowBack:
        return '腰背';
      case SymptomType.dysmenorrhea:
        return '痛经';
      case SymptomType.other:
        return '其他';
    }
  }

  static SymptomType fromId(String? id) {
    for (final symptom in SymptomType.values) {
      if (SymptomTypes.id(symptom) == id) return symptom;
    }
    return SymptomType.skipped;
  }
}

class MeasurementSelection {
  final BodyRegion bodyRegion;
  final SymptomType symptomType;
  final String acupointName;

  const MeasurementSelection({
    required this.bodyRegion,
    required this.symptomType,
    this.acupointName = '',
  });
}

class MeasurementSessionDraft {
  final String sessionId;
  final DateTime startTime;
  final BodyRegion bodyRegion;
  final SymptomType symptomType;
  final String acupointName;
  final String algorithmVersion;

  const MeasurementSessionDraft({
    required this.sessionId,
    required this.startTime,
    required this.bodyRegion,
    required this.symptomType,
    required this.algorithmVersion,
    this.acupointName = '',
  });
}

class CurveAnalysisResult {
  final bool valid;
  final String invalidReason;
  final String algorithmVersion;
  final int pptIndex;
  final double pptValue;
  final double pptTimeSec;
  final double pptTemperature;
  final double peakForce;
  final double contactStartSec;
  final double riseRate;
  final double slopeChangeScore;
  final double peakPptRatio;
  final double qualityScore;

  const CurveAnalysisResult({
    required this.valid,
    required this.invalidReason,
    required this.algorithmVersion,
    required this.pptIndex,
    required this.pptValue,
    required this.pptTimeSec,
    required this.pptTemperature,
    required this.peakForce,
    required this.contactStartSec,
    required this.riseRate,
    required this.slopeChangeScore,
    required this.peakPptRatio,
    required this.qualityScore,
  });

  factory CurveAnalysisResult.invalid(
    String reason, {
    String algorithmVersion = 'ppt_v2_press_peak',
  }) {
    return CurveAnalysisResult(
      valid: false,
      invalidReason: reason,
      algorithmVersion: algorithmVersion,
      pptIndex: -1,
      pptValue: 0,
      pptTimeSec: 0,
      pptTemperature: 0,
      peakForce: 0,
      contactStartSec: 0,
      riseRate: 0,
      slopeChangeScore: 0,
      peakPptRatio: 0,
      qualityScore: 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'valid': valid,
        'invalidReason': invalidReason,
        'algorithmVersion': algorithmVersion,
        'pptIndex': pptIndex,
        'pptValue': pptValue,
        'pptTimeSec': pptTimeSec,
        'pptTemperature': pptTemperature,
        'peakForce': peakForce,
        'contactStartSec': contactStartSec,
        'riseRate': riseRate,
        'slopeChangeScore': slopeChangeScore,
        'peakPptRatio': peakPptRatio,
        'qualityScore': qualityScore,
      };
}

class ReferenceResult {
  final bool hasReference;
  final String status;
  final String source;
  final String quality;
  final String note;
  final double pptPressure;
  final double percentile;
  final String referenceMode;
  final String matchedAcupointName;
  final String matchedAcupointCode;
  final String matchedAcupointMeridian;

  const ReferenceResult({
    required this.hasReference,
    required this.status,
    required this.source,
    required this.quality,
    required this.note,
    required this.pptPressure,
    required this.percentile,
    this.referenceMode = 'region_reference',
    this.matchedAcupointName = '',
    this.matchedAcupointCode = '',
    this.matchedAcupointMeridian = '',
  });

  factory ReferenceResult.unavailable({
    double pptPressure = 0,
    String note = '暂无该区域参考库',
  }) {
    return ReferenceResult(
      hasReference: false,
      status: 'unavailable',
      source: '',
      quality: 'unavailable',
      note: note,
      pptPressure: pptPressure,
      percentile: 0,
      referenceMode: 'unavailable',
    );
  }
}

class SensitizationResult {
  final String level;
  final String title;
  final String suggestion;

  const SensitizationResult({
    required this.level,
    required this.title,
    required this.suggestion,
  });
}

class MlRiskResult {
  final double riskScore;
  final String riskLevel;
  final double confidence;
  final String modelVersion;
  final String reasonText;
  final double temperatureRange;
  final double trendDelta;

  const MlRiskResult({
    required this.riskScore,
    required this.riskLevel,
    required this.confidence,
    required this.modelVersion,
    required this.reasonText,
    required this.temperatureRange,
    required this.trendDelta,
  });

  factory MlRiskResult.empty({
    String modelVersion = '',
    String reasonText = '',
  }) {
    return MlRiskResult(
      riskScore: 0,
      riskLevel: 'unavailable',
      confidence: 0,
      modelVersion: modelVersion,
      reasonText: reasonText,
      temperatureRange: 0,
      trendDelta: 0,
    );
  }
}

class MlRiskLevels {
  static String label(String level) {
    switch (level) {
      case 'high':
        return '高风险';
      case 'medium':
        return '中风险';
      case 'low':
        return '低风险';
      case 'uncertain':
        return '证据不足';
      case 'unavailable':
        return '暂未评估';
      default:
        return '暂未评估';
    }
  }
}

class SensitizationLevels {
  static String label(String level) {
    switch (level) {
      case 'marked_low':
        return '明显偏低，疑似敏化';
      case 'low':
        return '偏低，可能敏化';
      case 'mild_low':
        return '轻度偏低';
      case 'reference_range':
        return '参考范围';
      case 'high':
        return '阈值较高';
      case 'invalid_curve':
        return '曲线无效';
      case 'no_reference':
        return '缺少参考库';
      default:
        return '未评估';
    }
  }
}
