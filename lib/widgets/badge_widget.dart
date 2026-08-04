import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../config/theme.dart';

class BadgeDefinition {
  final String id;
  final String emoji;
  /// Translation key for the badge name — call `tr(nameKey)` to display.
  final String nameKey;
  /// Translation key for the badge description — call `tr(descriptionKey)` to display.
  final String descriptionKey;
  final Color color;

  const BadgeDefinition({
    required this.id,
    required this.emoji,
    required this.nameKey,
    required this.descriptionKey,
    required this.color,
  });
}

class AppBadges {
  static const all = [
    BadgeDefinition(
      id: 'first_visit',
      emoji: '🗾',
      nameKey: 'badges.first_visit_name',
      descriptionKey: 'badges.first_visit_desc',
      color: Color(0xFF4CAF50),
    ),
    BadgeDefinition(
      id: 'photo_lover',
      emoji: '📸',
      nameKey: 'badges.photo_lover_name',
      descriptionKey: 'badges.photo_lover_desc',
      color: Color(0xFF2196F3),
    ),
    BadgeDefinition(
      id: 'streak_7',
      emoji: '🔥',
      nameKey: 'badges.streak_7_name',
      descriptionKey: 'badges.streak_7_desc',
      color: Color(0xFFFF9800),
    ),
    BadgeDefinition(
      id: 'streak_30',
      emoji: '⚡',
      nameKey: 'badges.streak_30_name',
      descriptionKey: 'badges.streak_30_desc',
      color: Color(0xFFFF5722),
    ),
    BadgeDefinition(
      id: 'rater_10',
      emoji: '⭐',
      nameKey: 'badges.rater_10_name',
      descriptionKey: 'badges.rater_10_desc',
      color: Color(0xFFFFD700),
    ),
    BadgeDefinition(
      id: 'planner',
      emoji: '🗺️',
      nameKey: 'badges.planner_name',
      descriptionKey: 'badges.planner_desc',
      color: Color(0xFF9C27B0),
    ),
    BadgeDefinition(
      id: 'culture_fan',
      emoji: '⛩️',
      nameKey: 'badges.culture_fan_name',
      descriptionKey: 'badges.culture_fan_desc',
      color: Color(0xFFE91E63),
    ),
    BadgeDefinition(
      id: 'foodie',
      emoji: '🍜',
      nameKey: 'badges.foodie_name',
      descriptionKey: 'badges.foodie_desc',
      color: Color(0xFFFF6F00),
    ),
    BadgeDefinition(
      id: 'ai_explorer',
      emoji: '🤖',
      nameKey: 'badges.ai_explorer_name',
      descriptionKey: 'badges.ai_explorer_desc',
      color: Color(0xFF00BCD4),
    ),
    BadgeDefinition(
      id: 'level_5',
      emoji: '🗺️',
      nameKey: 'badges.level_5_name',
      descriptionKey: 'badges.level_5_desc',
      color: Color(0xFF607D8B),
    ),
    BadgeDefinition(
      id: 'level_7',
      emoji: '🎌',
      nameKey: 'badges.level_7_name',
      descriptionKey: 'badges.level_7_desc',
      color: Color(0xFFE63946),
    ),
    BadgeDefinition(
      id: 'japan_master',
      emoji: '👑',
      nameKey: 'badges.japan_master_name',
      descriptionKey: 'badges.japan_master_desc',
      color: Color(0xFFFFD700),
    ),
    BadgeDefinition(
      id: 'ambassador',
      emoji: '🎁',
      nameKey: 'badges.ambassador_name',
      descriptionKey: 'badges.ambassador_desc',
      color: Color(0xFFE65100),
    ),
  ];

  static BadgeDefinition? find(String id) {
    try {
      return all.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }
}

class BadgeChip extends StatelessWidget {
  final String badgeId;
  final bool unlocked;
  final double size;

  const BadgeChip({
    super.key,
    required this.badgeId,
    this.unlocked = true,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final badge = AppBadges.find(badgeId);
    if (badge == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _showTooltip(context, badge),
      child: Opacity(
        opacity: unlocked ? 1.0 : 0.35,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: badge.color.withValues(alpha: 0.15),
            border: Border.all(
              color: unlocked ? badge.color : AppColors.divider,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              badge.emoji,
              style: TextStyle(fontSize: size * 0.45),
            ),
          ),
        ),
      ),
    );
  }

  void _showTooltip(BuildContext context, BadgeDefinition badge) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(badge.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(
              tr(badge.nameKey),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tr(badge.descriptionKey),
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (!unlocked) ...[
              const SizedBox(height: 8),
              Text(
                'widgets.badge_not_unlocked'.tr(),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class BadgeGrid extends StatelessWidget {
  final List<String> unlockedIds;
  final bool showAll;

  const BadgeGrid({
    super.key,
    required this.unlockedIds,
    this.showAll = true,
  });

  @override
  Widget build(BuildContext context) {
    final badges = showAll ? AppBadges.all : AppBadges.all.where((b) => unlockedIds.contains(b.id)).toList();

    if (badges.isEmpty) {
      return Text(
        'widgets.badge_empty'.tr(),
        style: const TextStyle(color: AppColors.textSecondary),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: badges.map((b) => BadgeChip(
        badgeId: b.id,
        unlocked: unlockedIds.contains(b.id),
      )).toList(),
    );
  }
}

class NewBadgeAnimation extends StatefulWidget {
  final String badgeId;
  final VoidCallback onDismiss;

  const NewBadgeAnimation({
    super.key,
    required this.badgeId,
    required this.onDismiss,
  });

  @override
  State<NewBadgeAnimation> createState() => _NewBadgeAnimationState();
}

class _NewBadgeAnimationState extends State<NewBadgeAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badge = AppBadges.find(widget.badgeId);
    if (badge == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: widget.onDismiss,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: ScaleTransition(
            scale: _scale,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'widgets.badge_unlocked_title'.tr(),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(badge.emoji, style: const TextStyle(fontSize: 64)),
                    const SizedBox(height: 8),
                    Text(
                      badge.nameKey.tr(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      badge.descriptionKey.tr(),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: widget.onDismiss,
                      child: Text('widgets.badge_awesome'.tr()),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
