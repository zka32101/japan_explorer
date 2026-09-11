import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/curation.dart';
import 'offline_cache_service.dart';

/// Manages proactive bulk-download of content for offline use.
///
/// Lifecycle:
///   1. Call [syncAll] to download curations + images.
///   2. Observe [syncProgress] / [isSyncing] from the provider.
///   3. Call [clearDownloads] to free storage.
class OfflineSyncService {
  OfflineSyncService._();

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  final ValueNotifier<double> syncProgress = ValueNotifier(0);
  final ValueNotifier<String> syncStatus = ValueNotifier('');

  // Callback the provider registers to supply curations.
  Future<List<Curation>> Function()? _getCurations;
  void registerCurationsCallback(Future<List<Curation>> Function() cb) {
    _getCurations = cb;
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Download all curations + their first image for offline use.
  Future<bool> syncAll() async {
    if (_isSyncing) return false;
    _isSyncing = true;
    syncProgress.value = 0;
    syncStatus.value = 'Fetching content…';

    try {
      final getter = _getCurations;
      if (getter == null) {
        syncStatus.value = 'Not ready — please try again.';
        return false;
      }

      final curations = await getter();
      if (curations.isEmpty) {
        syncStatus.value = 'No content to download.';
        return false;
      }

      // 1. Cache curation metadata
      syncStatus.value = 'Caching spot data…';
      final allMaps = curations.map((c) => c.toMap()).toList();
      await offlineCacheService.cacheCurations('all', allMaps);

      // 2. Download hero images
      final imageDir = await _imageDir();
      int done = 0;
      for (final c in curations) {
        syncStatus.value = 'Downloading images (${done + 1}/${curations.length})…';
        if (c.imageUrls.isNotEmpty) {
          await _downloadImage(c.imageUrls.first, imageDir, c.id);
        }
        done++;
        syncProgress.value = done / curations.length;
      }

      syncStatus.value = 'Done! ${curations.length} spots saved offline.';
      return true;
    } catch (e) {
      syncStatus.value = 'Sync failed: $e';
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Delete all cached images and clear Hive data.
  Future<void> clearDownloads() async {
    await offlineCacheService.clearAll();
    final dir = await _imageDir();
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
    syncProgress.value = 0;
    syncStatus.value = '';
  }

  /// Returns approximate storage used in MB.
  Future<double> storageMb() async {
    double total = 0;
    final dir = await _imageDir();
    if (dir.existsSync()) {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          total += await entity.length();
        }
      }
    }
    return total / (1024 * 1024);
  }

  /// Returns the local file path for a cached image, or null.
  Future<String?> cachedImagePath(String curationId) async {
    final dir = await _imageDir();
    final file = File('${dir.path}/$curationId.jpg');
    return file.existsSync() ? file.path : null;
  }

  /// True if the full sync has been done (all curations are cached).
  bool get hasSyncedContent =>
      offlineCacheService.hasCachedCurations('all');

  // ── Private helpers ─────────────────────────────────────────────────────────

  Future<Directory> _imageDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/offline_images');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  Future<void> _downloadImage(
      String url, Directory dir, String id) async {
    try {
      final file = File('${dir.path}/$id.jpg');
      if (file.existsSync()) return; // already downloaded
      final resp = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) {
        await file.writeAsBytes(resp.bodyBytes);
      }
    } catch (_) {
      // Skip failed image silently
    }
  }
}

final offlineSyncService = OfflineSyncService._();
