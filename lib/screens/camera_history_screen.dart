import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../config/theme.dart';
import '../models/scan_history.dart';

final _scanHistoryProvider = FutureProvider<List<ScanRecord>>((ref) async {
  return scanHistoryRepository.getAll();
});

class CameraHistoryScreen extends ConsumerWidget {
  const CameraHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(_scanHistoryProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.history, color: AppColors.accent, size: 18),
            const SizedBox(width: 8),
            Text(tr('camera.scan_history')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(tr('settings.clear_scan_history_title')),
                  content: Text(tr('settings.clear_scan_history_body')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(tr('common.cancel')),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(tr('settings.clear'),
                          style: const TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await scanHistoryRepository.clear();
                ref.invalidate(_scanHistoryProvider);
              }
            },
            child: Text(tr('settings.clear'),
                style: const TextStyle(color: Colors.white54)),
          ),
        ],
      ),
      body: historyAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        error: (e, _) => Center(
          child: Text(tr('camera.failed_load_history'),
              style: const TextStyle(color: Colors.white54)),
        ),
        data: (records) => records.isEmpty
            ? _buildEmpty()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: records.length,
                itemBuilder: (context, index) => _ScanCard(
                  record: records[index],
                  onDelete: () async {
                    await scanHistoryRepository.delete(records[index].id);
                    ref.invalidate(_scanHistoryProvider);
                  },
                  onTap: () => _showDetail(context, records[index]),
                ),
              ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_camera_outlined, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            tr('camera.no_scans_yet'),
            style: const TextStyle(color: Colors.white54, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            tr('camera.no_scans_hint'),
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, ScanRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ScanDetailSheet(record: record),
    );
  }
}

class _ScanCard extends StatelessWidget {
  final ScanRecord record;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _ScanCard({
    required this.record,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage =
        record.imagePath != null && File(record.imagePath!).existsSync();
    final providerColor = record.provider == 'gemini'
        ? const Color(0xFF4285F4)
        : AppColors.accent;
    final providerLabel =
        record.provider == 'gemini' ? 'Gemini' : 'Claude';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF252525),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Image thumbnail
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(16)),
              child: SizedBox(
                width: 80,
                height: 80,
                child: hasImage
                    ? Image.file(File(record.imagePath!), fit: BoxFit.cover)
                    : Container(
                        color: Colors.white10,
                        child: const Icon(Icons.image_outlined,
                            color: Colors.white24, size: 32),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.landmarkName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.description,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: providerColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            providerLabel,
                            style: TextStyle(
                                color: providerColor, fontSize: 10),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(record.scannedAt),
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Delete
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.white24, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return tr('camera.today');
    if (diff.inDays == 1) return tr('camera.yesterday');
    if (diff.inDays < 7) {
      return tr('common.days_ago', args: ['${diff.inDays}']);
    }
    return '${dt.month}/${dt.day}';
  }
}

class _ScanDetailSheet extends StatelessWidget {
  final ScanRecord record;

  const _ScanDetailSheet({required this.record});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            record.landmarkName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _Section(tr('detail.about'), record.description),
          _Section(tr('what_is_this.history'), record.historicalBackground),
          _Section(
              tr('what_is_this.how_to_experience'), record.howToExperience),
          if (record.phraseJapanese.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🗣️ ${tr('camera.useful_japanese')}',
                      style: const TextStyle(
                          color: AppColors.sakura,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(record.phraseJapanese,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 20)),
                  Text(record.phraseRomaji,
                      style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text(record.phraseEnglish,
                      style: const TextStyle(color: Colors.white54)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String content;
  const _Section(this.title, this.content);

  @override
  Widget build(BuildContext context) {
    if (content.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8)),
        const SizedBox(height: 4),
        Text(content,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, height: 1.6)),
        const SizedBox(height: 16),
      ],
    );
  }
}
