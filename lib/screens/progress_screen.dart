import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../models/cultural_challenge.dart';
import '../models/cultural_progress.dart';
import '../providers/auth_provider.dart';
import '../providers/progress_provider.dart';
import '../services/firebase_service.dart';
import '../widgets/badge_widget.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(appUserProvider);
    final progressAsync = ref.watch(culturalProgressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text('🏆', style: TextStyle(fontSize: 18)),
            SizedBox(width: 8),
            Text('Cultural Progress'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refresh',
            onPressed: () =>
                ref.invalidate(culturalProgressProvider),
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Not logged in'));
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(culturalProgressProvider),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Hero: Level card ──────────────────────────────────
                _LevelHeroCard(user: user),
                const SizedBox(height: 20),

                // ── Cultural quiz progress ────────────────────────────
                progressAsync.when(
                  loading: () => const Center(
                      child: CircularProgressIndicator()),
                  error: (e, _) => Text('Failed to load: $e'),
                  data: (summary) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _QuizSummaryCard(summary: summary),
                      const SizedBox(height: 20),
                      _CategoryProgressSection(summary: summary),
                      const SizedBox(height: 20),
                      _StatsRow(summary: summary, user: user),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Badges ────────────────────────────────────────────
                _BadgesSection(unlockedIds: user.badges),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Level hero card ──────────────────────────────────────────────────────────

class _LevelHeroCard extends StatelessWidget {
  final dynamic user; // AppUser

  const _LevelHeroCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final progress = user.levelXpRequired > 0
        ? (user.xp / user.levelXpRequired).clamp(0.0, 1.0)
        : 1.0;
    final xpToNext = (user.levelXpRequired - user.xp).clamp(0, 999999);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF283593)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current Level',
                      style: TextStyle(
                          color: Colors.white60, fontSize: 12)),
                  Text('Lv.${user.level}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      )),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Text(
                  user.levelTitle,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // XP bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${user.xp} XP',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              if (user.level < 10)
                Text('$xpToNext XP to next level',
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 12))
              else
                const Text('MAX LEVEL 🎉',
                    style: TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Quiz summary card ────────────────────────────────────────────────────────

class _QuizSummaryCard extends StatelessWidget {
  final CulturalProgressSummary summary;
  const _QuizSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final answered = summary.totalQuestionsAnswered;
    final pct = summary.overallAccuracy;
    final pctStr = answered == 0 ? '--' : '${(pct * 100).round()}%';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: _StatBlock(
                value: '$answered',
                label: 'Challenges',
                emoji: '🧠',
                color: AppColors.primary,
              ),
            ),
            Container(width: 1, height: 48, color: AppColors.divider),
            Expanded(
              child: _StatBlock(
                value: pctStr,
                label: 'Accuracy',
                emoji: '🎯',
                color: pct >= 0.7 ? Colors.green : AppColors.accent,
              ),
            ),
            Container(width: 1, height: 48, color: AppColors.divider),
            Expanded(
              child: _StatBlock(
                value: '${summary.totalXpFromChallenges}',
                label: 'Quiz XP',
                emoji: '⭐',
                color: AppColors.secondary,
              ),
            ),
            Container(width: 1, height: 48, color: AppColors.divider),
            Expanded(
              child: _StatBlock(
                value: '${summary.scanCount}',
                label: 'Scans',
                emoji: '📷',
                color: const Color(0xFF00BCD4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String value;
  final String label;
  final String emoji;
  final Color color;

  const _StatBlock({
    required this.value,
    required this.label,
    required this.emoji,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }
}

// ── Per-category bars ────────────────────────────────────────────────────────

class _CategoryProgressSection extends StatelessWidget {
  final CulturalProgressSummary summary;
  const _CategoryProgressSection({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Knowledge by Category',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...summary.categories.map(
          (c) => _CategoryBar(progress: c),
        ),
      ],
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final CategoryProgress progress;
  const _CategoryBar({required this.progress});

  static const _emojis = {
    ChallengeCategory.history: '🏯',
    ChallengeCategory.etiquette: '🙏',
    ChallengeCategory.food: '🍜',
    ChallengeCategory.language: '🗣️',
    ChallengeCategory.customs: '🎎',
  };

  @override
  Widget build(BuildContext context) {
    final cat = progress.category;
    final emoji = _emojis[cat] ?? '📚';
    final acc = progress.accuracy;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(cat.label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: progress.masteryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  progress.masteryLabel,
                  style: TextStyle(
                      color: progress.masteryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: acc,
              minHeight: 8,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(
                  progress.masteryColor),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            progress.questionsAnswered == 0
                ? 'No questions answered yet'
                : '${progress.correctCount}/${progress.questionsAnswered} correct',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ── Stats row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final CulturalProgressSummary summary;
  final dynamic user;
  const _StatsRow({required this.summary, required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InfoTile(
            emoji: '🔥',
            value: '${user.streakDays}',
            label: 'Day Streak',
            color: const Color(0xFFFF9800),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InfoTile(
            emoji: '🏅',
            value: '${user.badges.length}',
            label: 'Badges',
            color: const Color(0xFF9C27B0),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InfoTile(
            emoji: '⭐',
            value: '${user.xp}',
            label: 'Total XP',
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color color;

  const _InfoTile({
    required this.emoji,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Badges section ───────────────────────────────────────────────────────────

class _BadgesSection extends StatelessWidget {
  final List<String> unlockedIds;
  const _BadgesSection({required this.unlockedIds});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Badges',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${unlockedIds.length}/${AppBadges.all.length}',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        BadgeGrid(unlockedIds: unlockedIds, showAll: true),
        if (unlockedIds.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Complete activities and quizzes to unlock badges!',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
      ],
    );
  }
}
