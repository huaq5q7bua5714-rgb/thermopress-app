// lib/pages/home/auth_controller.dart
import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'patient_controller.dart';

class Doctor {
  final String username;
  final String displayName;

  final int centerCode;
  final String centerName;
  final String subCenterNo;

  Doctor({
    required this.username,
    required this.displayName,
    required this.centerCode,
    required this.centerName,
    required this.subCenterNo,
  });
}


/// 管理「医生账号 + 登录状态」的控制器
class AuthController extends GetxController {
  /// 是否已登录
  final RxBool isLoggedIn = false.obs;

  /// 当前登录的医生
  final Rxn<Doctor> currentDoctor = Rxn<Doctor>();

  /// 账号表：username -> password
  Map<String, String> _accounts = {};
  Map<String, Map<String, dynamic>> _profiles = {};
  static const String _keyProfiles = 'auth_doctor_profiles';

  /// 最近一次登录成功的账号
  String? _lastUsername;

  /// 最近一次登录成功的密码（仅 Demo，用于本地自动登录；正式环境不要这样存）
  String? _lastPassword;

  /// 是否开启自动登录
  bool _autoLoginEnabled = false;

  bool _loaded = false;

  static const String _keyAccounts = 'auth_accounts';
  static const String _keyLastUsername = 'auth_last_username';
  static const String _keyLastPassword = 'auth_last_password';
  static const String _keyAutoLogin = 'auth_auto_login';

  String? get lastUsername => _lastUsername;

  @override
  void onInit() {
    super.onInit();
    _loadFromStorage();
  }

  /// 从 SharedPreferences 读取账号配置
  Future<void> _loadFromStorage() async {
    if (_loaded) return;
    _loaded = true;

    final prefs = await SharedPreferences.getInstance();

    final accountsJson = prefs.getString(_keyAccounts);
    if (accountsJson != null) {
      final Map<String, dynamic> data = jsonDecode(accountsJson);
      _accounts = data.map((key, value) => MapEntry(key, value.toString()));
    } else {
      // 首次启动：初始化测试账号
      _accounts = {
        'admin': 'admin123',
      };
      await _saveAccountsToStorage();
      // ✅ 给 admin 也补一个默认 profile（可选）
      _profiles['admin'] = {
        'displayName': 'Dr. admin',
        'centerCode': 1,
        'centerName': '江苏省中医院',
        'subCenterNo': '',
      };
      await _saveProfilesToStorage();
    }

    // ===== load profiles =====
    final profilesJson = prefs.getString(_keyProfiles);
    if (profilesJson != null) {
      final Map<String, dynamic> data = jsonDecode(profilesJson);
      _profiles = data.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)));
    } else {
      _profiles = {};
      await _saveProfilesToStorage();
    }

    _lastUsername = prefs.getString(_keyLastUsername);
    _lastPassword = prefs.getString(_keyLastPassword);
    _autoLoginEnabled = prefs.getBool(_keyAutoLogin) ?? false;
  }

  Future<void> _saveProfilesToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfiles, jsonEncode(_profiles));
  }

  Future<void> _saveAccountsToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccounts, jsonEncode(_accounts));
  }

  Future<void> _saveLoginInfoToStorage(
      String username, String password, bool autoLogin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastUsername, username);
    await prefs.setString(_keyLastPassword, password);
    await prefs.setBool(_keyAutoLogin, autoLogin);

    _lastUsername = username;
    _lastPassword = password;
    _autoLoginEnabled = autoLogin;
  }

  /// 注册一个新医生账号
  /// 返回 null 表示成功，其它字符串为错误信息
  Future<String?> registerDoctor({
    required String username,
    required String password,
    required int centerCode,
    required String centerName,
    required String subCenterNo,
  }) async {
    await _loadFromStorage();

    username = username.trim();
    password = password.trim();

    if (username.isEmpty || password.isEmpty) {
      return 'Username and password cannot be empty.';
    }

    if (_accounts.containsKey(username)) {
      return 'This username already exists.';
    }

    if (password.length < 4) {
      return 'Password must be at least 4 characters.';
    }

    _accounts[username] = password;
    await _saveAccountsToStorage();

    // ✅ 保存医生资料（研究中心信息）
    _profiles[username] = {
      'displayName': 'Dr. $username',
      'centerCode': centerCode,
      'centerName': centerName,
      'subCenterNo': subCenterNo,
    };
    await _saveProfilesToStorage();

    // 注册后记住用户名，方便回填
    await _saveLoginInfoToStorage(username, password, false);

    return null; // 成功

  }

  /// 普通登录
  /// remember = true 时会保存账号并下次自动登录
  Future<bool> login(String username, String password,
      {bool remember = true}) async {
    await _loadFromStorage();

    username = username.trim();
    password = password.trim();

    if (username.isEmpty || password.isEmpty) {
      return false;
    }

    final savedPwd = _accounts[username];
    if (savedPwd == null) {
      return false;
    }
    if (savedPwd != password) {
      return false;
    }

    if (remember) {
      await _saveLoginInfoToStorage(username, password, true);
    }

    isLoggedIn.value = true;

    // ✅ 从 profile 取研究中心信息（兼容老账号/无 profile 情况）
    final p = _profiles[username];
    final displayName = (p?['displayName']?.toString()) ?? 'Dr. $username';

    final int centerCode = (p?['centerCode'] is int)
        ? (p!['centerCode'] as int)
        : int.tryParse(p?['centerCode']?.toString() ?? '') ?? 1;

    final String centerName = (p?['centerName']?.toString()) ?? '';
    final String subCenterNo = (p?['subCenterNo']?.toString()) ?? '';

    currentDoctor.value = Doctor(
      username: username,
      displayName: displayName,
      centerCode: centerCode,
      centerName: centerName,
      subCenterNo: subCenterNo,
    );


    // ✅ 登录成功时：为当前账号创建对应的 PatientController
    // 如果之前有（比如刚退出了另一个账号），先删掉旧的
    if (Get.isRegistered<PatientController>()) {
      Get.delete<PatientController>(force: true);
    }

    // 用当前登录账号的 username 创建病人控制器
    Get.put<PatientController>(
      PatientController(username),
      permanent: true,
    );

    return true;
  }

  /// 尝试自动登录（用于启动 App 时）
  /// 返回：是否自动登录成功
  Future<bool> tryAutoLogin() async {
    await _loadFromStorage();

    if (!_autoLoginEnabled ||
        _lastUsername == null ||
        _lastPassword == null) {
      return false;
    }

    // 不再重复写 autoLogin 标志
    return await login(_lastUsername!, _lastPassword!, remember: false);
  }

  /// 退出登录
  Future<void> logout() async {
    Get.log('🔴 AuthController.logout() called');
    // ✅ 先删掉当前账号对应的 PatientController
    if (Get.isRegistered<PatientController>()) {
      Get.log('🔴 Deleting PatientController with force');
      Get.delete<PatientController>(force: true);
    }else {
      Get.log('🔴 No PatientController registered');
    }

    // 再清理登录状态
    isLoggedIn.value = false;
    currentDoctor.value = null;

    // 退出后关闭自动登录（保留用户名，用于回填）
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoLogin, false);
    _autoLoginEnabled = false;
  }
}
