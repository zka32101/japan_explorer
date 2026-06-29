import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../models/cultural_challenge.dart';
import '../providers/challenge_provider.dart';
import '../widgets/badge_widget.dart';
import '../widgets/level_up_overlay.dart';

class ChallengeScreen extends ConsumerWidget {
  const ChallengeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(challengeNotifierProvider);
    final challenge = state.challenge;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(challenge.category.emoji),
            const SizedBox(width: 8),
            const Text('Daily Challenge'),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
            ),
            child: Text(
              challenge.category.label,
              style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────
              _buildHeader(state),
              const SizedBox(height: 24),

              // ── Question ────────────────────────────────────────────
              Text(
                challenge.question,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // ── Options ─────────────────────────────────────────────
              ...List.generate(challenge.options.length, (i) {
                return _OptionTile(
                  index: i,
                  text: challenge.options[i],
                  state: state,
                  onTap: state.isAnswered
                      ? null
                      : () => ref
                          .read(challengeNotifierProvider.notifier)
                          .answer(i),
                );
              }),

              const SizedBox(height: 24),

              // ── Result / Explanation ─────────────────────────────────
              if (state.isAnswered) ...[
                _buildResultCard(state),
                const SizedBox(height: 16),
                _buildExplanation(challenge),
                const SizedBox(height: 24),
                _buildNextChallengeInfo(),
              ],
            ],
          ),
        ),
      ),
          // ── Level-up overlay ──────────────────────────────────────
          if (state.leveledUp && state.newLevel != null)
            LevelUpOverlay(
              newLevel: state.newLevel!,
              onDismiss: () => ref
                  .read(challengeNotifierProvider.notifier)
                  .clearFeedback(),
            ),
          // ── Badge unlock overlays (shown one by one) ──────────────
          if (!state.leveledUp && state.newBadgeIds.isNotEmpty)
            NewBadgeAnimation(
              badgeId: state.newBadgeIds.first,
              onDismiss: () => ref
                  .read(challengeNotifierProvider.notifier)
                  .clearFeedback(),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(ChallengeState state) {
    if (state.alreadyAnsweredToday && state.xpEarned != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.today, color: AppColors.textSecondary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                state.isCorrect
                    ? 'You nailed today\'s challenge! Come back tomorrow.'
                    : 'Today\'s challenge complete. Try again tomorrow!',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFFFF6B6B)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Text('🧠', style: TextStyle(fontSize: 28)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Cultural Challenge',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                SizedBox(height: 2),
                Text('Answer correctly to earn 15 XP',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Column(
            children: [
              Text('⭐ 15', style: TextStyle(color: Colors.white, fontSize: 16)),
              Text('XP', style: TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(ChallengeState state) {
    final isCorrect = state.isCorrect;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCorrect ? Colors.green : Colors.orange,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Text(
            isCorrect ? '🎉' : '💡',
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCorrect ? 'Correct!' : 'Not quite…',
                  style: TextStyle(
                    color: isCorrect ? Colors.green.shade800 : Colors.orange.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isCorrect
                      ? '+${state.xpEarned} XP earned 🌟'
                      : '+${state.xpEarned} XP for trying',
                  style: TextStyle(
                    color: isCorrect ? Colors.green.shade700 : Colors.orange.shade700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanation(CulturalChallenge challenge) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.menu_book, color: AppColors.secondary, size: 18),
              SizedBox(width: 8),
              Text('Explanation',
                  style: TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            challenge.explanation,
            style: const TextStyle(fontSize: 14, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildNextChallengeInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.schedule, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        const Text(
          'A new challenge awaits tomorrow',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  final int index;
  final String text;
  final ChallengeState state;
  final VoidCallback? onTap;

  static const _labels = ['A', 'B', 'C', 'D'];

  const _OptionTile({
    required this.index,
    required this.text,
    required this.state,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final answered = state.isAnswered;
    final selected = state.selectedIndex == index;
    final correct = index == state.challenge.correctIndex;

    Color borderColor = AppColors.divider;
    Color bgColor = Colors.white;
    Color labelBg = Colors.grey.shade200;
    Color labelText = AppColors.textSecondary;

    if (answered) {
      if (correct) {
        borderColor = Colors.green;
        bgColor = const Color(0xFFE8F5E9);
        labelBg = Colors.green;
        labelText = Colors.white;
      } else if (selected && !correct) {
        borderColor = Colors.orange;
        bgColor = const Color(0xFFFFF3E0);
        labelBg = Colors.orange;
        labelText = Colors.white;
      }
    } else if (selected) {
      borderColor = AppColors.primary;
      bgColor = AppColors.primary.withValues(alpha: 0.06);
      labelBg = AppColors.primary;
      labelText = Colors.white;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: answered && correct ? 2 : 1),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: labelBg,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                _labels[index],
                style: TextStyle(
                    color: labelText,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 14, height: 1.4)),
            ),
            if (answered && correct)
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
            if (answered && selected && !correct)
              const Icon(Icons.cancel, color: Colors.orange, size: 20),
          ],
        ),
      ),
    );
  }
}
