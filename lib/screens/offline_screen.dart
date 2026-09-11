import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/offline_provider.dart';

class OfflineScreen extends ConsumerWidget {
  const OfflineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(offlineSyncProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('offline.title')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _StorageCard(state: state),
          const SizedBox(height: 20),
          _SyncCard(state: state, ref: ref),
          const SizedBox(height: 20),
          _WhatIsAvailableCard(),
          const SizedBox(height: 20),
          if (state.hasSynced)
            _ClearButton(ref: ref),
        ],
      ),
    );
  }
}

// ── Storage Card ─────────────────────────────────────────────────────────────

class _StorageCard extends StatelessWidget {
  final OfflineSyncState state;
  const _StorageCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.storage_outlined,
                  color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('offline.storage_used'),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(
                    formatStorageMb(state.storageMb),
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ),
            if (state.hasSynced)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle,
                        size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(tr('offline.synced'),
                        style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                            fontSize: 12)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Sync Card ────────────────────────────────────────────────────────────────

class _SyncCard extends StatelessWidget {
  final OfflineSyncState state;
  final WidgetRef ref;
  const _SyncCard({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.download_outlined, color: AppColors.primary),
                const SizedBox(width: 10),
                Text(tr('offline.download_title'),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tr('offline.download_subtitle'),
              style: const TextStyle(
                  color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),

            // Progress bar (visible during sync)
            if (state.isSyncing) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: state.progress,
                  minHeight: 8,
                  backgroundColor:
                      AppColors.primary.withValues(alpha: 0.12),
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              const SizedBox(height: 8),
              Text(state.statusText,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 12),
            ] else if (state.statusText.isNotEmpty) ...[
              Text(state.statusText,
                  style: TextStyle(
                      color: state.statusText.startsWith('Done')
                          ? Colors.green
                          : AppColors.textSecondary,
                      fontSize: 13)),
              const SizedBox(height: 12),
            ],

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: state.isSyncing
                    ? null
                    : () =>
                        ref.read(offlineSyncProvider.notifier).startSync(),
                icon: state.isSyncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.sync),
                label: Text(state.hasSynced
                    ? tr('offline.resync')
                    : tr('offline.start_sync')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── What's available card ────────────────────────────────────────────────────

class _WhatIsAvailableCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.location_on_outlined, 'offline.available_spots'),
      (Icons.record_voice_over_outlined, 'offline.available_phrases'),
      (Icons.wb_sunny_outlined, 'offline.available_seasons'),
      (Icons.map_outlined, 'offline.available_planner'),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('offline.available_title'),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Icon(item.$1,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(tr(item.$2),
                            style: const TextStyle(fontSize: 14)),
                      ),
                      const Icon(Icons.check,
                          size: 16, color: Colors.green),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// ── Clear Button ─────────────────────────────────────────────────────────────

class _ClearButton extends StatelessWidget {
  final WidgetRef ref;
  const _ClearButton({required this.ref});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red),
        minimumSize: const Size(double.infinity, 48),
      ),
      onPressed: () async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(tr('offline.clear_title')),
            content: Text(tr('offline.clear_confirm')),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(tr('common.cancel'))),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(tr('offline.clear_btn'),
                      style: const TextStyle(color: Colors.red))),
            ],
          ),
        );
        if (ok == true) {
          await ref.read(offlineSyncProvider.notifier).clearDownloads();
        }
      },
      icon: const Icon(Icons.delete_outline),
      label: Text(tr('offline.clear_btn')),
    );
  }
}
