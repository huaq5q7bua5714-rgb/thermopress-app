import 'package:flutter_test/flutter_test.dart';
import 'package:poct_app/data/measurement_models.dart';
import 'package:poct_app/pages/home/patient_controller.dart';
import 'package:poct_app/util/acupoint_catalog.dart';
import 'package:poct_app/util/ml_risk_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Sensitization labels use clinical tendency wording', () {
    expect(SensitizationLevels.label('reference_range'), '无明显敏化倾向');
    expect(SensitizationLevels.label('high'), '无明显敏化倾向');
    expect(SensitizationLevels.label('marked_low'), '高度敏化倾向');
    expect(SensitizationLevels.label('low'), '中度敏化倾向');
    expect(SensitizationLevels.label('mild_low'), '轻度敏化倾向');
  });

  test('AcupointCatalog resolves common names and codes', () async {
    final byName = await AcupointCatalog.resolve('足三里');
    final byCode = await AcupointCatalog.resolve('ST36');

    expect(byName?.name, '足三里');
    expect(byName?.code, 'ST36');
    expect(byName?.meridian, '足阳明胃经');
    expect(byCode?.name, byName?.name);
  });

  test('MlRiskEngine returns a bounded risk score for valid curves', () {
    final curve = CurveAnalysisResult(
      valid: true,
      invalidReason: '',
      algorithmVersion: 'test',
      pptIndex: 10,
      pptValue: 18,
      pptTimeSec: 2.4,
      pptTemperature: 34.2,
      peakForce: 18,
      contactStartSec: 0.4,
      riseRate: 9,
      slopeChangeScore: 0.4,
      peakPptRatio: 1,
      qualityScore: 86,
    );
    const reference = ReferenceResult(
      hasReference: true,
      status: 'ok',
      source: 'test',
      quality: 'test',
      note: '',
      pptPressure: 10.2,
      percentile: 8,
    );
    final patient = Patient(
      name: 'test',
      age: 60,
      weight: 65,
      phone: '10086',
    );
    final session = MeasurementSessionDraft(
      sessionId: 'S1',
      startTime: DateTime(2026, 1, 1),
      bodyRegion: BodyRegion.lumbosacral,
      symptomType: SymptomType.lowBack,
      algorithmVersion: 'test',
    );

    final result = MlRiskEngine.evaluate(
      curve: curve,
      reference: reference,
      patient: patient,
      session: session,
      avgTemp: 34.0,
      maxTemp: 34.6,
      minTemp: 33.8,
      history: const [],
    );

    expect(result.modelVersion, MlRiskEngine.modelVersion);
    expect(result.riskScore, inInclusiveRange(0, 1));
    expect(result.confidence, inInclusiveRange(0, 1));
    expect(result.riskLevel, isNot('unavailable'));
    expect(result.reasonText, '模型结果与PPT参考分层一致，未发现额外异常信号。');
  });

  test('MlRiskEngine treats temperature range as a weak auxiliary feature', () {
    final curve = CurveAnalysisResult(
      valid: true,
      invalidReason: '',
      algorithmVersion: 'test',
      pptIndex: 10,
      pptValue: 42,
      pptTimeSec: 2.4,
      pptTemperature: 34.2,
      peakForce: 42,
      contactStartSec: 0.4,
      riseRate: 30,
      slopeChangeScore: 0.2,
      peakPptRatio: 1,
      qualityScore: 80,
    );
    const reference = ReferenceResult(
      hasReference: true,
      status: 'ok',
      source: 'test',
      quality: 'test',
      note: '',
      pptPressure: 24,
      percentile: 35,
    );
    final patient = Patient(
      name: 'test',
      age: 35,
      weight: 65,
      phone: '10086',
    );
    final session = MeasurementSessionDraft(
      sessionId: 'S1',
      startTime: DateTime(2026, 1, 1),
      bodyRegion: BodyRegion.upperLimb,
      symptomType: SymptomType.other,
      algorithmVersion: 'test',
    );

    final stableTemp = MlRiskEngine.evaluate(
      curve: curve,
      reference: reference,
      patient: patient,
      session: session,
      avgTemp: 34.0,
      maxTemp: 34.1,
      minTemp: 34.0,
      history: const [],
    );
    final shakyTemp = MlRiskEngine.evaluate(
      curve: curve,
      reference: reference,
      patient: patient,
      session: session,
      avgTemp: 34.0,
      maxTemp: 36.5,
      minTemp: 33.0,
      history: const [],
    );

    expect(shakyTemp.riskScore - stableTemp.riskScore, lessThan(0.04));
    expect(stableTemp.reasonText, contains('未提示额外敏化风险'));
    expect(stableTemp.reasonText, isNot(contains('参考百分位')));
    expect(stableTemp.reasonText, isNot(contains('曲线质量')));
  });

  test('MlRiskEngine skips invalid curves', () {
    final patient = Patient(
      name: 'test',
      age: 30,
      weight: 60,
      phone: '10086',
    );
    final session = MeasurementSessionDraft(
      sessionId: 'S1',
      startTime: DateTime(2026, 1, 1),
      bodyRegion: BodyRegion.knee,
      symptomType: SymptomType.kneeJoint,
      algorithmVersion: 'test',
    );

    final result = MlRiskEngine.evaluate(
      curve: CurveAnalysisResult.invalid('曲线无效'),
      reference: ReferenceResult.unavailable(),
      patient: patient,
      session: session,
      avgTemp: 0,
      maxTemp: 0,
      minTemp: 0,
      history: const [],
    );

    expect(result.riskLevel, 'unavailable');
    expect(result.riskScore, 0);
  });
}
