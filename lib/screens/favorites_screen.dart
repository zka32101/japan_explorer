import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../utils/favorites_view.dart';
import '../services/firebase_service.dart';
import '../providers/auth_provider.dart';
import '../utils/trip_planner.dart';
import '../config/theme.dart';
import '../models/curation.dart';
import '../providers/favorites_provider.dart';
import '../providers/plan_provider.dart';
import '../widgets/theme/app_icons.dart';
import '../widgets/theme/brand_scaffold.dart';

/// Spots the user saved ("行きたい場所"), with filtering, sorting, per-spot
/// memos and a shortcut to turn them into a trip plan.
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  String? _category;
  FavoriteSort _sort = FavoriteSort.newest;

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(favoriteCurationsProvider);
    final notes = ref.watch(favoriteNotesProvider);
    final ids = ref.watch(favoriteIdsProvider);

    return BrandScaffold(
      title: tr('favorites.title'),
      actions: [
        PopupMenuButton<FavoriteSort>(
          icon: const Icon(Icons.sort, color: Colors.white),
          onSelected: (v) => setState(() => _sort = v),
          itemBuilder: (_) => [
            CheckedPopupMenuItem(
              value: FavoriteSort.newest,
              checked: _sort == FavoriteSort.newest,
              child: Text(tr('favorites.sort_newest')),
            ),
            CheckedPopupMenuItem(
              value: FavoriteSort.area,
              checked: _sort == FavoriteSort.area,
              child: Text(tr('favorites.sort_area')),
            ),
          ],
        ),
      ],
      body: ids.isEmpty
          ? const _EmptyFavorites()
          : saved.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (all) {
                final categories = categoriesPresent(all);
                // A filter whose spots were all removed falls back to "all".
                final category = categories.contains(_category) ? _category : null;
                final shown = filterAndSortFavorites(all,
                    category: category, sort: _sort);
                return Stack(
                  children: [
                    Column(
                      children: [
                        if (categories.length > 1)
                          SizedBox(
                            height: 52,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              children: [
                                _chip(tr('favorites.filter_all'),
                                    category == null, () {
                                  setState(() => _category = null);
                                }),
                                for (final c in categories)
                                  _chip(
                                    '${CurationCategory.emoji(c)} ${CurationCategory.label(c)}',
                                    category == c,
                                    () => setState(() => _category = c),
                                  ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            itemCount: shown.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (_, i) => _FavoriteTile(
                              curation: shown[i],
                              note: notes[shown[i].id],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: FloatingActionButton.extended(
                        onPressed: shown.isEmpty
                            ? null
                            : () => _makePlan(context, ref, shown, notes),
                        icon: const Icon(Icons.event_note_outlined),
                        label: Text(tr('favorites.make_plan')),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(color: selected ? Colors.white : AppColors.onSurface),
        ),
      );

  /// Turns the currently shown spots into a plan (new, or added to one).
  Future<void> _makePlan(BuildContext context, WidgetRef ref,
      List<Curation> curations, Map<String, String> notes) async {
    final messenger = ScaffoldMessenger.of(context);
    final plans = ref.read(planNotifierProvider).valueOrNull ?? [];

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
      created = await _askNewPlan(context, curations.length);
      if (created == null || !context.mounted) return;
    }

    final notifier = ref.read(planNotifierProvider.notifier);
    if (created != null) {
      // Walkable order, split over the chosen number of days.
      await notifier.createPlanWithSpots(created.title,
          arrangeByRoute(curations, days: created.days, notes: notes));
    } else {
      await notifier.addSpotsToPlan(choice, [
        for (var i = 0; i < curations.length; i++)
          planSpotFromCuration(curations[i],
              order: i, note: notes[curations[i].id]),
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
  const _FavoriteTile({required this.curation, this.note});
  final Curation curation;
  final String? note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = curation;
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      '${CurationCategory.emoji(c.category)} ${c.prefecture}',
                      style: const TextStyle(
                          fontSize: kMinFontSize,
                          color: AppColors.textSecondary),
                    ),
                    if (note != null && note!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        note!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: kMinFontSize, color: AppColors.primary),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.edit_note,
                    color: (note ?? '').isEmpty
                        ? AppColors.textSecondary
                        : AppColors.primary,
                  ),
                  tooltip: tr('favorites.note_title'),
                  onPressed: () => _editNote(context, ref),
                ),
                IconButton(
                  icon: const Icon(Icons.bookmark, color: AppColors.primary),
                  onPressed: () => toggleFavorite(context, ref, c.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editNote(BuildContext context, WidgetRef ref) async {
    final user = ref.read(appUserProvider).valueOrNull;
    if (user == null) return;
    final controller = TextEditingController(text: note ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr('favorites.note_title')),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          maxLength: 120,
          decoration: InputDecoration(hintText: tr('favorites.note_hint')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(tr('favorites.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: Text(tr('favorites.save')),
          ),
        ],
      ),
    );
    if (result == null) return;
    await ref
        .read(firebaseServiceProvider)
        .setFavoriteNote(user.uid, curation.id, result);
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
