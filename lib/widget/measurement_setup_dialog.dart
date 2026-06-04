import 'package:flutter/material.dart';
import 'package:poct_app/data/measurement_models.dart';
import 'package:poct_app/util/acupoint_catalog.dart';

class MeasurementSetupDialog extends StatefulWidget {
  const MeasurementSetupDialog({super.key});

  @override
  State<MeasurementSetupDialog> createState() => _MeasurementSetupDialogState();
}

class _MeasurementSetupDialogState extends State<MeasurementSetupDialog> {
  BodyRegion _region = BodyRegion.knee;
  SymptomType _symptom = SymptomType.skipped;
  final TextEditingController _acupointController = TextEditingController();
  List<AcupointCatalogEntry> _allAcupoints = const [];

  @override
  void initState() {
    super.initState();
    _loadAcupoints();
  }

  Future<void> _loadAcupoints() async {
    final entries = await AcupointCatalog.all();
    if (!mounted) return;
    setState(() => _allAcupoints = entries);
  }

  @override
  void dispose() {
    _acupointController.dispose();
    super.dispose();
  }

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
            const SizedBox(height: 18),
            const Text(
              '具体穴位',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _acupointController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                hintText: '可选，如 足三里 / 肾俞 / 三阴交',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            if (_regionAcupoints.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _regionAcupoints.map((entry) {
                  final selected =
                      _acupointController.text.trim() == entry.name ||
                          _acupointController.text.trim().toUpperCase() ==
                              entry.code.toUpperCase();
                  return ChoiceChip(
                    label: Text(entry.label),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _acupointController.text = entry.name);
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context, rootNavigator: true)
                .pop<MeasurementSelection?>(null);
          },
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop(
              MeasurementSelection(
                bodyRegion: _region,
                symptomType: _symptom,
                acupointName: _acupointController.text.trim(),
              ),
            );
          },
          child: const Text('开始测量'),
        ),
      ],
    );
  }

  List<AcupointCatalogEntry> get _regionAcupoints {
    return _allAcupoints.where((entry) => entry.belongsTo(_region)).toList();
  }
}
