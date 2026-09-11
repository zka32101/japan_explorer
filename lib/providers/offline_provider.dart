import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/offline_sync_service.dart';
import '../providers/curations_provider.dart';

// ── Sync state ──────────────────────────────────────────────────────────────

class OfflineSyncState {
  final bool isSyncing;
  final double progress;      // 0.0–1.0
  final String statusText;
  final double storageMb;
  final bool hasSynced;

  const OfflineSyncState({
    this.isSyncing = false,
    this.progress = 0,
    this.statusText = '',
    this.storageMb = 0,
    this.hasSynced = false,
  });

  OfflineSyncState copyWith({
    bool? isSyncing,
    double? progress,
    String? statusText,
    double? storageMb,
    bool? hasSynced,
  }) =>
      OfflineSyncState(
        isSyncing: isSyncing ?? this.isSyncing,
        progress: progress ?? this.progress,
        statusText: statusText ?? this.statusText,
        storageMb: storageMb ?? this.storageMb,
        hasSynced: hasSynced ?? this.hasSynced,
      );
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class OfflineSyncNotifier extends StateNotifier<OfflineSyncState> {
  final Ref _ref;

  OfflineSyncNotifier(this._ref) : super(const OfflineSyncState()) {
    _init();
  }

  Future<void> _init() async {
    final mb = await offlineSyncService.storageMb();
    final synced = offlineSyncService.hasSyncedContent;
    state = state.copyWith(storageMb: mb, hasSynced: synced);

    // Register callbacks to sync service
    offlineSyncService.registerCurationsCallback(() async {
      final result = await _ref.read(curationsProvider(null).future);
      return result;
    });

    // Wire up ValueNotifier listeners
    offlineSyncService.syncProgress.addListener(_onProgress);
    offlineSyncService.syncStatus.addListener(_onStatus);
  }

  void _onProgress() {
    state = state.copyWith(
      progress: offlineSyncService.syncProgress.value,
      isSyncing: offlineSyncService.isSyncing,
    );
  }

  void _onStatus() {
    state = state.copyWith(statusText: offlineSyncService.syncStatus.value);
  }

  Future<void> startSync() async {
    state = state.copyWith(isSyncing: true, progress: 0);
    final ok = await offlineSyncService.syncAll();
    final mb = await offlineSyncService.storageMb();
    state = state.copyWith(
      isSyncing: false,
      hasSynced: ok,
      storageMb: mb,
    );
  }

  Future<void> clearDownloads() async {
    await offlineSyncService.clearDownloads();
    state = state.copyWith(
      hasSynced: false,
      storageMb: 0,
      progress: 0,
      statusText: '',
    );
  }

  @override
  void dispose() {
    offlineSyncService.syncProgress.removeListener(_onProgress);
    offlineSyncService.syncStatus.removeListener(_onStatus);
    super.dispose();
  }
}

final offlineSyncProvider =
    StateNotifierProvider<OfflineSyncNotifier, OfflineSyncState>(
  (ref) => OfflineSyncNotifier(ref),
);

// ── Storage size string helper ───────────────────────────────────────────────

String formatStorageMb(double mb) {
  if (mb < 0.1) return '0 MB';
  if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
  return '${(mb / 1024).toStringAsFixed(2)} GB';
}
