import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:poct_app/data/measurement_models.dart';

class AcupointCatalogEntry {
  final String name;
  final String code;
  final List<String> aliases;
  final String meridian;
  final String region;
  final String referenceRegion;
  final List<String> symptoms;
  final String referenceMode;
  final String note;

  const AcupointCatalogEntry({
    required this.name,
    required this.code,
    required this.aliases,
    required this.meridian,
    required this.region,
    required this.referenceRegion,
    required this.symptoms,
    required this.referenceMode,
    required this.note,
  });

  factory AcupointCatalogEntry.fromJson(Map<String, dynamic> json) {
    List<String> list(dynamic value) =>
        (value as List? ?? const []).map((e) => '$e').toList();

    return AcupointCatalogEntry(
      name: '${json['name'] ?? ''}',
      code: '${json['code'] ?? ''}',
      aliases: list(json['aliases']),
      meridian: '${json['meridian'] ?? ''}',
      region: '${json['region'] ?? ''}',
      referenceRegion: '${json['reference_region'] ?? json['region'] ?? ''}',
      symptoms: list(json['symptoms']),
      referenceMode: '${json['reference_mode'] ?? 'region_fallback'}',
      note: '${json['note'] ?? ''}',
    );
  }

  String get label => code.trim().isEmpty ? name : '$name $code';

  bool matches(String query) {
    final normalized = _normalize(query);
    if (normalized.isEmpty) return false;
    if (_normalize(name) == normalized) return true;
    if (_normalize(code) == normalized) return true;
    return aliases.any((alias) => _normalize(alias) == normalized);
  }

  bool belongsTo(BodyRegion bodyRegion) {
    return region == BodyRegions.id(bodyRegion);
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
  }
}

class AcupointCatalog {
  static List<AcupointCatalogEntry>? _cache;

  static Future<List<AcupointCatalogEntry>> all() async {
    if (_cache != null) return _cache!;
    final text =
        await rootBundle.loadString('assets/reference/acupoint_catalog.json');
    final data = Map<String, dynamic>.from(jsonDecode(text) as Map);
    final entries = (data['acupoints'] as List? ?? const [])
        .map((item) =>
            AcupointCatalogEntry.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    _cache = entries;
    return entries;
  }

  static Future<AcupointCatalogEntry?> resolve(String query) async {
    final text = query.trim();
    if (text.isEmpty) return null;
    final entries = await all();
    for (final entry in entries) {
      if (entry.matches(text)) return entry;
    }
    return null;
  }

  static Future<List<AcupointCatalogEntry>> commonForRegion(
    BodyRegion bodyRegion,
  ) async {
    final entries = await all();
    return entries.where((entry) => entry.belongsTo(bodyRegion)).toList();
  }
}
