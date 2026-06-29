/// A seasonal event or natural phenomenon in Japan.
class SeasonEvent {
  final String id;
  final String emoji;
  final String title;
  final String titleJa;
  final String description;
  final String tip;
  final SeasonType season;

  /// Month+day window (inclusive). Day 0 means "entire month".
  final int startMonth;
  final int startDay;
  final int endMonth;
  final int endDay;

  const SeasonEvent({
    required this.id,
    required this.emoji,
    required this.title,
    required this.titleJa,
    required this.description,
    required this.tip,
    required this.season,
    required this.startMonth,
    required this.startDay,
    required this.endMonth,
    required this.endDay,
  });

  /// Returns true if [date] falls within this event's window.
  bool isActive(DateTime date) {
    final start = _toOrdinal(startMonth, startDay == 0 ? 1 : startDay);
    final end = _toOrdinal(endMonth, endDay == 0 ? 28 : endDay);
    final current = _toOrdinal(date.month, date.day);

    if (start <= end) {
      return current >= start && current <= end;
    }
    // Wraps around the year (e.g. Dec–Jan)
    return current >= start || current <= end;
  }

  static int _toOrdinal(int month, int day) => month * 100 + day;
}

enum SeasonType {
  spring,
  summer,
  autumn,
  winter,
  yearRound,
}

extension SeasonTypeExt on SeasonType {
  String get label {
    switch (this) {
      case SeasonType.spring:
        return 'Spring';
      case SeasonType.summer:
        return 'Summer';
      case SeasonType.autumn:
        return 'Autumn';
      case SeasonType.winter:
        return 'Winter';
      case SeasonType.yearRound:
        return 'Year Round';
    }
  }

  String get emoji {
    switch (this) {
      case SeasonType.spring:
        return '🌸';
      case SeasonType.summer:
        return '☀️';
      case SeasonType.autumn:
        return '🍁';
      case SeasonType.winter:
        return '❄️';
      case SeasonType.yearRound:
        return '🗾';
    }
  }
}
