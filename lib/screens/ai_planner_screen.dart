import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../models/ai_itinerary.dart';
import '../models/rating.dart';
import '../providers/plan_provider.dart';
import '../providers/planner_provider.dart';
import '../providers/premium_provider.dart';
import '../widgets/premium_gate.dart';

// ── Available cities ──────────────────────────────────────────────────────────
const _cities = [
  '🗼 Tokyo',
  '⛩️ Kyoto',
  '🦌 Nara',
  '🌊 Osaka',
  '🏯 Hiroshima',
  '🌋 Hakone',
  '🎿 Hokkaido',
  '🌸 Kanazawa',
  '🏔️ Nikko',
  '🍣 Fukuoka',
];

// ── Interests ─────────────────────────────────────────────────────────────────
const _interests = [
  ('culture', '⛩️', 'Culture & History'),
  ('food', '🍜', 'Food & Drink'),
  ('nature', '🌿', 'Nature & Outdoors'),
  ('modern', '🏙️', 'Modern Japan'),
  ('shopping', '🛍️', 'Shopping'),
  ('nightlife', '🌃', 'Nightlife'),
];

class AiPlannerScreen extends ConsumerStatefulWidget {
  const AiPlannerScreen({super.key});

  @override
  ConsumerState<AiPlannerScreen> createState() => _AiPlannerScreenState();
}

class _AiPlannerScreenState extends ConsumerState<AiPlannerScreen> {
  String _selectedCity = 'Tokyo';
  int _days = 3;
  final Set<String> _selectedInterests = {'culture', 'food'};
  TripBudget _budget = TripBudget.midRange;

  String get _cityName =>
      _selectedCity.replaceAll(RegExp(r'^[^\s]+ '), '');

  Future<void> _checkAndGenerate() async {
    final isPremium = ref.read(isPremiumProvider);
    final canUse =
        await UsageLimitService.canUseAiPlanner(isPremium: isPremium);
    if (!canUse) {
      if (mounted) await showPremiumPaywall(context);
      return;
    }
    await UsageLimitService.recordAiPlannerUse();
    ref.read(plannerNotifierProvider.notifier).generate(
          TripPreferences(
            city: _cityName,
            days: _days,
            interests: _selectedInterests.toList(),
            budget: _budget,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final plannerState = ref.watch(plannerNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('🤖', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(tr('planner.title')),
          ],
        ),
        actions: [
          if (plannerState.itinerary != null)
            TextButton(
              onPressed: () => ref.read(plannerNotifierProvider.notifier).reset(),
              child: Text(tr('planner.reset')),
            ),
        ],
      ),
      body: plannerState.isGenerating
          ? _buildLoading()
          : plannerState.itinerary != null
              ? _ItineraryView(itinerary: plannerState.itinerary!)
              : _buildInputForm(plannerState),
    );
  }

  Widget _buildInputForm(PlannerState state) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Hero ──────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF283593)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Text('🗾', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              Text(tr('planner.hero_title'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(tr('planner.hero_subtitle'),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // ── City ──────────────────────────────────────────────────────
        _SectionHeader(icon: Icons.location_on, title: tr('planner.destination')),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _cities.map((c) {
            final name = c.replaceAll(RegExp(r'^[^\s]+ '), '');
            final sel = _selectedCity == name;
            return GestureDetector(
              onTap: () => setState(() => _selectedCity = name),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: sel ? AppColors.primary : AppColors.divider,
                  ),
                  boxShadow: sel
                      ? [
                          BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2))
                        ]
                      : null,
                ),
                child: Text(
                  c,
                  style: TextStyle(
                    color: sel ? Colors.white : AppColors.onSurface,
                    fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),

        // ── Days ──────────────────────────────────────────────────────
        _SectionHeader(icon: Icons.calendar_today, title: tr('planner.duration')),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              tr('planner.days_count', args: ['$_days']),
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary),
            ),
            const Spacer(),
            const Text('1', style: TextStyle(color: AppColors.textSecondary)),
            Expanded(
              flex: 6,
              child: Slider(
                value: _days.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _days = v.round()),
              ),
            ),
            const Text('10', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 24),

        // ── Interests ─────────────────────────────────────────────────
        _SectionHeader(icon: Icons.interests, title: tr('planner.interests')),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _interests.map((item) {
            final (id, emoji, label) = item;
            final sel = _selectedInterests.contains(id);
            return FilterChip(
              avatar: Text(emoji, style: const TextStyle(fontSize: 14)),
              label: Text(label),
              selected: sel,
              onSelected: (v) => setState(() {
                if (v) {
                  _selectedInterests.add(id);
                } else if (_selectedInterests.length > 1) {
                  _selectedInterests.remove(id);
                }
              }),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                  color: sel ? Colors.white : AppColors.onSurface,
                  fontSize: 13),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // ── Budget ────────────────────────────────────────────────────
        _SectionHeader(icon: Icons.wallet, title: tr('planner.budget')),
        const SizedBox(height: 12),
        Row(
          children: TripBudget.values.map((b) {
            final sel = _budget == b;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _budget = b),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.secondary : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: sel ? AppColors.secondary : AppColors.divider),
                  ),
                  child: Text(
                    b.label,
                    style: TextStyle(
                      color: sel ? Colors.white : AppColors.onSurface,
                      fontSize: 12,
                      fontWeight:
                          sel ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),

        // ── Error ─────────────────────────────────────────────────────
        if (state.error != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(state.error!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
          ),

        // ── Generate button ───────────────────────────────────────────
        ElevatedButton.icon(
          onPressed: _selectedInterests.isEmpty ? null : _checkAndGenerate,
          icon: const Text('✨', style: TextStyle(fontSize: 18)),
          label: Text(tr('planner.generate_button', args: ['$_days', _cityName])),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          tr('planner.powered_by'),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoading() {
    final city = ref.read(plannerNotifierProvider).preferences?.city ?? '';
    final days = ref.read(plannerNotifierProvider).preferences?.days ?? 0;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 3),
          ),
          const SizedBox(height: 24),
          Text(tr('planner.planning_trip'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            tr('planner.creating_itinerary', args: ['$days', city]),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            tr('planner.takes_time'),
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Itinerary Result View ────────────────────────────────────────────────────

class _ItineraryView extends ConsumerStatefulWidget {
  final AiItinerary itinerary;
  const _ItineraryView({required this.itinerary});

  @override
  ConsumerState<_ItineraryView> createState() => _ItineraryViewState();
}

class _ItineraryViewState extends ConsumerState<_ItineraryView> {
  final Set<int> _expandedDays = {1};
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final it = widget.itinerary;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Trip header ───────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF283593)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(it.tripTitle,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(it.overview,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13, height: 1.5)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Day cards ─────────────────────────────────────────────────
        ...it.days.map((day) => _DayCard(
              day: day,
              isExpanded: _expandedDays.contains(day.day),
              onToggle: () => setState(() {
                if (_expandedDays.contains(day.day)) {
                  _expandedDays.remove(day.day);
                } else {
                  _expandedDays.add(day.day);
                }
              }),
            )),

        const SizedBox(height: 16),

        // ── General tips ──────────────────────────────────────────────
        if (it.generalTips.isNotEmpty)
          _TipCard(tips: it.generalTips, budgetNote: it.budgetNote),

        const SizedBox(height: 24),

        // ── Save as plan ─────────────────────────────────────────────
        ElevatedButton.icon(
          onPressed: _saving ? null : () => _saveAsPlan(context, it),
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.save_outlined),
          label: Text(_saving ? tr('planner.saving') : tr('planner.save_as_plan')),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Future<void> _saveAsPlan(BuildContext context, AiItinerary it) async {
    setState(() => _saving = true);
    try {
      await ref.read(planNotifierProvider.notifier).createPlan(it.tripTitle);
      final plans = ref.read(planNotifierProvider).valueOrNull ?? [];
      if (plans.isEmpty) return;
      final plan = plans.first;

      int order = 0;
      for (final day in it.days) {
        for (final activity in day.activities) {
          if (activity.spotName.isEmpty) continue;
          final spot = PlanSpot(
            curationId: '',
            curationTitle: activity.spotName,
            order: order++,
            note: 'Day ${day.day} · ${activity.area} · ${activity.duration}',
          );
          await ref
              .read(planNotifierProvider.notifier)
              .addSpotToPlan(plan.id, spot);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('planner.saved_to_plans', args: [it.tripTitle])),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('planner.save_failed', args: ['$e']))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _DayCard extends StatelessWidget {
  final ItineraryDay day;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _DayCard({
    required this.day,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Header (always visible)
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('planner.day_number', args: ['${day.day}']),
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                        Text(day.theme,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          // Expandable content
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _ActivityRow(time: tr('planner.morning'), emoji: '🌅', activity: day.morning),
                  if (day.lunchTip != null) ...[
                    const SizedBox(height: 8),
                    _InfoRow(icon: Icons.restaurant_outlined, text: day.lunchTip!),
                  ],
                  const SizedBox(height: 8),
                  _ActivityRow(time: tr('planner.afternoon'), emoji: '☀️', activity: day.afternoon),
                  if (day.transportTip != null) ...[
                    const SizedBox(height: 8),
                    _InfoRow(icon: Icons.directions_subway_outlined, text: day.transportTip!),
                  ],
                  const SizedBox(height: 8),
                  _ActivityRow(time: tr('planner.evening'), emoji: '🌆', activity: day.evening),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final String time;
  final String emoji;
  final ItineraryActivity activity;

  const _ActivityRow({
    required this.time,
    required this.emoji,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(time,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5)),
              const Spacer(),
              if (activity.duration.isNotEmpty)
                Text(activity.duration,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 6),
          Text(activity.spotName,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15)),
          if (activity.area.isNotEmpty)
            Text(activity.area,
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12)),
          const SizedBox(height: 4),
          Text(activity.description,
              style: const TextStyle(fontSize: 13, height: 1.4)),
          if (activity.tip.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline,
                    size: 13, color: Colors.amber),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(activity.tip,
                      style: TextStyle(
                          color: Colors.amber.shade800,
                          fontSize: 12,
                          fontStyle: FontStyle.italic)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.secondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  color: AppColors.secondary, fontSize: 12)),
        ),
      ],
    );
  }
}

class _TipCard extends StatelessWidget {
  final List<String> tips;
  final String? budgetNote;

  const _TipCard({required this.tips, this.budgetNote});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(tr('planner.trip_tips'),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary)),
            ],
          ),
          const SizedBox(height: 10),
          ...tips.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ',
                        style: TextStyle(color: AppColors.secondary)),
                    Expanded(
                      child: Text(t,
                          style: const TextStyle(
                              fontSize: 13, height: 1.4)),
                    ),
                  ],
                ),
              )),
          if (budgetNote != null) ...[
            const Divider(),
            Row(
              children: [
                const Icon(Icons.wallet, size: 14, color: AppColors.secondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(budgetNote!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Section header helper ────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
