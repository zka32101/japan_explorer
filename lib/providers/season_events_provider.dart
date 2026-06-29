import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/season_event.dart';
import '../services/season_service.dart';

/// All events for a given [SeasonType] filter (null = all).
final eventsBySeasonProvider =
    Provider.family<List<SeasonEvent>, SeasonType?>((ref, season) {
  return SeasonService.getEventsBySeason(season);
});

/// Events that are currently active today.
final activeEventsProvider = Provider<List<SeasonEvent>>((ref) {
  return SeasonService.getActiveEvents(DateTime.now());
});

/// Events for a given month (1–12).
final eventsForMonthProvider =
    Provider.family<List<SeasonEvent>, int>((ref, month) {
  return SeasonService.getAllEvents().where((e) {
    if (e.season == SeasonType.yearRound) return true;
    final start = e.startMonth * 100 + (e.startDay == 0 ? 1 : e.startDay);
    final end = e.endMonth * 100 + (e.endDay == 0 ? 28 : e.endDay);
    final mid = month * 100 + 15;
    if (start <= end) return mid >= start && mid <= end;
    return mid >= start || mid <= end;
  }).toList();
});
