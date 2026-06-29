import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/journal_provider.dart';
import '../providers/premium_provider.dart';
import '../config/theme.dart';
import '../utils/constants.dart';
import '../widgets/streak_widget.dart';
import '../widgets/badge_widget.dart';
import '../widgets/premium_gate.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(appUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/profile/settings'),
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) return const Center(child: Text('Not logged in'));
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildProfileHeader(context, user),
              const SizedBox(height: 24),
              _buildLevelCard(context, user),
              const SizedBox(height: 16),
              _buildPremiumBanner(context, ref),
              _buildStreakCard(context, user),
              const SizedBox(height: 16),
              _buildFeaturesSection(context),
              const SizedBox(height: 16),
              _buildBadgesSection(context, user.badges),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authNotifierProvider.notifier).signOut();
                  if (context.mounted) context.go('/login');
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, user) {
    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: AppColors.primary,
          backgroundImage:
              user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
          child: user.photoUrl == null
              ? Text(
                  user.displayName.isNotEmpty
                      ? user.displayName[0].toUpperCase()
                      : 'J',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.displayName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                user.email,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Lv.${user.level} ${user.levelTitle}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLevelCard(BuildContext context, user) {
    final progress = user.levelXpRequired > 0
        ? (user.xp / user.levelXpRequired).clamp(0.0, 1.0)
        : 1.0;
    return Card(
      child: InkWell(
        onTap: () => context.push('/progress'),
        borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'XP Progress',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${user.xp} XP',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.divider,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Next level: ${user.levelXpRequired} XP',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right,
                    size: 16, color: AppColors.textSecondary),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context, user) {
    return Column(
      children: [
        StreakWidget(streakDays: user.streakDays),
        const SizedBox(height: 8),
        WeeklyStreakCalendar(streakDays: user.streakDays),
      ],
    );
  }

  Widget _buildPremiumBanner(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    if (isPremium) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE63946), Color(0xFFFF6B6B)],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            Text('✨', style: TextStyle(fontSize: 18)),
            SizedBox(width: 10),
            Text(
              'Premium Member',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Spacer(),
            Text('Active',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      );
    }
    return InkWell(
      onTap: () => showPremiumPaywall(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFE63946).withValues(alpha: 0.1),
              const Color(0xFFFF6B6B).withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFFE63946).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Text('✨', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unlock Premium',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'Unlimited AI guides, plans & more',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Features',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _FeatureTile(
                emoji: '🧠',
                title: 'Daily Challenge',
                subtitle: 'Test your Japan knowledge',
                color: const Color(0xFF1A237E),
                onTap: () => context.push('/challenge'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FeatureTile(
                emoji: '✨',
                title: 'AI Trip Planner',
                subtitle: 'Generate a custom itinerary',
                color: const Color(0xFF00695C),
                onTap: () => context.push('/ai-planner'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _FeatureTile(
                emoji: '🇯🇵',
                title: 'Phrasebook',
                subtitle: 'Learn Japanese phrases',
                color: const Color(0xFFB71C1C),
                onTap: () => context.push('/phrases'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FeatureTile(
                emoji: '📷',
                title: 'Camera AI',
                subtitle: 'Scan & identify landmarks',
                color: const Color(0xFF4527A0),
                onTap: () => context.push('/camera'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _FeatureTile(
          emoji: '🏆',
          title: 'Cultural Progress',
          subtitle: 'View your knowledge stats, badges & level history',
          color: const Color(0xFF00695C),
          onTap: () => context.push('/progress'),
        ),
        const SizedBox(height: 12),
        Consumer(builder: (context, ref, _) {
          final count = ref.watch(journalProvider).entries.length;
          return _FeatureTile(
            emoji: '📖',
            title: tr('journal.title'),
            subtitle: count > 0
                ? tr('journal.entry_count',
                    namedArgs: {'count': '$count'})
                : tr('journal.subtitle'),
            color: const Color(0xFF4E342E),
            onTap: () => context.push(AppRoutes.journal),
          );
        }),
        const SizedBox(height: 12),
        _FeatureTile(
          emoji: '🤝',
          title: 'Meet a Local',
          subtitle: 'Connect with local hosts for a personal Japan experience',
          color: const Color(0xFF6A1B9A),
          onTap: () => context.push('/hosts'),
        ),
      ],
    );
  }

  Widget _buildBadgesSection(BuildContext context, List<String> badges) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Badges (${badges.length}/${AppBadges.all.length})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        BadgeGrid(unlockedIds: badges, showAll: true),
      ],
    );
  }
}

// ── Feature tile ─────────────────────────────────────────────────────────────

class _FeatureTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _FeatureTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: color)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
