import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:poct_app/pages/home/home_contolller.dart';
import 'package:poct_app/pages/home/patient_controller.dart';
import 'package:poct_app/pages/measurement_page.dart';
import 'package:poct_app/pages/router/patient_detail_page.dart';
import 'package:poct_app/pages/router/add_patient_page.dart';
import 'package:poct_app/pages/home/auth_controller.dart';
import 'package:poct_app/pages/router/login_page.dart';

class WorkspacePage extends StatefulWidget {
  const WorkspacePage({super.key});

  @override
  State<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends State<WorkspacePage> {
  late final TextEditingController _search_controller;

  @override
  void initState() {
    super.initState();
    _search_controller = TextEditingController();
  }

  @override
  void dispose() {
    _search_controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patient_controller = Get.find<PatientController>();

    return GetBuilder<HomeController>(builder: (home_controller) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F7FB),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
          title: Obx(() {
            final auth = Get.find<AuthController>();
            final doctor = auth.currentDoctor.value;
            final title_text =
            doctor != null ? '${doctor.displayName}' : '患者';
            return Text(
              title_text,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            );
          }),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed: () async {
                  final auth = Get.find<AuthController>();
                  await auth.logout();
                  Get.offAll(() => const LoginPage());
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  '退出登录',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== 顶部 BLE 状态栏 =====
                Obx(() {
                  final info = home_controller.bluetoothInfo.value;
                  final connected = info.isConnected;
                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: connected
                              ? const Color(0xFFE2F5EB)
                              : const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bluetooth,
                              size: 18,
                              color: connected
                                  ? const Color(0xFF16A34A)
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              connected ? '蓝牙已连接' : '蓝牙未连接',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: connected
                                    ? const Color(0xFF15803D)
                                    : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          connected
                              ? info.platformName
                              : '无设备连接',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  );
                }),

                const SizedBox(height: 16),

                // ===== 搜索患者（仅搜索当前医生账号下的 patients） =====
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Obx(() {
                    final q = patient_controller.searchQuery.value;
                    return TextField(
                      controller: _search_controller,
                      onChanged: patient_controller.setSearchQuery,
                      decoration: InputDecoration(
                        hintText: '搜索患者 (姓名 / 电话号码)',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: q.isEmpty
                            ? null
                            : IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            patient_controller.clearSearch();
                            _search_controller.clear();
                            FocusScope.of(context).unfocus();
                          },
                        ),
                        border: InputBorder.none,
                        contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 16),

                // ===== 患者列表 =====
                Expanded(
                  child: _PatientsList(
                    patientController: patient_controller,
                    onTapPatient: (p) {
                      patient_controller.selectPatient(p);
                      Get.to(() => PatientDetailPage(patient: p));
                    },
                    onStartMeasurement: (p) {
                      patient_controller.selectPatient(p);
                      final info = home_controller.bluetoothInfo.value;
                      if (!info.isConnected) {
                        Get.snackbar('无设备连接', '蓝牙未连接, 使用内部模拟数据');
                      }
                      Get.to(() => const MeasurementPage());
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Get.to(() => const AddPatientPage());
          },
          backgroundColor: Colors.blue,
          child: const Icon(Icons.add),
        ),
      );
    });
  }
}

class _PatientsList extends StatelessWidget {
  final PatientController patientController;
  final void Function(Patient p) onTapPatient;
  final void Function(Patient p) onStartMeasurement;

  const _PatientsList({
    Key? key,
    required this.patientController,
    required this.onTapPatient,
    required this.onStartMeasurement,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // ✅ 关键：必须用过滤后的列表
      final list = patientController.filteredPatients;

      if (list.isEmpty) {
        final q = patientController.searchQuery.value.trim();
        final show_text = q.isEmpty
            ? '无患者 请点击 + 添加患者'
            : 'No results for "$q"';

        return Center(
          child: Text(
            show_text,
            style: const TextStyle(color: Colors.black54),
          ),
        );
      }

      return ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, index) {
          final p = list[index];
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              elevation: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onTapPatient(p),
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // 左侧 文字信息
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${p.age} 岁, ${p.weight.toStringAsFixed(0)} kg',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              p.phone,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 删除按钮
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent),
                        onPressed: () {
                          Get.defaultDialog(
                            title: '删除患者',
                            middleText:
                            '你确定想要删除患者${p.name}吗?',
                            textCancel: '取消',
                            textConfirm: '删除',
                            confirmTextColor: Colors.white,
                            onConfirm: () {
                              patientController.deletePatient(p);
                              Get.back();
                            },
                          );
                        },
                      ),

                      const SizedBox(width: 4),

                      // Start 按钮
                      TextButton.icon(
                        onPressed: () => onStartMeasurement(p),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFE0EDFF),
                          foregroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: const Text(
                          '开始测量',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }
}
