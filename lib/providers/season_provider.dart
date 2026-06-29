import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/season_event.dart';
import '../services/season_service.dart';

/// Active seasonal events for today.
final activeSeasonEventsProvider = Provider<List<SeasonEvent>>((ref) {
  return SeasonService.getActiveEvents(DateTime.now());
});

/// Current season type.
final currentSeasonProvider = Provider<SeasonType>((ref) {
  return SeasonService.getCurrentSeason(DateTime.now());
});
