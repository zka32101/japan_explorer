import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../models/season_event.dart';
import '../providers/season_events_provider.dart';

class SeasonEventsScreen extends ConsumerStatefulWidget {
  const SeasonEventsScreen({super.key});

  @override
  ConsumerState<SeasonEventsScreen> createState() =>
      _SeasonEventsScreenState();
}

class _SeasonEventsScreenState extends ConsumerState<SeasonEventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  SeasonType? _selectedSeason; // null = All

  static const _seasons = [
    null,                   // All
    SeasonType.spring,
    SeasonType.summer,
    SeasonType.autumn,
    SeasonType.winter,
    SeasonType.yearRound,
  ];

  static const _seasonLabels = [
    '🗾 All', '🌸 Spring', '☀️ Summer', '🍁 Autumn', '❄️ Winter', '✨ All Year',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _seasons.length, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) return;
      setState(() => _selectedSeason = _seasons[_tabCtrl.index]);
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeEvents = ref.watch(activeEventsProvider);
    final filteredEvents = ref.watch(eventsBySeasonProvider(_selectedSeason));

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('seasons.title')),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _seasonLabels
              .map((l) => Tab(text: l))
              .toList(),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // ── Happening Now ────────────────────────────────────────────────
          if (activeEvents.isNotEmpty && _selectedSeason == null) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tr('seasons.happening_now'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: activeEvents.length,
                  itemBuilder: (ctx, i) =>
                      _ActiveEventChip(event: activeEvents[i]),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Divider(height: 24),
            ),
          ],

          // ── Section heading ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                _selectedSeason == null
                    ? tr('seasons.all_events')
                    : _selectedSeason!.label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),

          // ── Event cards ──────────────────────────────────────────────────
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _EventCard(event: filteredEvents[i]),
              childCount: filteredEvents.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ── Active event horizontal chip ─────────────────────────────────────────────

class _ActiveEventChip extends StatelessWidget {
  const _ActiveEventChip({required this.event});
  final SeasonEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 148,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      constraints: const BoxConstraints(maxWidth: 148),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _seasonColor(event.season).withValues(alpha: 0.8),
            _seasonColor(event.season).withValues(alpha: 0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.emoji, style: const TextStyle(fontSize: 32)),
            const Spacer(),
            Text(
              event.title,
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              event.titleJa,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Event detail card ─────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});
  final SeasonEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final isActive = event.isActive(today);
    final color = _seasonColor(event.season);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: color.withValues(alpha: isActive ? 0.8 : 0.3),
                width: isActive ? 2 : 1),
          ),
          alignment: Alignment.center,
          child: Text(event.emoji,
              style: const TextStyle(fontSize: 22)),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(event.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold)),
            ),
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tr('seasons.now'),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 10),
                ),
              ),
          ],
        ),
        subtitle: Row(
          children: [
            Text(event.titleJa,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: color)),
            const SizedBox(width: 8),
            _SeasonChip(season: event.season),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.description,
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(event.tip,
                            style: theme.textTheme.bodySmall),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _DateRangeRow(event: event),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Date range row ────────────────────────────────────────────────────────────

class _DateRangeRow extends StatelessWidget {
  const _DateRangeRow({required this.event});
  final SeasonEvent event;

  @override
  Widget build(BuildContext context) {
    String dateStr;
    if (event.season == SeasonType.yearRound) {
      dateStr = tr('seasons.year_round');
    } else {
      final mNames = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      final s = '${mNames[event.startMonth]}${event.startDay > 0 ? ' ${event.startDay}' : ''}';
      final e = '${mNames[event.endMonth]}${event.endDay > 0 ? ' ${event.endDay}' : ''}';
      dateStr = '$s – $e';
    }

    return Row(
      children: [
        const Icon(Icons.calendar_today_outlined,
            size: 14, color: AppColors.accent),
        const SizedBox(width: 6),
        Text(dateStr,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w500,
                )),
      ],
    );
  }
}

// ── Season chip ───────────────────────────────────────────────────────────────

class _SeasonChip extends StatelessWidget {
  const _SeasonChip({required this.season});
  final SeasonType season;

  @override
  Widget build(BuildContext context) {
    final color = _seasonColor(season);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '${season.emoji} ${season.label}',
        style: TextStyle(color: color, fontSize: 10),
      ),
    );
  }
}

// ── Helper ────────────────────────────────────────────────────────────────────

Color _seasonColor(SeasonType s) {
  switch (s) {
    case SeasonType.spring:     return AppColors.sakura;
    case SeasonType.summer:     return Colors.teal;
    case SeasonType.autumn:     return Colors.deepOrange;
    case SeasonType.winter:     return Colors.indigo;
    case SeasonType.yearRound:  return AppColors.accent;
  }
}
