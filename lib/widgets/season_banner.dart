import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../models/season_event.dart';
import '../providers/season_provider.dart';

/// Compact horizontal banner showing the active seasonal event(s).
/// Shows nothing if no events are active.
class SeasonBanner extends ConsumerWidget {
  final VoidCallback? onTap;
  const SeasonBanner({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(activeSeasonEventsProvider);
    if (events.isEmpty) return const SizedBox.shrink();

    // Show the most culturally significant event (first in list)
    final event = events.first;
    return GestureDetector(
      onTap: onTap ?? () => _showAllEvents(context, events),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _gradientColors(event.season),
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(event.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (events.length > 1) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+${events.length - 1}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 10),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.tip,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54, size: 18),
          ],
        ),
      ),
    );
  }

  List<Color> _gradientColors(SeasonType season) {
    switch (season) {
      case SeasonType.spring:
        return [const Color(0xFFE91E8C), const Color(0xFFFF6B9D)];
      case SeasonType.summer:
        return [const Color(0xFF1565C0), const Color(0xFF0288D1)];
      case SeasonType.autumn:
        return [const Color(0xFFE65100), const Color(0xFFF57F17)];
      case SeasonType.winter:
        return [const Color(0xFF283593), const Color(0xFF00838F)];
      case SeasonType.yearRound:
        return [AppColors.primary, AppColors.indigo];
    }
  }

  void _showAllEvents(BuildContext context, List<SeasonEvent> events) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SeasonEventSheet(events: events),
    );
  }
}

class _SeasonEventSheet extends StatelessWidget {
  final List<SeasonEvent> events;
  const _SeasonEventSheet({required this.events});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'What\'s Happening in Japan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Active seasonal events right now',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          ...events.map((event) => _EventCard(event: event)),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final SeasonEvent event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(event.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(event.titleJa,
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  event.season.label,
                  style: TextStyle(
                      color: Colors.grey.shade700, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(event.description,
              style: const TextStyle(fontSize: 13, height: 1.5)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb_outline,
                  size: 14, color: Colors.amber),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  event.tip,
                  style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                      fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
