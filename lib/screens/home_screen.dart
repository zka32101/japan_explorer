import 'dart:async';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/favorites_provider.dart';
import '../models/curation.dart';
import '../providers/auth_provider.dart';
import '../providers/curations_provider.dart';
import '../providers/language_provider.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/curation_card.dart';
import '../widgets/season_banner.dart';
import '../widgets/streak_widget.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/offline_banner.dart';
import '../config/theme.dart';
import '../utils/constants.dart';
import '../providers/streak_provider.dart';
import '../widgets/daily_culture_card.dart';
import '../widgets/theme/app_icons.dart';
import '../widgets/theme/brand_header.dart';
import '../widgets/theme/paper_background.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollController = ScrollController();
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Update streak on every home screen open (debounced inside provider)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(streakNotifierProvider.notifier).checkAndUpdateStreak());
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      unawaited(ref.read(curationsNotifierProvider.notifier).loadMore());
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appUserProvider).valueOrNull;
    final curationsState = ref.watch(curationsNotifierProvider);
    final isLearner = ref.watch(usageGoalProvider) == 'learn';

    // ── Daily culture card ─────────────────────────────────────────────────
    const dailyCultureSliver = SliverToBoxAdapter(
      child: RepaintBoundary(
        child: DailyCultureCard(),
      ),
    );

    // ── Season banner ────────────────────────────────────────────────────
    const seasonBannerSliver = SliverToBoxAdapter(
      child: RepaintBoundary(
        child: SeasonBanner(),
      ),
    );

    // ── Daily challenge CTA ──────────────────────────────────────────────
    final dailyChallengeSliver = SliverToBoxAdapter(
      child: RepaintBoundary(
        child: _DailyChallengeCard(onTap: () => context.push(AppRoutes.challenge)),
      ),
    );

    // Learners get culture content first, with a prominent Culture Hub CTA;
    // travelers keep the original spot-focused order.
    final middleSlivers = isLearner
        ? [
            dailyCultureSliver,
            SliverToBoxAdapter(
              child: RepaintBoundary(
                child: _LearnCultureCard(
                  onTap: () => context.push(AppRoutes.cultureHub),
                ),
              ),
            ),
            dailyChallengeSliver,
            seasonBannerSliver,
          ]
        : [
            seasonBannerSliver,
            dailyCultureSliver,
            dailyChallengeSliver,
          ];

    return Scaffold(
      body: PaperBackground(
        child: OfflineAwarePage(
        child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(user?.displayName)),
          const SliverToBoxAdapter(child: _SearchEntry()),
          if (user != null)
            SliverToBoxAdapter(
              child: RepaintBoundary(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      StreakWidget(streakDays: user.streakDays, compact: true),
                    ],
                  ),
                ),
              ),
            ),
          const SliverToBoxAdapter(
            child: RepaintBoundary(child: _QuickMenu()),
          ),
          ...middleSlivers,
          if (isLearner)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Text(
                  tr('home.spots_section_title'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          _buildCategoryFilter(),
          // ── Curations list (repaint boundary) ──────────────────────
          curationsState.when(
            loading: () => const CurationListSkeleton(count: 3),
            error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, size: 48, color: AppColors.textSecondary),
                      const SizedBox(height: 16),
                      Text(
                        tr('home.error_load_title'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tr('home.error_load_subtitle'),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () => ref
                            .read(curationsNotifierProvider.notifier)
                            .loadInitial(),
                        icon: const Icon(Icons.refresh),
                        label: Text(tr('common.retry')),
                      ),
                    ],
                  ),
                ),
              ),
            data: (curations) => _buildCurationsList(curations),
          ),
        ],
      ),
      ),
      ),
      floatingActionButton: AppConstants.aiLensEnabled
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/camera'),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.camera_alt, color: Colors.white),
              label: Text(tr('home.ai_lens_label'),
                  style: const TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  Widget _buildHeader(String? name) {
    return BrandHeader(
      height: 170,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: BrandHeaderTitle(
              subtitle:
                  name == null ? tr('app_name') : tr('home.greeting', args: [name]),
              title: tr('home.title'),
            ),
          ),
          Consumer(
            builder: (context, ref, _) {
              final language = ref.watch(languageProvider);
              return PopupMenuButton<Language>(
                onSelected: (lang) {
                  ref.read(languageProvider.notifier).setLanguage(lang);
                },
                itemBuilder: (BuildContext context) => [
                  for (final lang in Language.values)
                    PopupMenuItem<Language>(
                      value: lang,
                      child: Row(
                        children: [
                          Text('${lang.flag} ${lang.displayName}'),
                          if (language == lang)
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Icon(Icons.check, size: 18),
                            ),
                        ],
                      ),
                    ),
                ],
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Text(
                    language.displayName,
                    style: const TextStyle(
                      fontSize: kMinFontSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = CurationCategory.all;
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 48,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length + 1,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final cat = index == 0 ? null : categories[index - 1];
            final label = index == 0
                ? tr('home.category_all')
                : '${CurationCategory.emoji(categories[index - 1])} ${CurationCategory.label(categories[index - 1])}';
            final isSelected = _selectedCategory == cat;

            return FilterChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedCategory = cat);
                ref
                    .read(curationsNotifierProvider.notifier)
                    .filterByCategory(cat);
              },
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.onSurface,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCurationsList(List<Curation> curations) {
    if (curations.isEmpty) {
      return SliverFillRemaining(
        child: Center(child: Text(tr('home.no_spots_found'))),
      );
    }

    final notifier = ref.read(curationsNotifierProvider.notifier);
    final favorites = ref.watch(favoriteIdsProvider).toSet();

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == curations.length) {
              return notifier.hasMore
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                          child:
                              CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          tr('home.all_spots_seen'),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
            }
            final curation = curations[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: CurationCard(
                curation: curation,
                isSaved: favorites.contains(curation.id),
                onSave: () => toggleFavorite(context, ref, curation.id),
                onTap: () => context.go('/home/detail/${curation.id}'),
              ),
            );
          },
          childCount: curations.length + 1,
        ),
      ),
    );
  }
}

/// Tappable search field under the app bar. Search is no longer a bottom tab;
/// it opens the search screen (back returns to Home).
class _SearchEntry extends StatelessWidget {
  const _SearchEntry();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => context.push(AppRoutes.search),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const AppIcon(AppGlyph.search, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr('search.hint'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Entry points to the app's features, grouped by what the traveller wants to
/// do. Replaces a single overflowing row of text buttons; every destination is
/// pushed so the back button returns to Home.
class _QuickMenu extends StatelessWidget {
  const _QuickMenu();

  @override
  Widget build(BuildContext context) {
    final items = <_QuickMenuItem>[
      if (AppConstants.aiLensEnabled)
        _QuickMenuItem(AppGlyph.lens, 'home.nav_what', () => context.push(AppRoutes.whatIsThis)),
      _QuickMenuItem(AppGlyph.bowl, 'home.nav_menu', () => context.push(AppRoutes.menuTranslator)),
      _QuickMenuItem(AppGlyph.globe, 'home.nav_phrases', () => context.push(AppRoutes.phrases)),
      _QuickMenuItem(AppGlyph.book, 'home.nav_learn', () => context.push(AppRoutes.cultureHub)),
      _QuickMenuItem(AppGlyph.sakura, 'home.nav_seasons', () => context.push(AppRoutes.seasonEvents)),
      _QuickMenuItem(AppGlyph.plan, 'home.nav_collection', () => context.push(AppRoutes.collection)),
      _QuickMenuItem(AppGlyph.people, 'home.nav_locals', () => context.push(AppRoutes.hosts)),
      _QuickMenuItem(AppGlyph.trophy, 'home.nav_rankings', () => context.push('/home/ranking')),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 0.95,
        children: [for (final item in items) _QuickMenuTile(item: item)],
      ),
    );
  }
}

class _QuickMenuItem {
  final AppGlyph glyph;
  final String label;
  final VoidCallback onTap;
  const _QuickMenuItem(this.glyph, this.label, this.onTap);
}

class _QuickMenuTile extends StatelessWidget {
  final _QuickMenuItem item;
  const _QuickMenuTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIconChip(item.glyph, size: 44),
          const SizedBox(height: 4),
          Text(
            tr(item.label),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _LearnCultureCard extends StatelessWidget {
  final VoidCallback onTap;

  const _LearnCultureCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const AppIcon(AppGlyph.book, size: 24, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('home.learn_card_title'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    tr('home.learn_card_subtitle'),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }
}

class _DailyChallengeCard extends StatelessWidget {
  final VoidCallback onTap;

  const _DailyChallengeCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const AppIcon(AppGlyph.lens, size: 24, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('challenge.title'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    tr('home.challenge_subtitle'),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }
}
