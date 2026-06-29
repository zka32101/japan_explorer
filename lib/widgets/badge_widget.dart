import 'package:flutter/material.dart';
import '../config/theme.dart';

class BadgeDefinition {
  final String id;
  final String emoji;
  final String name;
  final String description;
  final Color color;

  const BadgeDefinition({
    required this.id,
    required this.emoji,
    required this.name,
    required this.description,
    required this.color,
  });
}

class AppBadges {
  static const all = [
    BadgeDefinition(
      id: 'first_visit',
      emoji: '🗾',
      name: 'First Step',
      description: 'Visited your first spot',
      color: Color(0xFF4CAF50),
    ),
    BadgeDefinition(
      id: 'photo_lover',
      emoji: '📸',
      name: 'Shutter Bug',
      description: 'Uploaded 10 photos',
      color: Color(0xFF2196F3),
    ),
    BadgeDefinition(
      id: 'streak_7',
      emoji: '🔥',
      name: 'Week Warrior',
      description: '7-day streak',
      color: Color(0xFFFF9800),
    ),
    BadgeDefinition(
      id: 'streak_30',
      emoji: '⚡',
      name: 'Monthly Master',
      description: '30-day streak',
      color: Color(0xFFFF5722),
    ),
    BadgeDefinition(
      id: 'rater_10',
      emoji: '⭐',
      name: 'Critic',
      description: 'Rated 10 spots',
      color: Color(0xFFFFD700),
    ),
    BadgeDefinition(
      id: 'planner',
      emoji: '🗺️',
      name: 'Planner',
      description: 'Created 3 travel plans',
      color: Color(0xFF9C27B0),
    ),
    BadgeDefinition(
      id: 'culture_fan',
      emoji: '⛩️',
      name: 'Culture Fan',
      description: 'Visited 5 shrines/temples',
      color: Color(0xFFE91E63),
    ),
    BadgeDefinition(
      id: 'foodie',
      emoji: '🍜',
      name: 'Foodie',
      description: 'Explored 10 food spots',
      color: Color(0xFFFF6F00),
    ),
    BadgeDefinition(
      id: 'ai_explorer',
      emoji: '🤖',
      name: 'AI Explorer',
      description: 'Used AI Lens 20 times',
      color: Color(0xFF00BCD4),
    ),
    BadgeDefinition(
      id: 'level_5',
      emoji: '🗺️',
      name: 'Explorer',
      description: 'Reached Level 5',
      color: Color(0xFF607D8B),
    ),
    BadgeDefinition(
      id: 'level_7',
      emoji: '🎌',
      name: 'Cultural Ambassador',
      description: 'Reached Level 7',
      color: Color(0xFFE63946),
    ),
    BadgeDefinition(
      id: 'japan_master',
      emoji: '👑',
      name: 'Japan Master',
      description: 'Reached Level 10',
      color: Color(0xFFFFD700),
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
              badge.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              badge.description,
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (!unlocked) ...[
              const SizedBox(height: 8),
              const Text(
                'Not yet unlocked',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
      return const Text(
        'Complete activities to earn badges!',
        style: TextStyle(color: AppColors.textSecondary),
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
                    const Text(
                      '🎉 Badge Unlocked!',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(badge.emoji, style: const TextStyle(fontSize: 64)),
                    const SizedBox(height: 8),
                    Text(
                      badge.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      badge.description,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: widget.onDismiss,
                      child: const Text('Awesome!'),
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
