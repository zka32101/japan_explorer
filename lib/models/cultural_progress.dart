import 'dart:ui' show Color;
import 'cultural_challenge.dart';

/// Aggregated quiz stats for one challenge category.
class CategoryProgress {
  final ChallengeCategory category;
  final int questionsAnswered;
  final int correctCount;
  final int xpEarned;

  const CategoryProgress({
    required this.category,
    this.questionsAnswered = 0,
    this.correctCount = 0,
    this.xpEarned = 0,
  });

  /// 0.0 – 1.0 correctness rate (0 if unanswered).
  double get accuracy =>
      questionsAnswered == 0 ? 0 : correctCount / questionsAnswered;

  /// Human-friendly mastery label.
  String get masteryLabel {
    if (questionsAnswered == 0) return 'Not started';
    final pct = accuracy;
    if (pct >= 0.9) return 'Expert';
    if (pct >= 0.7) return 'Proficient';
    if (pct >= 0.5) return 'Familiar';
    return 'Beginner';
  }

  Color get masteryColor {
    if (questionsAnswered == 0) return const Color(0xFFBDBDBD);
    final pct = accuracy;
    if (pct >= 0.9) return const Color(0xFF1B5E20);
    if (pct >= 0.7) return const Color(0xFF2E7D32);
    if (pct >= 0.5) return const Color(0xFFF57C00);
    return const Color(0xFFE53935);
  }

  factory CategoryProgress.fromJson(
      ChallengeCategory category, Map<String, dynamic> json) {
    return CategoryProgress(
      category: category,
      questionsAnswered: json['answered'] as int? ?? 0,
      correctCount: json['correct'] as int? ?? 0,
      xpEarned: json['xp'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'answered': questionsAnswered,
        'correct': correctCount,
        'xp': xpEarned,
      };

  CategoryProgress add({required bool correct, required int xp}) =>
      CategoryProgress(
        category: category,
        questionsAnswered: questionsAnswered + 1,
        correctCount: correctCount + (correct ? 1 : 0),
        xpEarned: xpEarned + xp,
      );
}

/// Full cultural progress summary for the progress dashboard.
class CulturalProgressSummary {
  final List<CategoryProgress> categories;
  final int scanCount;

  const CulturalProgressSummary({
    required this.categories,
    this.scanCount = 0,
  });

  int get totalQuestionsAnswered =>
      categories.fold(0, (s, c) => s + c.questionsAnswered);
  int get totalCorrect =>
      categories.fold(0, (s, c) => s + c.correctCount);
  int get totalXpFromChallenges =>
      categories.fold(0, (s, c) => s + c.xpEarned);

  double get overallAccuracy => totalQuestionsAnswered == 0
      ? 0
      : totalCorrect / totalQuestionsAnswered;

  static CulturalProgressSummary empty() => CulturalProgressSummary(
        categories: ChallengeCategory.values
            .map((c) => CategoryProgress(category: c))
            .toList(),
      );
}
