import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/curation.dart';
import '../services/analytics_service.dart';
import '../services/firebase_service.dart';
import '../services/offline_cache_service.dart';
import '../utils/constants.dart';
import 'auth_provider.dart';

final selectedCategoryProvider = StateProvider<String?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');

final curationsProvider =
    FutureProvider.family<List<Curation>, String?>((ref, category) async {
  final service = ref.read(firebaseServiceProvider);
  return service.getCurations(category: category);
});

final curationDetailProvider =
    FutureProvider.family<Curation?, String>((ref, id) async {
  final service = ref.read(firebaseServiceProvider);
  return service.getCuration(id);
});

final searchResultsProvider =
    FutureProvider.family<List<Curation>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final service = ref.read(firebaseServiceProvider);
  return service.searchCurations(query);
});

class CurationsNotifier extends StateNotifier<AsyncValue<List<Curation>>> {
  final FirebaseService _service;
  String? _currentCategory;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  DocumentSnapshot? _lastDocument;

  CurationsNotifier(this._service) : super(const AsyncValue.loading()) {
    loadInitial();
  }

  Future<void> loadInitial({String? category}) async {
    _currentCategory = category;
    _hasMore = true;
    _isLoadingMore = false;
    _lastDocument = null;
    state = const AsyncValue.loading();

    final cacheKey = category ?? 'all';

    try {
      final (items, cursor) =
          await _service.getCurationsPage(category: category);
      _lastDocument = cursor;
      _hasMore = items.length >= AppConstants.pageSize;
      state = AsyncValue.data(items);

      // Cache the first page for offline use
      await offlineCacheService.cacheCurations(
        cacheKey,
        items.map((c) => c.toMap()).toList(),
      );
    } catch (e, st) {
      // Try to serve from cache
      final cached = offlineCacheService.getCachedCurations(cacheKey);
      if (cached != null) {
        analyticsService.logOfflineCacheUsed('home');
        _hasMore = false;
        state = AsyncValue.data(
          cached.map(Curation.fromMap).toList(),
        );
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    final current = state.valueOrNull;
    if (current == null) return;

    _isLoadingMore = true;
    try {
      final (more, cursor) = await _service.getCurationsPage(
        category: _currentCategory,
        lastDoc: _lastDocument,
      );
      if (more.isEmpty) {
        _hasMore = false;
        // Force a rebuild so the UI switches from spinner to "all seen" message
        state = AsyncValue.data(current);
      } else {
        _lastDocument = cursor;
        _hasMore = more.length >= AppConstants.pageSize;
        state = AsyncValue.data([...current, ...more]);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> filterByCategory(String? category) async {
    await loadInitial(category: category);
  }

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
}

final curationsNotifierProvider =
    StateNotifierProvider<CurationsNotifier, AsyncValue<List<Curation>>>((ref) {
  return CurationsNotifier(ref.read(firebaseServiceProvider));
});
