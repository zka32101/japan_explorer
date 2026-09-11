import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/curation.dart';
import '../providers/ranking_provider.dart';
import '../config/theme.dart';

class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(rankingFilterProvider);
    final rankingsAsync = ref.watch(rankingProvider(filter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rankings'),
      ),
      body: Column(
        children: [
          _buildFilterTabs(context, ref, filter),
          if (filter == RankingFilter.category) _buildCategoryPicker(ref),
          Expanded(
            child: rankingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (curations) => _buildList(context, curations),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(BuildContext context, WidgetRef ref, RankingFilter current) {
    final filters = [
      (RankingFilter.overall, 'Overall', Icons.leaderboard),
      (RankingFilter.weekly, 'Trending', Icons.trending_up),
      (RankingFilter.category, 'Category', Icons.category),
    ];

    return Container(
      color: AppColors.surface,
      child: Row(
        children: filters.map((f) {
          final isSelected = f.$1 == current;
          return Expanded(
            child: GestureDetector(
              onTap: () => ref.read(rankingFilterProvider.notifier).state = f.$1,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      f.$3,
                      size: 16,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      f.$2,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryPicker(WidgetRef ref) {
    final selected = ref.watch(rankingCategoryProvider);
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: CurationCategory.all.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = CurationCategory.all[i];
          final isSelected = selected == cat;
          return ChoiceChip(
            label: Text(
                '${CurationCategory.emoji(cat)} ${CurationCategory.label(cat)}'),
            selected: isSelected,
            onSelected: (_) =>
                ref.read(rankingCategoryProvider.notifier).state = cat,
            selectedColor: AppColors.primary,
            labelStyle:
                TextStyle(color: isSelected ? Colors.white : AppColors.onSurface),
          );
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Curation> curations) {
    if (curations.isEmpty) {
      return const Center(child: Text('No rankings available'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: curations.length,
      itemBuilder: (context, index) {
        final curation = curations[index];
        return _RankingTile(
          rank: index + 1,
          curation: curation,
          onTap: () => context.go('/home/detail/${curation.id}'),
        );
      },
    );
  }
}

class _RankingTile extends StatelessWidget {
  final int rank;
  final Curation curation;
  final VoidCallback onTap;

  const _RankingTile({
    required this.rank,
    required this.curation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rankColor = switch (rank) {
      1 => const Color(0xFFFFD700),
      2 => const Color(0xFFC0C0C0),
      3 => const Color(0xFFCD7F32),
      _ => AppColors.textSecondary,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: SizedBox(
          width: 40,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              rank <= 3
                  ? Text(
                      rank == 1 ? '🥇' : rank == 2 ? '🥈' : '🥉',
                      style: const TextStyle(fontSize: 24),
                    )
                  : Text(
                      '#$rank',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: rankColor,
                        fontSize: 16,
                      ),
                    ),
            ],
          ),
        ),
        title: Text(
          curation.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${curation.prefecture} · ${CurationCategory.emoji(curation.category)} ${CurationCategory.label(curation.category)}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star, size: 12, color: AppColors.primary),
                const SizedBox(width: 2),
                Text(
                  'Want: ${curation.averageWantToGo.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.recommend, size: 12, color: AppColors.secondary),
                const SizedBox(width: 2),
                Text(
                  'Rec: ${curation.averageRecommend.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.secondary),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
