import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../models/ai_itinerary.dart';

class AiPlannerService {
  static const _geminiModel = 'gemini-3.1-flash-lite';
  static const _geminiBase =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const _claudeModel = 'claude-sonnet-4-6';
  static const _claudeBase = 'https://api.anthropic.com/v1';

  final String _geminiKey;
  final String _claudeKey;
  final Dio _dio;
  final _logger = Logger();

  AiPlannerService({required String geminiKey, required String claudeKey})
      : _geminiKey = geminiKey,
        _claudeKey = claudeKey,
        _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 90),
        ));

  Future<AiItinerary> generateItinerary(TripPreferences prefs) async {
    final prompt = _buildPrompt(prefs);

    // 1st: Gemini Flash
    try {
      _logger.d('Generating itinerary with Gemini...');
      final json = await _geminiGenerate(prompt);
      _logger.i('Gemini itinerary generated');
      return AiItinerary.fromJson(json, prefs.city, prefs.days);
    } catch (e) {
      _logger.w('Gemini failed ($e), falling back to Claude...');
    }

    // 2nd: Claude fallback
    _logger.d('Generating itinerary with Claude...');
    final json = await _claudeGenerate(prompt);
    _logger.i('Claude itinerary generated');
    return AiItinerary.fromJson(json, prefs.city, prefs.days);
  }

  String _buildPrompt(TripPreferences prefs) {
    final interestStr = prefs.interests.join(', ');
    return '''Create a ${prefs.days}-day travel itinerary for ${prefs.city}, Japan.

Traveler interests: $interestStr
Budget level: ${prefs.budget.aiDescription}
Response language: ${prefs.language}

Return ONLY valid JSON with this exact structure (no markdown, no extra text):
{
  "trip_title": "${prefs.days} Days in ${prefs.city}",
  "overview": "2-3 sentence description of this trip",
  "days": [
    {
      "day": 1,
      "theme": "Short thematic title for the day",
      "morning": {
        "spot": "Spot name in English",
        "area": "Neighborhood or area",
        "description": "2 sentences on what to do and why it's special",
        "tip": "One practical visitor tip",
        "duration": "Xh"
      },
      "afternoon": { same structure },
      "evening": { same structure },
      "lunch_tip": "Brief lunch recommendation near the afternoon area",
      "transport_tip": "How to get between morning and afternoon spots"
    }
  ],
  "general_tips": ["tip 1", "tip 2", "tip 3"],
  "budget_note": "Rough daily cost estimate"
}

Include exactly ${prefs.days} days. Each day should have morning, afternoon, and evening activities. Focus on the interests: $interestStr. Vary the neighborhoods each day. Make tips specific and practical.''';
  }

  Future<Map<String, dynamic>> _geminiGenerate(String prompt) async {
    final url = '$_geminiBase/$_geminiModel:generateContent?key=$_geminiKey';
    final body = {
      'contents': [
        {
          'parts': [{'text': prompt}]
        }
      ],
      'generationConfig': {
        'maxOutputTokens': 4096,
        'temperature': 0.7,
      },
    };

    final response = await _dio.post(url, data: body);
    final text = response.data['candidates'][0]['content']['parts'][0]['text']
        as String;
    return _parseJson(text);
  }

  Future<Map<String, dynamic>> _claudeGenerate(String prompt) async {
    final response = await _dio.post(
      '$_claudeBase/messages',
      options: Options(headers: {
        'x-api-key': _claudeKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      }),
      data: {
        'model': _claudeModel,
        'max_tokens': 4096,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
      },
    );
    final text = response.data['content'][0]['text'] as String;
    return _parseJson(text);
  }

  Map<String, dynamic> _parseJson(String text) {
    // Strip markdown code fences if present
    final clean = text
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();
    final match = RegExp(r'\{[\s\S]*\}').firstMatch(clean);
    if (match == null) throw FormatException('No JSON found in response');
    return jsonDecode(match.group(0)!) as Map<String, dynamic>;
  }
}
