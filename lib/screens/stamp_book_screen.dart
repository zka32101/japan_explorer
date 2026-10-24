import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showglobe_core/showglobe_core.dart'
    show
        RegionTileMap,
        ShareCardLabels,
        StampBadge,
        StampBookShareCard,
        VisitRecord,
        YearSummaryShareCard,
        firstVisitByRegion,
        showShareCardSheet,
        summarizeYear,
        visitedRegionIds;

import '../config/app_brand.dart';
import '../config/theme.dart';
import '../data/japan_regions.dart';
import '../providers/visits_provider.dart';
import '../widgets/theme/app_icons.dart';
import '../widgets/theme/brand_scaffold.dart';

/// スタンプ帳: 日記を書いた場所の都道府県が色づくタイルマップ、集めたスタンプ、
/// 年間まとめ。どれもカードにして共有できる。
class StampBookScreen extends ConsumerStatefulWidget {
  const StampBookScreen({super.key});

  @override
  ConsumerState<StampBookScreen> createState() => _StampBookScreenState();
}

class _StampBookScreenState extends ConsumerState<StampBookScreen> {
  int? _year;

  @override
  Widget build(BuildContext context) {
    final visits = ref.watch(visitRecordsProvider);
    return BrandScaffold(
      title: tr('stamps.title'),
      body: visits.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (records) =>
            records.isEmpty ? const _Empty() : _content(context, records),
      ),
    );
  }

  Widget _content(BuildContext context, List<VisitRecord> records) {
    final visited = visitedRegionIds(records)
        .where((id) => japanRegions.any((r) => r.id == id))
        .toSet();
    final first = firstVisitByRegion(records);
    final stamped = visited.toList()
      ..sort((a, b) => first[b]!.compareTo(first[a]!)); // 新しい順
    final years = records.map((r) => r.visitedAt.year).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    final year = years.contains(_year) ? _year! : years.first;
    final summary = summarizeYear(records, year);
    final labels = ShareCardLabels.localized();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(
          tr('stamps.visited_of',
              args: ['${visited.length}', '${japanRegions.length}']),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        RegionTileMap(
          regions: japanRegions,
          visitedIds: visited,
          color: AppColors.primary,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => showShareCardSheet(
            context,
            labels: labels,
            subject: tr('stamps.title'),
            shareText: '${tr('stamps.title')} · ${tripBrand.displayName}',
            cardBuilder: (_, style) => StampBookShareCard(
              style: style,
              brand: tripBrand,
              regions: japanRegions,
              visits: records,
              labels: labels,
            ),
          ),
          icon: const Icon(Icons.ios_share),
          label: Text(tr('stamps.share_book')),
        ),
        const SizedBox(height: 24),
        Text(tr('stamps.collected'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final id in stamped)
              StampBadge(
                label: japanRegions.firstWhere((r) => r.id == id).label,
                color: AppColors.primary,
                date: _ymd(first[id]!),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text(tr('stamps.year_section'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final y in years)
              ChoiceChip(
                label: Text('$y'),
                selected: y == year,
                onSelected: (_) => setState(() => _year = y),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          tr('stamps.year_numbers', args: [
            '${summary.spotCount}',
            '${summary.regionCount}',
          ]),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => showShareCardSheet(
            context,
            labels: labels,
            subject: tr('stamps.year_section'),
            shareText: '${tr('stamps.year_section')} · ${tripBrand.displayName}',
            cardBuilder: (_, style) => YearSummaryShareCard(
              style: style,
              brand: tripBrand,
              summary: summary,
              labels: labels,
            ),
          ),
          icon: const Icon(Icons.ios_share),
          label: Text(tr('stamps.share_year')),
        ),
      ],
    );
  }

  static String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppIconChip(AppGlyph.trophy, size: 88),
            const SizedBox(height: 20),
            Text(tr('stamps.empty_title'),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              tr('stamps.empty_hint'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
