/// A single activity slot in the AI-generated itinerary.
class ItineraryActivity {
  final String spotName;
  final String area;
  final String description;
  final String tip;
  final String duration;

  const ItineraryActivity({
    required this.spotName,
    required this.area,
    required this.description,
    required this.tip,
    this.duration = '2h',
  });

  factory ItineraryActivity.fromJson(Map<String, dynamic> json) =>
      ItineraryActivity(
        spotName: json['spot'] as String? ?? json['name'] as String? ?? '',
        area: json['area'] as String? ?? '',
        description: json['description'] as String? ?? '',
        tip: json['tip'] as String? ?? '',
        duration: json['duration'] as String? ?? '2h',
      );
}

/// One day in the AI-generated trip itinerary.
class ItineraryDay {
  final int day;
  final String theme;
  final ItineraryActivity morning;
  final ItineraryActivity afternoon;
  final ItineraryActivity evening;
  final String? lunchTip;
  final String? transportTip;

  const ItineraryDay({
    required this.day,
    required this.theme,
    required this.morning,
    required this.afternoon,
    required this.evening,
    this.lunchTip,
    this.transportTip,
  });

  factory ItineraryDay.fromJson(Map<String, dynamic> json) => ItineraryDay(
        day: json['day'] as int? ?? 1,
        theme: json['theme'] as String? ?? '',
        morning: ItineraryActivity.fromJson(
            json['morning'] as Map<String, dynamic>? ?? {}),
        afternoon: ItineraryActivity.fromJson(
            json['afternoon'] as Map<String, dynamic>? ?? {}),
        evening: ItineraryActivity.fromJson(
            json['evening'] as Map<String, dynamic>? ?? {}),
        lunchTip: json['lunch_tip'] as String?,
        transportTip: json['transport_tip'] as String?,
      );

  /// All activities in order.
  List<ItineraryActivity> get activities => [morning, afternoon, evening];
}

/// The complete AI-generated trip itinerary.
class AiItinerary {
  final String tripTitle;
  final String overview;
  final List<ItineraryDay> days;
  final List<String> generalTips;
  final String? budgetNote;
  final String city;
  final int numDays;

  const AiItinerary({
    required this.tripTitle,
    required this.overview,
    required this.days,
    required this.generalTips,
    this.budgetNote,
    required this.city,
    required this.numDays,
  });

  factory AiItinerary.fromJson(
      Map<String, dynamic> json, String city, int numDays) {
    final rawDays = json['days'] as List<dynamic>? ?? [];
    return AiItinerary(
      tripTitle: json['trip_title'] as String? ?? '$numDays Days in $city',
      overview: json['overview'] as String? ?? '',
      days: rawDays
          .map((d) => ItineraryDay.fromJson(d as Map<String, dynamic>))
          .toList(),
      generalTips: (json['general_tips'] as List<dynamic>? ?? [])
          .map((t) => t.toString())
          .toList(),
      budgetNote: json['budget_note'] as String?,
      city: city,
      numDays: numDays,
    );
  }
}

/// User preferences passed to the AI planner.
class TripPreferences {
  final String city;
  final int days;
  final List<String> interests; // e.g. ['culture', 'food', 'nature']
  final TripBudget budget;
  final String language;

  const TripPreferences({
    required this.city,
    required this.days,
    required this.interests,
    required this.budget,
    this.language = 'en',
  });
}

enum TripBudget {
  budget,
  midRange,
  luxury,
}

extension TripBudgetExt on TripBudget {
  String get label {
    switch (this) {
      case TripBudget.budget:   return '¥ Budget';
      case TripBudget.midRange: return '¥¥ Mid-range';
      case TripBudget.luxury:   return '¥¥¥ Luxury';
    }
  }

  String get aiDescription {
    switch (this) {
      case TripBudget.budget:   return 'budget-friendly (hostels, ramen, local transit)';
      case TripBudget.midRange: return 'mid-range (business hotels, casual restaurants, JR Pass)';
      case TripBudget.luxury:   return 'luxury (ryokan, kaiseki, private transport, premium experiences)';
    }
  }
}
