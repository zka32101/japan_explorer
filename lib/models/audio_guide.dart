/// A cached AI-generated audio guide script for a cultural spot.
class AudioGuide {
  final String curationId;
  final String curationTitle;
  final String script;
  final String language;
  final int estimatedDurationSeconds; // rough estimate at ~130 wpm
  final DateTime generatedAt;

  const AudioGuide({
    required this.curationId,
    required this.curationTitle,
    required this.script,
    required this.language,
    required this.estimatedDurationSeconds,
    required this.generatedAt,
  });

  /// Words in the script, split for display.
  List<String> get words => script.split(RegExp(r'\s+'));

  /// Paragraphs for the scrolling transcript view.
  List<String> get paragraphs =>
      script.split('\n\n').where((p) => p.trim().isNotEmpty).toList();

  factory AudioGuide.fromJson(Map<String, dynamic> json) => AudioGuide(
        curationId: json['curation_id'] as String,
        curationTitle: json['curation_title'] as String,
        script: json['script'] as String,
        language: json['language'] as String,
        estimatedDurationSeconds: json['duration_s'] as int? ?? 120,
        generatedAt:
            DateTime.parse(json['generated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'curation_id': curationId,
        'curation_title': curationTitle,
        'script': script,
        'language': language,
        'duration_s': estimatedDurationSeconds,
        'generated_at': generatedAt.toIso8601String(),
      };

  static int estimateDuration(String script) {
    final words = script.split(RegExp(r'\s+')).length;
    return (words / 130 * 60).round(); // 130 words/min
  }
}
