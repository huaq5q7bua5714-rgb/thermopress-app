import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:poct_app/pages/home/auth_controller.dart';
import 'package:poct_app/pages/home/home_page.dart';
import 'package:poct_app/pages/router/register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AuthController _authController;

  /// 登录按钮 loading 状态
  final RxBool _isLoading = false.obs;

  /// 密码是否隐藏
  final RxBool _obscurePassword = true.obs;

  @override
  void initState() {
    super.initState();
    _authController = Get.find<AuthController>();

    // 启动后尝试自动登录
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ok = await _authController.tryAutoLogin();
      if (ok) {
        // 自动登录成功，直接进主页
        Get.offAll(() => const HomePage());
      } else {
        // 自动登录失败，把上次的用户名回填一下
        _usernameController.text = _authController.lastUsername ?? '';
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    // 表单校验
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    _isLoading.value = true;

    try {
      final success =
      await _authController.login(username, password, remember: true);

      if (!success) {
        // 登录失败：提示 + 不跳转
        Get.snackbar(
          '登录失败',
          '用户名或密码错误',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.08),
          colorText: Colors.redAccent,
        );
        return;
      }

      // 登录成功：清空栈并进入 HomePage
      Get.offAll(() => const HomePage());
    } catch (e) {
      // 任意异常都捕获，防止红屏
      Get.snackbar(
        'Error',
        'Unexpected error: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.08),
        colorText: Colors.redAccent,
      );
    } finally {
      // 一定要还原 loading 状态
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ===== 标题 =====
                const Text(
                  'ThermoPress',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Color(0xFF1D88F5),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '穴位压温智能检测系统',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2933),
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '请点击"登录"按键查看患者数据',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 32),

                // ===== 表单区域 =====
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Doctor Name
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: '医生姓名',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              isDense: true,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return '请输入医生姓名';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password + 小眼睛
                          Obx(() {
                            return TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword.value,
                              decoration: InputDecoration(
                                labelText: '密码',
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword.value
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    _obscurePassword.value =
                                    !_obscurePassword.value;
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                isDense: true,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return '请输入密码';
                                }
                                if (v.trim().length < 4) {
                                  return '密码长度至少为4';
                                }
                                return null;
                              },
                            );
                          }),

                          const SizedBox(height: 24),

                          // 登录按钮（监听 _isLoading）
                          Obx(() {
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading.value ? null : _onLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1D88F5),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: _isLoading.value
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                                    : const Text(
                                  '登录',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          }),

                          const SizedBox(height: 12),

                          TextButton(
                            onPressed: () {
                              Get.snackbar(
                                '忘记密码',
                                '请联系软件App管理员',
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            },
                            child: const Text(
                              '忘记密码?',
                              style: TextStyle(
                                color: Colors.black54,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // 去注册
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 4,
                            runSpacing: 0,
                            children: [
                              const Text(
                                "没有账户?",
                                style: TextStyle(fontSize: 13),
                              ),
                              TextButton(
                                onPressed: () {
                                  Get.to(() => const RegisterPage());
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: const Text(
                                  '点击创建',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
