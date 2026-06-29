import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../models/culture_content.dart';
import '../providers/daily_culture_provider.dart';
import '../services/culture_content_seeder.dart';

class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});

  static const _categories = [
    ('culture',  '🏮', 'Culture'),
    ('food',     '🍱', 'Food'),
    ('region',   '🗾', 'Regions'),
    ('art',      '🎨', 'Art'),
    ('language', '📖', 'Language'),
    ('sport',    '🥋', 'Martial Arts'),
    ('regions',  '🗾', 'Regional'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readIds = ref.watch(cultureReadProvider);
    final notifier = ref.read(cultureReadProvider.notifier);
    final total = CultureContentSeeder.allContent.length;
    final readCount = readIds.length;
    final progress = total == 0 ? 0.0 : readCount / total;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Culture Collection'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/culture'),
            icon: const Icon(Icons.library_books, size: 16),
            label: const Text('Learn More'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Overall progress ──────────────────────────────────────────────
          _ProgressHeader(
            readCount: readCount,
            total: total,
            progress: progress,
          ),
          const SizedBox(height: 20),

          // ── Category breakdown ─────────────────────────────────────────────
          Text(
            'By Category',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ..._categories.map((cat) {
            final catRead = notifier.countForCategory(cat.$1);
            final catTotal = notifier.totalForCategory(cat.$1);
            if (catTotal == 0) return const SizedBox.shrink();
            return _CategoryRow(
              emoji: cat.$2,
              label: cat.$3,
              read: catRead,
              total: catTotal,
            );
          }),
          const SizedBox(height: 20),

          // ── Streak / motivation ────────────────────────────────────────────
          _MotivationCard(readCount: readCount, total: total),
          const SizedBox(height: 20),

          // ── Recently read ──────────────────────────────────────────────────
          if (notifier.recentlyRead.isNotEmpty) ...[
            Text(
              'Recently Read',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...notifier.recentlyRead.map((c) => _RecentReadItem(content: c)),
          ],
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _ProgressHeader extends StatelessWidget {
  final int readCount;
  final int total;
  final double progress;
  const _ProgressHeader({
    required this.readCount,
    required this.total,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📚', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$readCount / $total Articles Read',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}% of Japan Explorer complete',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _progressMessage(readCount),
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _progressMessage(int count) {
    if (count == 0) return '🌱 Start your Japan culture journey!';
    if (count < 10) return '🗾 You\'re just getting started — keep exploring!';
    if (count < 50) return '🏮 Growing your Japan knowledge — great work!';
    if (count < 100) return '⛩️ You\'re becoming a true Japan enthusiast!';
    if (count < 200) return '🎌 Impressive depth — a cultural ambassador!';
    if (count < 500) return '👘 You know more about Japan than most!';
    return '🏯 Japan Master — extraordinary cultural knowledge!';
  }
}

class _CategoryRow extends StatelessWidget {
  final String emoji;
  final String label;
  final int read;
  final int total;
  const _CategoryRow({
    required this.emoji,
    required this.label,
    required this.read,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : read / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const Spacer(),
              Text(
                '$read / $total',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppColors.surface,
              valueColor: AlwaysStoppedAnimation<Color>(
                pct >= 1.0 ? Colors.green : AppColors.primary,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _MotivationCard extends StatelessWidget {
  final int readCount;
  final int total;
  const _MotivationCard({required this.readCount, required this.total});

  @override
  Widget build(BuildContext context) {
    final next = _nextMilestone(readCount);
    final remaining = next - readCount;
    if (remaining <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Text('🎯', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next milestone: $next articles',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  '$remaining more to unlock your next badge',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _nextMilestone(int current) {
    const milestones = [10, 50, 100, 200, 500, 1000];
    return milestones.firstWhere(
      (m) => m > current,
      orElse: () => current + 100,
    );
  }
}

class _RecentReadItem extends ConsumerWidget {
  final CultureContent content;
  const _RecentReadItem({required this.content});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => context.push('/culture/${content.id}'),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  _categoryEmoji(content.categoryId),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    content.subtitle,
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.check_circle, color: Colors.green, size: 18),
          ],
        ),
      ),
    );
  }

  String _categoryEmoji(String categoryId) {
    switch (categoryId) {
      case 'culture': return '🏮';
      case 'food': return '🍱';
      case 'region': return '🗾';
      case 'regions': return '🗾';
      case 'art': return '🎨';
      case 'language': return '📖';
      case 'sport': return '🥋';
      default: return '🇯🇵';
    }
  }
}
