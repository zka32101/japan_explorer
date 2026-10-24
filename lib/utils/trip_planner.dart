import 'dart:math' as math;

import '../models/curation.dart';
import '../models/rating.dart';
import '../providers/favorites_provider.dart';

/// Great-circle distance in kilometres.
double distanceKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLng / 2), 2);
  return 2 * r * math.asin(math.sqrt(a));
}

/// Orders [curations] into a walkable route and, for more than one day,
/// splits it into [days] consecutive days of near-equal size.
///
/// The route starts at the westernmost spot and always continues to the
/// nearest unvisited one, so spots in the same area end up on the same day.
/// With one day only the order is set (no day numbers).
List<PlanSpot> arrangeByRoute(List<Curation> curations, {int days = 1}) {
  if (curations.isEmpty) return [];
  final remaining = [...curations];
  remaining.sort(
      (a, b) => a.location.longitude.compareTo(b.location.longitude));
  final route = <Curation>[remaining.removeAt(0)];
  while (remaining.isNotEmpty) {
    final last = route.last.location;
    var best = 0;
    var bestDistance = double.infinity;
    for (var i = 0; i < remaining.length; i++) {
      final d = distanceKm(last.latitude, last.longitude,
          remaining[i].location.latitude, remaining[i].location.longitude);
      if (d < bestDistance) {
        bestDistance = d;
        best = i;
      }
    }
    route.add(remaining.removeAt(best));
  }

  final dayCount = days.clamp(1, route.length);
  final base = route.length ~/ dayCount;
  final extra = route.length % dayCount; // the first [extra] days get one more
  final spots = <PlanSpot>[];
  var index = 0;
  for (var day = 1; day <= dayCount; day++) {
    final size = base + (day <= extra ? 1 : 0);
    for (var k = 0; k < size; k++) {
      final spot = planSpotFromCuration(route[index], order: index);
      spots.add(dayCount > 1 ? spot.copyWith(dayNumber: day) : spot);
      index++;
    }
  }
  return spots;
}
