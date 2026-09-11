import 'package:flutter/material.dart';
import '../config/theme.dart';

class StreakWidget extends StatelessWidget {
  final int streakDays;
  final bool compact;

  const StreakWidget({
    super.key,
    required this.streakDays,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) return _buildCompact(context);
    return _buildFull(context);
  }

  Widget _buildCompact(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: streakDays > 0
            ? Colors.orange.withValues(alpha: 0.15)
            : AppColors.divider,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            streakDays > 0 ? '🔥' : '💤',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 4),
          Text(
            '$streakDays day${streakDays != 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: streakDays > 0 ? Colors.orange : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFull(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(
              streakDays > 0 ? '🔥' : '💤',
              style: const TextStyle(fontSize: 36),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$streakDays Day Streak',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    streakDays > 0
                        ? 'Keep exploring daily!'
                        : 'Start your streak today!',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (streakDays >= 7)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'On Fire!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class WeeklyStreakCalendar extends StatelessWidget {
  final int streakDays;

  const WeeklyStreakCalendar({super.key, required this.streakDays});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday; // 1=Mon, 7=Sun
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (i) {
        final dayIndex = i + 1;
        final isCompleted = streakDays >= (today - dayIndex + 7) % 7 + 1;
        final isToday = dayIndex == today;
        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
        return Column(
          children: [
            Text(
              days[i],
              style: TextStyle(
                fontSize: 11,
                color: isToday ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? Colors.orange
                    : isToday
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : AppColors.divider,
                border: isToday
                    ? Border.all(color: AppColors.primary, width: 2)
                    : null,
              ),
              child: Center(
                child: Text(
                  isCompleted ? '🔥' : '',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
