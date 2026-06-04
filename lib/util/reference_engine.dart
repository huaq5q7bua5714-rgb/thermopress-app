import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:poct_app/data/measurement_models.dart';
import 'package:poct_app/util/acupoint_catalog.dart';

class ReferenceEngine {
  static Map<String, dynamic>? _cache;

  static Future<ReferenceResult> evaluate({
    required BodyRegion bodyRegion,
    required double pptForce,
    required double probeAreaCm2,
    String acupointName = '',
  }) async {
    final safeArea = probeAreaCm2 <= 0 ? 1.0 : probeAreaCm2;
    final pptPressure = pptForce / safeArea;
    final acupoint = await AcupointCatalog.resolve(acupointName);
    final referenceRegionId =
        acupoint?.referenceRegion.trim().isNotEmpty == true
            ? acupoint!.referenceRegion
            : BodyRegions.id(bodyRegion);

    final data = await _loadReferenceJson();
    final refs = (data['references'] as List? ?? const []);
    Map<String, dynamic>? entry;
    for (final item in refs) {
      final map = Map<String, dynamic>.from(item as Map);
      if (map['region'] == referenceRegionId) {
        entry = map;
        break;
      }
    }

    if (entry == null) {
      return ReferenceResult.unavailable(
        pptPressure: pptPressure,
        note: '该身体区域暂无参考百分位库',
      );
    }

    final knots = <double, double>{
      5: _num(entry['p5']),
      10: _num(entry['p10']),
      25: _num(entry['p25']),
      50: _num(entry['p50']),
      75: _num(entry['p75']),
      90: _num(entry['p90']),
      95: _num(entry['p95']),
    };

    final percentile = _interpolatePercentile(pptPressure, knots);
    final acupointNote = acupoint == null
        ? ''
        : '${acupoint.name}${acupoint.code.isEmpty ? '' : ' ${acupoint.code}'}'
            '（${acupoint.meridian}）当前采用${BodyRegions.label(BodyRegions.fromId(referenceRegionId))}区域参考库。';
    final noteParts = [
      if (acupointNote.isNotEmpty) acupointNote,
      '${entry['note'] ?? ''}',
    ].where((text) => text.trim().isNotEmpty).toList();

    return ReferenceResult(
      hasReference: true,
      status: 'ok',
      source: '${entry['source'] ?? ''}',
      quality: '${entry['quality'] ?? 'limited'}',
      note: noteParts.join(' '),
      pptPressure: pptPressure,
      percentile: percentile,
      referenceMode: acupoint == null
          ? 'region_reference'
          : acupoint.referenceMode.isEmpty
              ? 'region_fallback'
              : acupoint.referenceMode,
      matchedAcupointName: acupoint?.name ?? '',
      matchedAcupointCode: acupoint?.code ?? '',
      matchedAcupointMeridian: acupoint?.meridian ?? '',
    );
  }

  static Future<Map<String, dynamic>> _loadReferenceJson() async {
    if (_cache != null) return _cache!;
    final text =
        await rootBundle.loadString('assets/reference/ppt_reference.json');
    _cache = Map<String, dynamic>.from(jsonDecode(text) as Map);
    return _cache!;
  }

  static double _num(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0.0;
  }

  static double _interpolatePercentile(
    double value,
    Map<double, double> knots,
  ) {
    final ordered = knots.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (ordered.isEmpty) return 0;
    if (value <= ordered.first.value) {
      final base = ordered.first.value <= 0 ? 1.0 : ordered.first.value;
      return max(1.0, ordered.first.key * value / base);
    }

    for (int i = 1; i < ordered.length; i++) {
      final prev = ordered[i - 1];
      final next = ordered[i];
      if (value <= next.value) {
        final dy = next.value - prev.value;
        if (dy.abs() < 1e-9) return next.key;
        final ratio = (value - prev.value) / dy;
        return prev.key + ratio * (next.key - prev.key);
      }
    }

    final last = ordered.last;
    final tail = last.value <= 0 ? 1.0 : last.value;
    return min(99.0, last.key + ((value - last.value) / tail) * 5.0);
  }
}

class SensitizationEngine {
  static SensitizationResult evaluate({
    required CurveAnalysisResult curve,
    required ReferenceResult reference,
  }) {
    if (!curve.valid) {
      return SensitizationResult(
        level: 'invalid_curve',
        title: '曲线无效',
        suggestion:
            curve.invalidReason.isEmpty ? '请重新测量。' : curve.invalidReason,
      );
    }

    if (!reference.hasReference) {
      return const SensitizationResult(
        level: 'no_reference',
        title: '缺少参考库',
        suggestion: '本次已提取PPT，可用于同一患者后续纵向比较。',
      );
    }

    final p = reference.percentile;
    if (p < 5) {
      return const SensitizationResult(
        level: 'marked_low',
        title: '高度敏化倾向',
        suggestion: 'PPT低于参考人群第5百分位，提示该测点敏化程度较高，建议结合症状与相邻测点复核。',
      );
    }
    if (p < 10) {
      return const SensitizationResult(
        level: 'low',
        title: '中度敏化倾向',
        suggestion: 'PPT低于参考人群第10百分位，提示存在一定敏化倾向，建议复测或与相邻区域比较。',
      );
    }
    if (p < 25) {
      return const SensitizationResult(
        level: 'mild_low',
        title: '轻度敏化倾向',
        suggestion: 'PPT处于偏低区间，提示轻度敏化倾向，建议结合患者主诉与历史趋势观察。',
      );
    }
    if (p <= 75) {
      return const SensitizationResult(
        level: 'reference_range',
        title: '无明显敏化倾向',
        suggestion: '本次PPT位于参考人群中间区间，未见明显敏化倾向。',
      );
    }
    return const SensitizationResult(
      level: 'high',
      title: '无明显敏化倾向',
      suggestion: '本次PPT高于多数参考人群，未见明显机械痛敏化倾向，建议主要关注后续趋势变化。',
    );
  }
}
