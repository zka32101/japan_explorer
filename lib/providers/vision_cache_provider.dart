import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/vision_cache_service.dart';

final visionCacheServiceProvider = Provider<VisionCacheService>((ref) {
  return VisionCacheService();
});

final visionCacheSizeProvider = FutureProvider<double>((ref) async {
  final service = ref.watch(visionCacheServiceProvider);
  return service.getCacheSizeMB();
});

final visionCacheHistoryProvider =
    StateNotifierProvider<VisionCacheHistoryNotifier, List<CachedAnalysis>>((ref) {
  final service = ref.watch(visionCacheServiceProvider);
  return VisionCacheHistoryNotifier(service);
});

class CachedAnalysis {
  final String imageHash;
  final String analysisType;
  final String resultJson;
  final String imagePath;
  final DateTime cachedAt;

  CachedAnalysis({
    required this.imageHash,
    required this.analysisType,
    required this.resultJson,
    required this.imagePath,
    required this.cachedAt,
  });
}

class VisionCacheHistoryNotifier extends StateNotifier<List<CachedAnalysis>> {
  final VisionCacheService _service;

  VisionCacheHistoryNotifier(this._service) : super([]) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final whatIsThisResults = _service.getAnalysesByType('what_is_this');
    final menuResults = _service.getAnalysesByType('menu_translator');

    final allResults = [
      ...whatIsThisResults.map((e) => CachedAnalysis(
        imageHash: e.imageHash,
        analysisType: e.analysisType,
        resultJson: e.resultJson,
        imagePath: e.imagePath,
        cachedAt: e.cachedAt,
      )),
      ...menuResults.map((e) => CachedAnalysis(
        imageHash: e.imageHash,
        analysisType: e.analysisType,
        resultJson: e.resultJson,
        imagePath: e.imagePath,
        cachedAt: e.cachedAt,
      )),
    ];

    // Sort by most recent first
    allResults.sort((a, b) => b.cachedAt.compareTo(a.cachedAt));

    state = allResults;
  }

  Future<void> clearOldCache({int daysOld = 7}) async {
    await _service.clearOldCache(daysOld: daysOld);
    await _loadHistory();
  }

  Future<void> clearAll() async {
    await _service.clearAll();
    state = [];
  }
}
