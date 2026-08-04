import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/vision_cache_provider.dart';

class VisionCacheHistoryScreen extends ConsumerWidget {
  const VisionCacheHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(visionCacheHistoryProvider);
    final cacheSize = ref.watch(visionCacheSizeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('vision_cache.title')),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showClearDialog(context, ref),
            ),
        ],
      ),
      body: history.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStorageCard(cacheSize),
                  const SizedBox(height: 16),
                  _buildHistoryList(history),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            tr('vision_cache.empty'),
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageCard(AsyncValue<double> cacheSizeAsync) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: cacheSizeAsync.when(
        data: (size) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('vision_cache.storage'),
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${size.toStringAsFixed(2)} MB',
              style: Theme.of(null!).textTheme.headlineSmall?.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        loading: () => const CircularProgressIndicator(),
        error: (err, st) => Text(tr('myplan.error_prefix', args: ['$err'])),
      ),
    );
  }

  Widget _buildHistoryList(List<CachedAnalysis> history) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('vision_cache.analyses_count', args: ['${history.length}']),
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...history.map((item) => _buildHistoryItem(item)).toList(),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(CachedAnalysis item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getIconForType(item.analysisType),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.analysisType == 'what_is_this'
                            ? tr('what_is_this.title')
                            : tr('menu_translator.title'),
                        style: Theme.of(null!).textTheme.titleSmall,
                      ),
                      Text(
                        _formatDate(item.cachedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (File(item.imagePath).existsSync())
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      image: DecorationImage(
                        image: FileImage(File(item.imagePath)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _getIconForType(String type) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          type == 'what_is_this' ? '❓' : '🍽️',
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return tr('vision_cache.time_min_ago', args: ['${diff.inMinutes}']);
    } else if (diff.inHours < 24) {
      return tr('vision_cache.time_hour_ago', args: ['${diff.inHours}']);
    } else if (diff.inDays < 7) {
      return tr('vision_cache.time_day_ago', args: ['${diff.inDays}']);
    } else {
      return DateFormat('MMM dd').format(date);
    }
  }

  void _showClearDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('vision_cache.clear_dialog_title')),
        content: Text(tr('vision_cache.clear_dialog_content')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('common.cancel')),
          ),
          TextButton(
            onPressed: () {
              ref.read(visionCacheHistoryProvider.notifier).clearAll();
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(tr('vision_cache.clear_all')),
          ),
        ],
      ),
    );
  }
}
