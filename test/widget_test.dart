import 'package:flutter_test/flutter_test.dart';
import 'package:poct_app/data/measurement_models.dart';
import 'package:poct_app/pages/home/patient_controller.dart';
import 'package:poct_app/util/ml_risk_engine.dart';

void main() {
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
