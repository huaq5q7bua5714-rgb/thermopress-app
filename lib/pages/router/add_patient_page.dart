import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:poct_app/pages/home/patient_controller.dart';
import 'package:poct_app/pages/home/auth_controller.dart';
import 'package:poct_app/pages/measurement_page.dart';

class AddPatientPage extends StatefulWidget {
  const AddPatientPage({Key? key}) : super(key: key);

  @override
  State<AddPatientPage> createState() => _AddPatientPageState();
}

class _AddPatientPageState extends State<AddPatientPage> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _weightController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          '添加新患者',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildTextField(
                              controller: _nameController,
                              label: '姓名',
                              hint: '请输入患者全名',
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _ageController,
                              label: '年龄',
                              hint: '请输入患者年龄',
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _phoneController,
                              label: '电话号码',
                              hint: '+86',
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _weightController,
                              label: '体重 (kg)',
                              hint: '请输入患者体重',
                              keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _onSaveAndStart(),
                            ),

                            const SizedBox(height: 20),

                            // 让按钮尽量在底部；空间不够时滚动，不会溢出
                            const Spacer(),

                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Get.back(),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    ),
                                    child: const Text('取消'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _onSaveAndStart,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    ),
                                    child: const Text(
                                      '保存并开始测量',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    void Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        isDense: true,
      ),
    );
  }

  void _onSaveAndStart() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final age = int.tryParse(_ageController.text.trim()) ?? 0;
    final weight = double.tryParse(_weightController.text.trim()) ?? 0.0;

    PatientController pc;
    if (Get.isRegistered<PatientController>()) {
      pc = Get.find<PatientController>();
    } else {
      final auth = Get.find<AuthController>();
      final doctor = auth.currentDoctor.value;
      final username = doctor?.username ?? 'guest';

      pc = Get.put<PatientController>(
        PatientController(username),
        permanent: true,
      );
    }

    pc.addPatient(
      Patient(
        name: name,
        age: age,
        weight: weight,
        phone: phone,
      ),
    );

    Get.snackbar(
      '患者已保存',
      '新患者 $name 已保存到本地',
    );

    Get.off(() => const MeasurementPage());
  }
}
