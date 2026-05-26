import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:poct_app/data/measurement_models.dart';

class MeasurementSetupDialog extends StatefulWidget {
  const MeasurementSetupDialog({super.key});

  @override
  State<MeasurementSetupDialog> createState() => _MeasurementSetupDialogState();
}

class _MeasurementSetupDialogState extends State<MeasurementSetupDialog> {
  BodyRegion _region = BodyRegion.knee;
  SymptomType _symptom = SymptomType.skipped;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('测量设置'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '身体区域',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: BodyRegion.values.map((region) {
                return ChoiceChip(
                  label: Text(BodyRegions.label(region)),
                  selected: _region == region,
                  onSelected: (_) => setState(() => _region = region),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            const Text(
              '主诉类型',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SymptomType.values.map((symptom) {
                return ChoiceChip(
                  label: Text(SymptomTypes.label(symptom)),
                  selected: _symptom == symptom,
                  onSelected: (_) => setState(() => _symptom = symptom),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back<MeasurementSelection?>(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Get.back(
            result: MeasurementSelection(
              bodyRegion: _region,
              symptomType: _symptom,
            ),
          ),
          child: const Text('开始测量'),
        ),
      ],
    );
  }
}
