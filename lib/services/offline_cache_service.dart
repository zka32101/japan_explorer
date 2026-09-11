import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// Hive-based offline cache with a configurable TTL.
/// All data is stored as JSON strings — no TypeAdapters needed.
class OfflineCacheService {
  OfflineCacheService._();

  static const _kCurationsBox = 'curations_cache';
  static const _kDetailsBox = 'details_cache';
  static const _kTimestampsBox = 'cache_timestamps';
  static const _kTtlHours = 24;

  late final Box<String> _curationsBox;
  late final Box<String> _detailsBox;
  late final Box<int> _timestampsBox;

  bool _initialized = false;

  // ── Init ────────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    _curationsBox = await Hive.openBox<String>(_kCurationsBox);
    _detailsBox = await Hive.openBox<String>(_kDetailsBox);
    _timestampsBox = await Hive.openBox<int>(_kTimestampsBox);
    _initialized = true;
  }

  // ── Curations list ──────────────────────────────────────────────────────────

  /// Cache a list of curation maps under [key] (e.g. 'all' or 'food').
  Future<void> cacheCurations(
      String key, List<Map<String, dynamic>> data) async {
    await _curationsBox.put(key, json.encode(data));
    await _timestampsBox.put('curations_$key',
        DateTime.now().millisecondsSinceEpoch);
  }

  /// Returns cached curations for [key], or null if missing/stale.
  List<Map<String, dynamic>>? getCachedCurations(String key) {
    if (!_isFresh('curations_$key')) return null;
    final raw = _curationsBox.get(key);
    if (raw == null) return null;
    return (json.decode(raw) as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  bool hasCachedCurations(String key) =>
      _isFresh('curations_$key') && _curationsBox.containsKey(key);

  // ── Curation detail ─────────────────────────────────────────────────────────

  Future<void> cacheCurationDetail(
      String id, Map<String, dynamic> data) async {
    await _detailsBox.put(id, json.encode(data));
    await _timestampsBox.put(
        'detail_$id', DateTime.now().millisecondsSinceEpoch);
  }

  Map<String, dynamic>? getCachedDetail(String id) {
    if (!_isFresh('detail_$id')) return null;
    final raw = _detailsBox.get(id);
    if (raw == null) return null;
    return json.decode(raw) as Map<String, dynamic>;
  }

  bool hasCachedDetail(String id) =>
      _isFresh('detail_$id') && _detailsBox.containsKey(id);

  // ── Generic JSON helpers ────────────────────────────────────────────────────

  Future<void> cacheJson(String key, dynamic data) async {
    await _detailsBox.put('json_$key', json.encode(data));
    await _timestampsBox.put(
        'json_$key', DateTime.now().millisecondsSinceEpoch);
  }

  dynamic getCachedJson(String key) {
    if (!_isFresh('json_$key')) return null;
    final raw = _detailsBox.get('json_$key');
    if (raw == null) return null;
    return json.decode(raw);
  }

  // ── Housekeeping ────────────────────────────────────────────────────────────

  Future<void> clearAll() async {
    await _curationsBox.clear();
    await _detailsBox.clear();
    await _timestampsBox.clear();
  }

  Future<void> clearStale() async {
    final staleKeys = _timestampsBox.keys
        .where((k) => !_isFresh(k.toString()))
        .toList();
    for (final key in staleKeys) {
      await _timestampsBox.delete(key);
      if (key.toString().startsWith('curations_')) {
        await _curationsBox.delete(
            key.toString().replaceFirst('curations_', ''));
      } else if (key.toString().startsWith('detail_') ||
          key.toString().startsWith('json_')) {
        await _detailsBox
            .delete(key.toString().replaceFirst(RegExp(r'^(detail_|json_)'), ''));
      }
    }
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  bool _isFresh(String timestampKey) {
    final ts = _timestampsBox.get(timestampKey);
    if (ts == null) return false;
    final cached = DateTime.fromMillisecondsSinceEpoch(ts);
    return DateTime.now().difference(cached).inHours < _kTtlHours;
  }
}

final offlineCacheService = OfflineCacheService._();
