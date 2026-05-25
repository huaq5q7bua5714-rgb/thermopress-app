import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:poct_app/pages/home/patient_controller.dart';
import 'package:poct_app/pages/measurement_page.dart';
import 'package:poct_app/pages/router/measurement_record_detail_page.dart';

class PatientDetailPage extends StatelessWidget {
  final Patient patient;

  const PatientDetailPage({
    Key? key,
    required this.patient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pc = Get.find<PatientController>();

    String two(int v) => v.toString().padLeft(2, '0');
    String fmt_dt(DateTime dt) {
      return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
    }

    Widget statRow(String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$label:', style: const TextStyle(fontSize: 13, color: Colors.black54)),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        title: const Text(
          '患者详细信息',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== 顶部 Patient Profile =====
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.blue.withValues(alpha: 0.15),
                        child: const Icon(Icons.person, color: Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${patient.age} 岁, ${patient.weight.toStringAsFixed(0)} kg',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              patient.phone,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          pc.selectPatient(patient);
                          Get.to(() => const MeasurementPage());
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFE0EDFF),
                          foregroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: const Text(
                          '测量',
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

              const SizedBox(height: 16),

              // ===== Latest Measurement (Obx) =====
              Obx(() {
                final latest = pc.getLastSummaryForPatient(patient.phone);

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: latest == null
                        ? const Text(
                      '目前没有测量数据 请完成一次测量',
                      style: TextStyle(color: Colors.black54),
                    )
                        : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '最近一次测量数据',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '结束时间: ${fmt_dt(latest.endTime)}',
                          style: const TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '采样点数: ${latest.count}',
                          style: const TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        const SizedBox(height: 12),

                        // ✅ 温度左 / 力右：字段齐全
                        Row(
                          children: [
                            // Temperature (LEFT)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '温度',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  statRow('最大值', '${latest.maxTemp.toStringAsFixed(1)}°C'),
                                  statRow('最小值', '${latest.minTemp.toStringAsFixed(1)}°C'),
                                  statRow('平均值', '${latest.avgTemp.toStringAsFixed(1)}°C'),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Pressure (RIGHT)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '压力',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  statRow('最大值', '${latest.maxForce.toStringAsFixed(0)}N'),
                                  statRow('最小值', '${latest.minForce.toStringAsFixed(0)}N'),
                                  statRow('平均值', '${latest.avgForce.toStringAsFixed(0)}N'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 16),

              const Text(
                '历史测量记录',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: Obx(() {
                  final history = pc.getHistoryForPatient(patient.phone);

                  if (history.isEmpty) {
                    return const Center(
                      child: Text(
                        '目前没有测量数据 请完成一次测量',
                        style: TextStyle(color: Colors.black54),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final s = history[index];

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          elevation: 2,
                          child: ListTile(
                            title: Text(
                              fmt_dt(s.endTime),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              '平均温度: ${s.avgTemp.toStringAsFixed(1)}°C, '
                                  '平均压力: ${s.avgForce.toStringAsFixed(0)}N',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            trailing: Wrap(
                              spacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    Get.to(() => MeasurementRecordDetailPage(summary: s));
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: const Color(0xFFE0EDFF),
                                    foregroundColor: Colors.blue,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text(
                                    '查看',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  tooltip: '删除',
                                  onPressed: () async {
                                    final ok = await Get.dialog<bool>(
                                      AlertDialog(
                                        title: const Text('确定要删除测量数据吗?'),
                                        content: const Text(
                                          '本次测量数据将会被删除\n'
                                              '如果存在对应的csv文件，会一起被删除',
                                        ),
                                        actions: [
                                          TextButton(onPressed: () => Get.back(result: false), child: const Text('取消')),
                                          TextButton(onPressed: () => Get.back(result: true), child: const Text('删除')),
                                        ],
                                      ),
                                    );

                                    if (ok != true) return;

                                    await pc.delete_measurement_record(patient.phone, s);

                                    Get.snackbar(
                                      '删除',
                                      '测量数据删除成功！',
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
