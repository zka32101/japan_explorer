import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../utils/trip_planner.dart';
import '../config/theme.dart';
import '../models/curation.dart';
import '../providers/curations_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/plan_provider.dart';
import '../widgets/theme/app_icons.dart';
import '../widgets/theme/brand_scaffold.dart';

/// Spots the user saved ("行きたい場所"), with a shortcut to turn them into a
/// trip plan.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(favoriteIdsProvider);

    return BrandScaffold(
      title: tr('favorites.title'),
      floatingActionButton: ids.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _makePlan(context, ref, ids),
              icon: const Icon(Icons.event_note_outlined),
              label: Text(tr('favorites.make_plan')),
            ),
      body: ids.isEmpty
          ? const _EmptyFavorites()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: ids.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              // Newest first.
              itemBuilder: (_, i) => _FavoriteTile(id: ids[ids.length - 1 - i]),
            ),
    );
  }

  Future<void> _makePlan(
      BuildContext context, WidgetRef ref, List<String> ids) async {
    final messenger = ScaffoldMessenger.of(context);
    final plans = ref.read(planNotifierProvider).valueOrNull ?? [];

    // Pick the destination: a new plan or one of the existing plans.
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('favorites.sheet_title'),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.add_circle_outline,
                    color: AppColors.primary),
                title: Text(tr('favorites.new_plan')),
                onTap: () => Navigator.pop(sheetContext, ''),
              ),
              for (final p in plans)
                ListTile(
                  leading: const Icon(Icons.map_outlined,
                      color: AppColors.primary),
                  title: Text(p.title),
                  subtitle:
                      Text(tr('detail.spots_count', args: ['${p.spots.length}'])),
                  onTap: () => Navigator.pop(sheetContext, p.id),
                ),
            ],
          ),
        ),
      ),
    );
    if (choice == null || !context.mounted) return;

    ({String title, int days})? created;
    if (choice.isEmpty) {
      created = await _askNewPlan(context, ids.length);
      if (created == null || !context.mounted) return;
    }

    final curations = <Curation>[];
    for (final id in ids) {
      final c = await ref.read(curationDetailProvider(id).future);
      if (c != null) curations.add(c);
    }
    final notifier = ref.read(planNotifierProvider.notifier);
    if (created != null) {
      // Walkable order, split over the chosen number of days.
      await notifier.createPlanWithSpots(
          created.title, arrangeByRoute(curations, days: created.days));
    } else {
      await notifier.addSpotsToPlan(choice, [
        for (var i = 0; i < curations.length; i++)
          planSpotFromCuration(curations[i], order: i),
      ]);
    }
    messenger.showSnackBar(SnackBar(
      content: Text(
          tr(choice.isEmpty ? 'favorites.plan_created' : 'favorites.plan_updated')),
    ));
    if (context.mounted) context.go('/my-plan');
  }

  Future<({String title, int days})?> _askNewPlan(
      BuildContext context, int spotCount) {
    final controller =
        TextEditingController(text: tr('favorites.default_plan_title'));
    var days = 1;
    final maxDays = spotCount.clamp(1, 7);
    return showDialog<({String title, int days})>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(tr('favorites.new_plan')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration:
                    InputDecoration(labelText: tr('favorites.plan_name')),
              ),
              if (maxDays > 1) ...[
                const SizedBox(height: 16),
                Text(tr('favorites.days_label')),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (var d = 1; d <= maxDays; d++)
                      ChoiceChip(
                        label: Text('$d'),
                        selected: days == d,
                        onSelected: (_) => setState(() => days = d),
                      ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(tr('favorites.cancel')),
            ),
            FilledButton(
              onPressed: () {
                final t = controller.text.trim();
                Navigator.pop(dialogContext, (
                  title: t.isEmpty ? tr('favorites.default_plan_title') : t,
                  days: days,
                ));
              },
              child: Text(tr('favorites.create')),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteTile extends ConsumerWidget {
  const _FavoriteTile({required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final curation = ref.watch(curationDetailProvider(id));
    return curation.when(
      loading: () => const SizedBox(
        height: 72,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (c) {
        if (c == null) return const SizedBox.shrink();
        return Card(
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          child: InkWell(
            onTap: () => context.push('/home/detail/${c.id}'),
            child: Row(
              children: [
                SizedBox(
                  width: 88,
                  height: 88,
                  child: c.imageUrls.isEmpty
                      ? Container(
                          color: AppColors.divider,
                          child: const Icon(Icons.image,
                              color: AppColors.textSecondary),
                        )
                      : CachedNetworkImage(
                          imageUrl: c.imageUrls.first,
                          fit: BoxFit.cover,
                          memCacheWidth: 300,
                          errorWidget: (_, _, _) =>
                              Container(color: AppColors.divider),
                        ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          c.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          c.prefecture,
                          style: const TextStyle(
                              fontSize: kMinFontSize,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.bookmark, color: AppColors.primary),
                  onPressed: () => toggleFavorite(context, ref, c.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppIconChip(AppGlyph.map, size: 88),
            const SizedBox(height: 20),
            Text(tr('favorites.empty_title'),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              tr('favorites.empty_hint'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
