import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:poct_app/pages/home/auth_controller.dart';
import 'package:poct_app/pages/router/login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  // ===== Research center fields =====
  final RxInt _centerCode = 1.obs; // 默认 01
  final _subCenterController = TextEditingController();

  final RxBool _isLoading = false.obs;
  final RxBool _obscurePassword = true.obs;
  final RxBool _obscureConfirm = true.obs;

  late final AuthController _authController;

  static const List<Map<String, dynamic>> _centers = [
    {'code': 1, 'name': '江苏省中医院'},
    {'code': 2, 'name': '中国中医科学院广安门医院'},
    {'code': 3, 'name': '常州市中医医院'},
    {'code': 4, 'name': '昆山市中医医院'},
    {'code': 5, 'name': '上海市中医医院'},
    {'code': 6, 'name': '广东省中医院'},
    {'code': 7, 'name': '浙江中医药大学第二附属医院'},
  ];

  @override
  void initState() {
    super.initState();
    _authController = Get.find<AuthController>();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _subCenterController.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();
    final centerCode = _centerCode.value;
    final centerName = _centers.firstWhere((c) => c['code'] == centerCode)['name'] as String;
    final subCenterNo = _subCenterController.text.trim();

    if (password != confirm) {
      Get.snackbar(
        '错误',
        '两次输入的密码不匹配',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.08),
        colorText: Colors.redAccent,
      );
      return;
    }

    _isLoading.value = true;

    try {
      final err = await _authController.registerDoctor(
        username: username,
        password: password,
        centerCode: centerCode,
        centerName: centerName,
        subCenterNo: subCenterNo,
      );


      if (err != null) {
        Get.snackbar(
          '注册失败',
          err,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.08),
          colorText: Colors.redAccent,
        );
        return;
      }

      // 注册成功：提示 + 回到登录页，并且登录页会自动回填用户名
      Get.snackbar(
        '注册成功',
        '成功创建账户,请登录',
        snackPosition: SnackPosition.BOTTOM,
      );

      // 返回登录页（如果注册页是从登录页 push 过来的，直接 back 即可）
      Get.off(() => const LoginPage());
    } catch (e) {
      Get.snackbar(
        'Error',
        'Unexpected error: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.08),
        colorText: Colors.redAccent,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text(
          '创建医生账户',
          style: TextStyle(fontWeight: FontWeight.w400),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // ===== Research Center =====
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '研究中心信息',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withOpacity(0.65),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Obx(() {
                        return DropdownButtonFormField<int>(
                          isExpanded: true, // ✅ 关键：占满宽度，避免 overflow
                          value: _centerCode.value,

                          // ✅ 下拉列表：显示“编号 + 全称”
                          items: _centers.map((c) {
                            final code = c['code'] as int;
                            final name = c['name'] as String;
                            final codeStr = code.toString().padLeft(2, '0');
                            return DropdownMenuItem<int>(
                              value: code,
                              child: Text(
                                '$codeStr  $name',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),

                          // ✅ 选中后：只显示短文本（比如“中心 01”），不会撑爆
                          selectedItemBuilder: (context) {
                            return _centers.map((c) {
                              final code = c['code'] as int;
                              final codeStr = code.toString().padLeft(2, '0');
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '中心 $codeStr',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList();
                          },

                          onChanged: (v) {
                            if (v != null) _centerCode.value = v;
                          },

                          decoration: InputDecoration(
                            labelText: '研究中心',
                            prefixIcon: const Icon(Icons.apartment_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            isDense: true,
                          ),
                        );
                      }),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _subCenterController,
                        decoration: InputDecoration(
                          labelText: '分中心编号',
                          prefixIcon: const Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          isDense: true,
                        ),
                        validator: (v) {
                          // 如果医院要求必填：取消注释即可
                          // if (v == null || v.trim().isEmpty) return '请输入分中心编号';

                          if (v != null && v.trim().isNotEmpty) {
                            final s = v.trim();
                            final ok = RegExp(r'^[0-9]{1,3}([\-_.][0-9]{1,3}){0,2}$').hasMatch(s);
                            if (!ok) return '分中心编号格式不正确';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
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

                      // Password
                      Obx(() {
                        return TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword.value,
                          decoration: InputDecoration(
                            labelText: '密码',
                            prefixIcon:
                            const Icon(Icons.lock_outline_rounded),
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
                              return '密码长度必须大于4';
                            }
                            return null;
                          },
                        );
                      }),
                      const SizedBox(height: 16),

                      // Confirm Password
                      Obx(() {
                        return TextFormField(
                          controller: _confirmController,
                          obscureText: _obscureConfirm.value,
                          decoration: InputDecoration(
                            labelText: '确认密码',
                            prefixIcon:
                            const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm.value
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                _obscureConfirm.value =
                                !_obscureConfirm.value;
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            isDense: true,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return '请再次输入密码';
                            }
                            if (v.trim().length < 4) {
                              return '密码长度必须大于4';
                            }
                            return null;
                          },
                        );
                      }),

                      const SizedBox(height: 24),

                      Obx(() {
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                            _isLoading.value ? null : _onRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1D88F5),
                              foregroundColor: Colors.white,
                              padding:
                              const EdgeInsets.symmetric(vertical: 12),
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
                              '创建账户',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
