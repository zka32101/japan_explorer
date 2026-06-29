import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/audio_guide.dart';

class AudioGuideService {
  static const _geminiModel = 'gemini-3.1-flash-lite';
  static const _geminiBase =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const _claudeModel = 'claude-sonnet-4-6';
  static const _claudeBase = 'https://api.anthropic.com/v1';

  final String _geminiKey;
  final String _claudeKey;
  final Dio _dio;
  final _logger = Logger();

  AudioGuideService({required String geminiKey, required String claudeKey})
      : _geminiKey = geminiKey,
        _claudeKey = claudeKey,
        _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ));

  // ── Cache key ──────────────────────────────────────────────────────────────

  static String _cacheKey(String curationId, String language) =>
      'audio_guide_v1_${curationId}_$language';

  /// Returns a cached guide if available (up to 30 days old).
  Future<AudioGuide?> getCached(String curationId, String language) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey(curationId, language));
    if (raw == null) return null;
    try {
      final guide = AudioGuide.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
      // Expire after 30 days
      if (DateTime.now().difference(guide.generatedAt).inDays > 30) {
        return null;
      }
      return guide;
    } catch (_) {
      return null;
    }
  }

  Future<void> _cache(AudioGuide guide) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _cacheKey(guide.curationId, guide.language),
        jsonEncode(guide.toJson()));
  }

  // ── Generation ─────────────────────────────────────────────────────────────

  Future<AudioGuide> generate({
    required String curationId,
    required String title,
    required String description,
    required String city,
    required String category,
    required String language,
  }) async {
    // 1. Try cache
    final cached = await getCached(curationId, language);
    if (cached != null) return cached;

    // 2. Build prompt
    final prompt = _buildPrompt(
      title: title,
      description: description,
      city: city,
      category: category,
      language: language,
    );

    String script;

    // 3. Gemini first
    try {
      _logger.d('Generating audio guide with Gemini...');
      script = await _geminiGenerate(prompt);
      _logger.i('Gemini audio guide generated');
    } catch (e) {
      _logger.w('Gemini failed ($e), falling back to Claude...');
      script = await _claudeGenerate(prompt);
      _logger.i('Claude audio guide generated');
    }

    script = _cleanScript(script);

    final guide = AudioGuide(
      curationId: curationId,
      curationTitle: title,
      script: script,
      language: language,
      estimatedDurationSeconds: AudioGuide.estimateDuration(script),
      generatedAt: DateTime.now(),
    );

    await _cache(guide);
    return guide;
  }

  String _buildPrompt({
    required String title,
    required String description,
    required String city,
    required String category,
    required String language,
  }) {
    final langInstruction = language == 'ja'
        ? 'Write in Japanese.'
        : language == 'zh'
            ? 'Write in Simplified Chinese.'
            : language == 'ko'
                ? 'Write in Korean.'
                : language == 'fr'
                    ? 'Write in French.'
                    : 'Write in English.';

    return '''You are a warm, knowledgeable Japan cultural guide narrator.
Create an engaging 2-minute audio guide script for: $title ($category) in $city, Japan.

Background: $description

$langInstruction

The script must:
- Open with a vivid, atmospheric sentence that transports the listener
- Cover the cultural and historical significance (about 60 seconds when spoken)
- Share one fascinating story, legend, or little-known fact
- Give two practical visitor tips (best time to visit, hidden gem nearby, etc.)
- Close with an inspiring reflection on what this place means to Japan

IMPORTANT: Return ONLY the spoken script — no section headers, no labels, no markdown, no meta-commentary. Write as flowing narration with natural paragraph breaks (blank line between paragraphs). Aim for 250–300 words. Use short, speakable sentences.''';
  }

  Future<String> _geminiGenerate(String prompt) async {
    final url = '$_geminiBase/$_geminiModel:generateContent?key=$_geminiKey';
    final body = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'maxOutputTokens': 1024,
        'temperature': 0.8,
      },
    };
    final response = await _dio.post(url, data: body);
    return response.data['candidates'][0]['content']['parts'][0]['text']
        as String;
  }

  Future<String> _claudeGenerate(String prompt) async {
    final response = await _dio.post(
      '$_claudeBase/messages',
      options: Options(headers: {
        'x-api-key': _claudeKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      }),
      data: {
        'model': _claudeModel,
        'max_tokens': 1024,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
      },
    );
    return response.data['content'][0]['text'] as String;
  }

  String _cleanScript(String raw) {
    return raw
        .replaceAll(RegExp(r'```.*?```', dotAll: true), '')
        .replaceAll(RegExp(r'#+\s.*\n'), '') // remove markdown headers
        .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'\1') // remove bold
        .trim();
  }

  /// Clears cached guide (e.g. to force regeneration).
  Future<void> clearCache(String curationId, String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey(curationId, language));
  }
}
