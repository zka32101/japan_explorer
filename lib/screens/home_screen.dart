import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/curation.dart';
import '../providers/auth_provider.dart';
import '../providers/curations_provider.dart';
import '../providers/language_provider.dart';
import '../widgets/curation_card.dart';
import '../widgets/season_banner.dart';
import '../widgets/streak_widget.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/offline_banner.dart';
import '../config/theme.dart';
import '../utils/constants.dart';
import '../providers/streak_provider.dart';
import '../providers/daily_culture_provider.dart';
import '../widgets/daily_culture_card.dart';
import 'vision_cache_history_screen.dart';

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
      ref.read(streakNotifierProvider.notifier).checkAndUpdateStreak();
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
      ref.read(curationsNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appUserProvider).valueOrNull;
    final curationsState = ref.watch(curationsNotifierProvider);

    return Scaffold(
      body: OfflineAwarePage(
        child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildAppBar(user?.displayName),
          if (user != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    StreakWidget(streakDays: user.streakDays, compact: true),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => context.push(AppRoutes.seasonEvents),
                      icon: const Text('🌸', style: TextStyle(fontSize: 14)),
                      label: Text(tr('home.nav_seasons')),
                    ),
                    TextButton.icon(
                      onPressed: () => context.go('/phrases'),
                      icon: const Text('🇯🇵', style: TextStyle(fontSize: 14)),
                      label: Text(tr('home.nav_phrases')),
                    ),
                    TextButton.icon(
                      onPressed: () => context.push('/hosts'),
                      icon: const Text('🤝', style: TextStyle(fontSize: 14)),
                      label: Text(tr('home.nav_locals')),
                    ),
                    TextButton.icon(
                      onPressed: () => context.go('/home/ranking'),
                      icon: const Icon(Icons.leaderboard, size: 16),
                      label: Text(tr('home.nav_rankings')),
                    ),
                    TextButton.icon(
                      onPressed: () => context.push(AppRoutes.whatIsThis),
                      icon: const Text('❓', style: TextStyle(fontSize: 14)),
                      label: Text(tr('home.nav_what')),
                    ),
                    TextButton.icon(
                      onPressed: () => context.push(AppRoutes.menuTranslator),
                      icon: const Text('🍽️', style: TextStyle(fontSize: 14)),
                      label: Text(tr('home.nav_menu')),
                    ),
                    TextButton.icon(
                      onPressed: () => context.push(AppRoutes.cultureHub),
                      icon: const Text('📚', style: TextStyle(fontSize: 14)),
                      label: Text(tr('home.nav_learn')),
                    ),
                    TextButton.icon(
                      onPressed: () => context.push(AppRoutes.collection),
                      icon: const Text('🗂️', style: TextStyle(fontSize: 14)),
                      label: Text(tr('home.nav_collection')),
                    ),
                  ],
                ),
              ),
            ),
          // ── Season banner ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: SeasonBanner(),
          ),
          // ── Daily culture card ─────────────────────────────────────
          const SliverToBoxAdapter(
            child: DailyCultureCard(),
          ),
          // ── Daily challenge CTA ────────────────────────────────────
          SliverToBoxAdapter(
            child: GestureDetector(
              onTap: () => context.push(AppRoutes.challenge),
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
                    const Text('🧠', style: TextStyle(fontSize: 22)),
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
            ),
          ),
          _buildCategoryFilter(),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/camera'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.camera_alt, color: Colors.white),
        label: Text(tr('home.ai_lens_label'), style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildAppBar(String? name) {
    return SliverAppBar(
      floating: true,
      expandedHeight: 100,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name != null ? tr('home.greeting', args: [name]) : tr('app_name'),
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            Text(
              tr('home.title'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      actions: [
        Consumer(
          builder: (context, ref, _) {
            final language = ref.watch(languageProvider);
            return PopupMenuButton<Language>(
              onSelected: (lang) {
                ref.read(languageProvider.notifier).setLanguage(lang);
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<Language>(
                  value: Language.ja,
                  child: Row(
                    children: [
                      Text(Language.ja.displayName),
                      if (language == Language.ja)
                        const SizedBox(width: 8, child: Icon(Icons.check, size: 18)),
                    ],
                  ),
                ),
                PopupMenuItem<Language>(
                  value: Language.en,
                  child: Row(
                    children: [
                      Text(Language.en.displayName),
                      if (language == Language.en)
                        const SizedBox(width: 8, child: Icon(Icons.check, size: 18)),
                    ],
                  ),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Center(
                  child: Text(
                    language == Language.ja ? '日本語' : 'EN',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    final categories = [tr('home.category_all'), ...CurationCategory.all];
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 48,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final cat = index == 0 ? null : categories[index];
            final label = index == 0
                ? tr('home.category_all')
                : '${CurationCategory.emoji(categories[index])} ${CurationCategory.label(categories[index])}';
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
