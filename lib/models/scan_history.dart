import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// A single camera AI scan record stored locally.
class ScanRecord {
  final String id;
  final String landmarkName;
  final String description;
  final String historicalBackground;
  final String howToExperience;
  final String phraseJapanese;
  final String phraseRomaji;
  final String phraseEnglish;
  final DateTime scannedAt;
  final String provider; // 'gemini' | 'claude'
  final String? imagePath;  // local file path (may become stale)
  final String? nearbyCurationId;

  const ScanRecord({
    required this.id,
    required this.landmarkName,
    required this.description,
    required this.historicalBackground,
    required this.howToExperience,
    required this.phraseJapanese,
    required this.phraseRomaji,
    required this.phraseEnglish,
    required this.scannedAt,
    required this.provider,
    this.imagePath,
    this.nearbyCurationId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'landmarkName': landmarkName,
        'description': description,
        'historicalBackground': historicalBackground,
        'howToExperience': howToExperience,
        'phraseJapanese': phraseJapanese,
        'phraseRomaji': phraseRomaji,
        'phraseEnglish': phraseEnglish,
        'scannedAt': scannedAt.toIso8601String(),
        'provider': provider,
        'imagePath': imagePath,
        'nearbyCurationId': nearbyCurationId,
      };

  factory ScanRecord.fromJson(Map<String, dynamic> json) => ScanRecord(
        id: json['id'] as String,
        landmarkName: json['landmarkName'] as String? ?? '',
        description: json['description'] as String? ?? '',
        historicalBackground: json['historicalBackground'] as String? ?? '',
        howToExperience: json['howToExperience'] as String? ?? '',
        phraseJapanese: json['phraseJapanese'] as String? ?? '',
        phraseRomaji: json['phraseRomaji'] as String? ?? '',
        phraseEnglish: json['phraseEnglish'] as String? ?? '',
        scannedAt: DateTime.parse(json['scannedAt'] as String),
        provider: json['provider'] as String? ?? 'gemini',
        imagePath: json['imagePath'] as String?,
        nearbyCurationId: json['nearbyCurationId'] as String?,
      );
}

/// Local-only repository backed by SharedPreferences.
/// Keeps the last [maxRecords] scans.
class ScanHistoryRepository {
  static const _key = 'scan_history_v1';
  static const maxRecords = 30;

  Future<List<ScanRecord>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => ScanRecord.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    } catch (_) {
      return [];
    }
  }

  Future<void> add(ScanRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getAll();

    // Deduplicate: skip if same landmark was scanned in the last 5 minutes
    final recent = existing.isNotEmpty ? existing.first : null;
    if (recent != null &&
        recent.landmarkName == record.landmarkName &&
        record.scannedAt.difference(recent.scannedAt).inMinutes < 5) {
      return;
    }

    final updated = [record, ...existing].take(maxRecords).toList();
    await prefs.setString(
        _key, jsonEncode(updated.map((r) => r.toJson()).toList()));
  }

  Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getAll();
    final updated = existing.where((r) => r.id != id).toList();
    await prefs.setString(
        _key, jsonEncode(updated.map((r) => r.toJson()).toList()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

final scanHistoryRepository = ScanHistoryRepository();
