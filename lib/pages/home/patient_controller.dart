import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:poct_app/data/measurement_models.dart';
import 'dart:io';

/// 病人模型
class Patient {
  final String name;
  final int age;
  final double weight;
  final String phone;

  Patient({
    required this.name,
    required this.age,
    required this.weight,
    required this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'weight': weight,
      'phone': phone,
    };
  }

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      name: json['name'] as String,
      age: json['age'] as int,
      weight: (json['weight'] as num).toDouble(),
      phone: json['phone'] as String,
    );
  }
}

/// 单次测量摘要（用于在 Patient Detail 中展示“最近一次测量”）
class MeasurementSummary {
  final String sessionId;
  final DateTime startTime;
  final DateTime endTime;
  final int count;
  final String bodyRegion;
  final String symptomType;
  final String acupointName;
  final String acupointCode;
  final String acupointMeridian;
  final String algorithmVersion;
  final double probeAreaCm2;

  // Force
  final double maxForce;
  final double minForce;
  final double avgForce;

  //Temp
  final double maxTemp;
  final double minTemp;
  final double avgTemp;
  final String filePath;
  final double pptValue;
  final double pptPressure;
  final double pptTimeSec;
  final double pptTemp;
  final double peakForce;
  final double riseRate;
  final double slopeChangeScore;
  final double peakPptRatio;
  final double curveQualityScore;
  final bool curveValid;
  final String curveInvalidReason;
  final double referencePercentile;
  final String referenceStatus;
  final String referenceSource;
  final String referenceQuality;
  final String referenceMode;
  final String referenceNote;
  final String sensitizationLevel;
  final String suggestionText;
  final double mlRiskScore;
  final String mlRiskLevel;
  final double mlConfidence;
  final String mlModelVersion;
  final String mlReasonText;
  final double mlTemperatureRange;
  final double mlTrendDelta;

  MeasurementSummary({
    this.sessionId = '',
    required this.startTime,
    required this.endTime,
    required this.count,
    this.bodyRegion = 'lumbosacral',
    this.symptomType = 'skipped',
    this.acupointName = '',
    this.acupointCode = '',
    this.acupointMeridian = '',
    this.algorithmVersion = '',
    this.probeAreaCm2 = 1.0,
    required this.maxForce,
    required this.minForce,
    required this.avgForce,
    required this.maxTemp,
    required this.minTemp,
    required this.avgTemp,
    required this.filePath,
    this.pptValue = 0,
    this.pptPressure = 0,
    this.pptTimeSec = 0,
    this.pptTemp = 0,
    this.peakForce = 0,
    this.riseRate = 0,
    this.slopeChangeScore = 0,
    this.peakPptRatio = 0,
    this.curveQualityScore = 0,
    this.curveValid = false,
    this.curveInvalidReason = '',
    this.referencePercentile = 0,
    this.referenceStatus = 'unavailable',
    this.referenceSource = '',
    this.referenceQuality = '',
    this.referenceMode = '',
    this.referenceNote = '',
    this.sensitizationLevel = '',
    this.suggestionText = '',
    this.mlRiskScore = 0,
    this.mlRiskLevel = 'unavailable',
    this.mlConfidence = 0,
    this.mlModelVersion = '',
    this.mlReasonText = '',
    this.mlTemperatureRange = 0,
    this.mlTrendDelta = 0,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'startTime': startTime.millisecondsSinceEpoch,
        'endTime': endTime.millisecondsSinceEpoch,
        'count': count,
        'bodyRegion': bodyRegion,
        'symptomType': symptomType,
        'acupointName': acupointName,
        'acupointCode': acupointCode,
        'acupointMeridian': acupointMeridian,
        'algorithmVersion': algorithmVersion,
        'probeAreaCm2': probeAreaCm2,
        'maxForce': maxForce,
        'minForce': minForce,
        'avgForce': avgForce,
        'maxTemp': maxTemp,
        'minTemp': minTemp,
        'avgTemp': avgTemp,
        'filePath': filePath,
        'pptValue': pptValue,
        'pptPressure': pptPressure,
        'pptTimeSec': pptTimeSec,
        'pptTemp': pptTemp,
        'peakForce': peakForce,
        'riseRate': riseRate,
        'slopeChangeScore': slopeChangeScore,
        'peakPptRatio': peakPptRatio,
        'curveQualityScore': curveQualityScore,
        'curveValid': curveValid,
        'curveInvalidReason': curveInvalidReason,
        'referencePercentile': referencePercentile,
        'referenceStatus': referenceStatus,
        'referenceSource': referenceSource,
        'referenceQuality': referenceQuality,
        'referenceMode': referenceMode,
        'referenceNote': referenceNote,
        'sensitizationLevel': sensitizationLevel,
        'suggestionText': suggestionText,
        'mlRiskScore': mlRiskScore,
        'mlRiskLevel': mlRiskLevel,
        'mlConfidence': mlConfidence,
        'mlModelVersion': mlModelVersion,
        'mlReasonText': mlReasonText,
        'mlTemperatureRange': mlTemperatureRange,
        'mlTrendDelta': mlTrendDelta,
      };

  factory MeasurementSummary.fromJson(Map<String, dynamic> json) {
    double _num(dynamic v) => (v is num) ? v.toDouble() : 0.0;
    String _str(dynamic v, [String fallback = '']) =>
        v == null ? fallback : '$v';
    bool _bool(dynamic v) => v is bool ? v : '$v' == 'true';

    DateTime _dt(dynamic v) {
      // ✅ 兼容：int(毫秒) / num / String(ISO)
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
      if (v is String)
        return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return MeasurementSummary(
      sessionId: _str(json['sessionId']),
      startTime: _dt(json['startTime']),
      endTime: _dt(json['endTime']),
      count: (json['count'] is int)
          ? json['count'] as int
          : int.tryParse('${json['count']}') ?? 0,
      bodyRegion: _str(json['bodyRegion'], 'lumbosacral'),
      symptomType: _str(json['symptomType'], 'skipped'),
      acupointName: _str(json['acupointName']),
      acupointCode: _str(json['acupointCode']),
      acupointMeridian: _str(json['acupointMeridian']),
      algorithmVersion: _str(json['algorithmVersion']),
      probeAreaCm2:
          _num(json['probeAreaCm2']) == 0 ? 1.0 : _num(json['probeAreaCm2']),
      maxForce: _num(json['maxForce']),
      minForce: _num(json['minForce']),
      avgForce: _num(json['avgForce']),
      maxTemp: _num(json['maxTemp']),
      minTemp: _num(json['minTemp']),
      avgTemp: _num(json['avgTemp']),
      filePath: _str(json['filePath']),
      pptValue: _num(json['pptValue']),
      pptPressure: _num(json['pptPressure']),
      pptTimeSec: _num(json['pptTimeSec']),
      pptTemp: _num(json['pptTemp']),
      peakForce: _num(json['peakForce']),
      riseRate: _num(json['riseRate']),
      slopeChangeScore: _num(json['slopeChangeScore']),
      peakPptRatio: _num(json['peakPptRatio']),
      curveQualityScore: _num(json['curveQualityScore']),
      curveValid: _bool(json['curveValid']),
      curveInvalidReason: _str(json['curveInvalidReason']),
      referencePercentile: _num(json['referencePercentile']),
      referenceStatus: _str(json['referenceStatus'], 'unavailable'),
      referenceSource: _str(json['referenceSource']),
      referenceQuality: _str(json['referenceQuality']),
      referenceMode: _str(json['referenceMode']),
      referenceNote: _str(json['referenceNote']),
      sensitizationLevel: _str(json['sensitizationLevel']),
      suggestionText: _str(json['suggestionText']),
      mlRiskScore: _num(json['mlRiskScore']),
      mlRiskLevel: _str(json['mlRiskLevel'], 'unavailable'),
      mlConfidence: _num(json['mlConfidence']),
      mlModelVersion: _str(json['mlModelVersion']),
      mlReasonText: _str(json['mlReasonText']),
      mlTemperatureRange: _num(json['mlTemperatureRange']),
      mlTrendDelta: _num(json['mlTrendDelta']),
    );
  }

  bool get hasPpt => pptValue > 0;

  bool get hasSmartAssessment =>
      hasPpt && curveValid && sensitizationLevel.trim().isNotEmpty;

  String get bodyRegionLabel =>
      BodyRegions.label(BodyRegions.fromId(bodyRegion));

  String get symptomTypeLabel =>
      SymptomTypes.label(SymptomTypes.fromId(symptomType));

  String get siteLabel {
    final acupoint = acupointName.trim();
    if (acupoint.isEmpty) return bodyRegionLabel;
    final code = acupointCode.trim();
    final point = code.isEmpty ? acupoint : '$acupoint $code';
    return '$bodyRegionLabel · $point';
  }

  String get referenceModeLabel {
    switch (referenceMode) {
      case 'region_reference':
        return '区域参考库';
      case 'region_fallback':
        return '穴位映射 + 区域参考库';
      case 'direct_acupoint_reference':
        return '穴位专属参考库';
      default:
        return referenceStatus == 'ok' ? '区域参考库' : '暂无参考';
    }
  }

  String get sensitizationLabel =>
      SensitizationLevels.label(sensitizationLevel);

  bool get hasMlRisk => mlModelVersion.trim().isNotEmpty;

  String get mlRiskLabel => MlRiskLevels.label(mlRiskLevel);

  bool same_as(MeasurementSummary other) {
    if (sessionId.isNotEmpty && other.sessionId.isNotEmpty) {
      return sessionId == other.sessionId;
    }
    return startTime.millisecondsSinceEpoch ==
            other.startTime.millisecondsSinceEpoch &&
        endTime.millisecondsSinceEpoch ==
            other.endTime.millisecondsSinceEpoch &&
        count == other.count &&
        filePath == other.filePath;
  }
}

/// 按 “账号” 隔离的 PatientController
class PatientController extends GetxController {
  /// 当前登录账号名，例如 "zzh" / "hcgu"
  final String username;

  PatientController(this.username);

  final GetStorage _box = GetStorage();

  /// key: patients_zzh / patients_admin ...
  String get _patientsKey => 'patients_$username';

  /// 当前账号上一次选中的病人 phone
  String get _currentPatientKey => 'current_patient_$username';

  /// 病人列表
  final RxList<Patient> patients = <Patient>[].obs;

  /// 当前选中的病人
  final Rxn<Patient> currentPatient = Rxn<Patient>();

  /// 最近一次测量摘要（key: patient phone）
  final RxMap<String, MeasurementSummary> lastSummaryByPhone =
      <String, MeasurementSummary>{}.obs;

  String get _lastMeasurementsKey => 'last_measurements_$username';

  /// 搜索关键字（WorkspacePage 用）
  final RxString searchQuery = ''.obs;

  /// ✅【新增】完整历史记录（key: phone -> list of MeasurementSummary）
  final RxMap<String, List<MeasurementSummary>> historyByPhone =
      <String, List<MeasurementSummary>>{}.obs;

  String get _historyKey => 'measurement_history_$username';

  /// 返回过滤后的患者列表（只在当前账号 patients 内过滤）
  List<Patient> get filteredPatients {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return patients;

    return patients.where((p) {
      final name = p.name.toLowerCase();
      final phone = p.phone.toLowerCase();
      return name.contains(q) || phone.contains(q);
    }).toList();
  }

  void setSearchQuery(String v) {
    searchQuery.value = v.trim();
  }

  void clearSearch() {
    searchQuery.value = '';
  }

  @override
  void onInit() {
    super.onInit();
    _loadPatientsFromStorage();
    _loadLastMeasurementsFromStorage();
    _loadHistoryFromStorage();
  }

  /// 从本地加载当前账号的病人列表
  void _loadPatientsFromStorage() {
    final storedList = _box.read<List>(_patientsKey);

    if (storedList != null && storedList.isNotEmpty) {
      final loaded = storedList
          .map((e) => Patient.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      patients.assignAll(loaded);

      // ================== ✅ 核心修复点 ==================
      // 1️⃣ 读取上次选中的病人 phone（按账号）
      final savedPhone = _box.read<String>(_currentPatientKey);

      if (savedPhone != null) {
        // 2️⃣ 尝试在 patients 里找到这个病人
        final matched = patients.firstWhereOrNull(
          (p) => p.phone == savedPhone,
        );

        if (matched != null) {
          currentPatient.value = matched;
          return;
        }
      }

      // 3️⃣ 如果没存过 / 找不到，就兜底选第一个
      currentPatient.value = patients.first;
      // ==================================================
    } else {
      patients.clear();
      currentPatient.value = null;
    }
  }

  /// 从本地加载“最近一次测量摘要”
  void _loadLastMeasurementsFromStorage() {
    final stored = _box.read<Map>(_lastMeasurementsKey);
    if (stored == null) {
      lastSummaryByPhone.clear();
      return;
    }

    final map = <String, MeasurementSummary>{};
    stored.forEach((key, value) {
      try {
        map[key.toString()] =
            MeasurementSummary.fromJson(Map<String, dynamic>.from(value));
      } catch (e) {
        Get.log('❌ load last measurement failed: key=$key, err=$e');
      }
    });

    lastSummaryByPhone.assignAll(map);
  }

  void _saveLastMeasurementsToStorage() {
    final out = <String, dynamic>{};
    lastSummaryByPhone.forEach((k, v) {
      out[k] = v.toJson();
    });
    _box.write(_lastMeasurementsKey, out);
  }

  /// ✅【新增】加载完整历史
  void _loadHistoryFromStorage() {
    final stored = _box.read<Map>(_historyKey);
    if (stored == null) {
      historyByPhone.clear();
      return;
    }

    final map = <String, List<MeasurementSummary>>{};
    stored.forEach((key, value) {
      try {
        final list = (value as List)
            .map((e) =>
                MeasurementSummary.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        // 按时间排序（老 -> 新）
        list.sort((a, b) => a.endTime.compareTo(b.endTime));
        map[key.toString()] = list;
      } catch (e) {
        Get.log('❌ load history failed: phone=$key, err=$e');
      }
    });

    historyByPhone.assignAll(map);

    // ✅（可选）顺手用 history 更新 lastSummaryByPhone（避免两份状态不一致）
    lastSummaryByPhone.clear();
    historyByPhone.forEach((phone, list) {
      if (list.isNotEmpty) {
        lastSummaryByPhone[phone] = list.last;
      }
    });
  }

  /// ✅【新增】保存完整历史
  void _saveHistoryToStorage() {
    final out = <String, dynamic>{};
    historyByPhone.forEach((phone, list) {
      out[phone] = list.map((e) => e.toJson()).toList();
    });
    _box.write(_historyKey, out);
  }

  /// ✅【新增】追加一条历史记录（并同步更新 latest）
  void addMeasurementRecord(String phone, MeasurementSummary summary) {
    final list = historyByPhone[phone] ?? <MeasurementSummary>[];
    list.add(summary);
    list.sort((a, b) => a.endTime.compareTo(b.endTime));
    historyByPhone[phone] = list;

    // 同步“最近一次”
    lastSummaryByPhone[phone] = list.last;

    _saveHistoryToStorage();
    _saveLastMeasurementsToStorage();
  }

  Future<void> delete_measurement_record(
      String phone, MeasurementSummary summary) async {
    // 1) 删 CSV（有些测量失败没有 CSV，要判断；并且删文件不影响删记录）
    final path = summary.filePath.trim();
    if (path.isNotEmpty) {
      try {
        final f = File(path);
        if (await f.exists()) {
          await f.delete();
        }
      } catch (_) {
        // 不要 throw，避免删除按钮导致 UI 红屏
      }
    }

    // 2) 删 history 记录
    final list = historyByPhone[phone];
    if (list == null || list.isEmpty) {
      return;
    }

    // removeWhere 返回 void，我们自己判断是否删到了
    final before = list.length;
    list.removeWhere((x) => x.same_as(summary)); // ✅ 需要你上面加的 same_as
    final after = list.length;

    if (after == before) {
      // 兜底：如果 same_as 没匹配到，尝试更宽松的规则（防止老数据没 filePath）
      list.removeWhere((x) =>
          x.startTime.millisecondsSinceEpoch ==
              summary.startTime.millisecondsSinceEpoch &&
          x.endTime.millisecondsSinceEpoch ==
              summary.endTime.millisecondsSinceEpoch &&
          x.count == summary.count);
    }

    // 3) 如果删完为空：清理 map 里的 key，避免存一堆空列表
    if (list.isEmpty) {
      historyByPhone.remove(phone);
      lastSummaryByPhone.remove(phone);
    } else {
      // 保持 “老->新” 的内部排序
      list.sort((a, b) => a.endTime.compareTo(b.endTime));
      historyByPhone[phone] = list;

      // 同步最新
      lastSummaryByPhone[phone] = list.last;
    }

    // 4) 持久化
    _saveHistoryToStorage();
    _saveLastMeasurementsToStorage();

    // 5) 通知 UI 刷新（RxMap 一般会自动触发，但保险起见 refresh）
    historyByPhone.refresh();
    lastSummaryByPhone.refresh();
  }

  /// ✅【新增】获取某个患者全部历史（默认按新->旧返回，便于 UI）
  List<MeasurementSummary> getHistoryForPatient(String phone) {
    final list = historyByPhone[phone] ?? <MeasurementSummary>[];
    final copy = List<MeasurementSummary>.from(list);
    copy.sort((a, b) => b.endTime.compareTo(a.endTime)); // 新->旧
    return copy;
  }

  /// 把当前账号的病人列表保存到本地
  void _savePatientsToStorage() {
    final list = patients.map((p) => p.toJson()).toList();
    _box.write(_patientsKey, list);
  }

  /// 新增病人（仅当前账号）
  void addPatient(Patient patient) {
    patients.add(patient);
    currentPatient.value = patient;
    _box.write(_currentPatientKey, patient.phone);
    _savePatientsToStorage();
  }

  /// 选择病人
  void selectPatient(Patient patient) {
    currentPatient.value = patient;
    // ✅ 记住这个账号当前选中的病人（用 phone 作为唯一标识）
    _box.write(_currentPatientKey, patient.phone);
  }

  /// 删除病人
  void deletePatient(Patient patient) {
    final wasCurrent = currentPatient.value?.phone == patient.phone;
    patients.remove(patient);
    if (wasCurrent) {
      if (patients.isNotEmpty) {
        currentPatient.value = patients.first;
        _box.write(_currentPatientKey, patients.first.phone); // ✅ 更新
      } else {
        currentPatient.value = null;
        _box.remove(_currentPatientKey); // ✅ 清理
      }
    }
    _savePatientsToStorage();
  }

  /// 删除当前账号下的所有病人
  void deleteAllPatients() {
    patients.clear();
    currentPatient.value = null;
    _box.remove(_currentPatientKey);
    _savePatientsToStorage();
  }

  /// 保存某个患者的“最近一次测量摘要”
  void saveLastSummaryForPatient(String phone, MeasurementSummary summary) {
    addMeasurementRecord(phone, summary);
  }

  MeasurementSummary? getLastSummaryForPatient(String phone) {
    return lastSummaryByPhone[phone];
  }
}
