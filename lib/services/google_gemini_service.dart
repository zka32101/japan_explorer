import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:logger/logger.dart';
import 'claude_vision_service.dart';

class GeminiVisionService {
  static const _model = 'gemini-3.1-flash-lite';
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const _maxImageBytes = 1024 * 1024;

  final String _apiKey;
  final Dio _dio;
  final _logger = Logger();

  GeminiVisionService({required String apiKey})
      : _apiKey = apiKey,
        _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 30),
        ));

  static const _systemInstruction = '''You are a Japanese culture expert guide for international visitors.
Analyze the image and respond ONLY in this exact JSON format (no markdown, no extra text):
{
  "name": "Name of the place/object/food",
  "description": "2-3 sentence identification and cultural significance",
  "historical_background": "Concise history in 2-3 sentences",
  "how_to_experience": "Practical tips for visitors in 2-3 sentences",
  "phrase": {
    "japanese": "Japanese text",
    "romaji": "Romanized pronunciation",
    "english": "English translation and usage"
  }
}''';

  Future<CameraExplanation> explainImage({
    required File imageFile,
    String language = 'en',
    String? nearbySpotHint,
  }) async {
    final imageBase64 = await _compressAndEncode(imageFile);
    final mimeType = _getMimeType(imageFile.path);

    final hintText = nearbySpotHint != null
        ? ' Note: the user is physically near "$nearbySpotHint" — use this as context but verify from the image.'
        : '';

    final body = {
      'system_instruction': {
        'parts': [{'text': _systemInstruction}],
      },
      'contents': [
        {
          'parts': [
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': imageBase64,
              },
            },
            {
              'text':
                  'Explain this image for a Japan visitor. Language: $language$hintText',
            },
          ],
        }
      ],
      'generationConfig': {
        'maxOutputTokens': 600,
        'temperature': 0.4,
      },
    };

    final url =
        '$_baseUrl/$_model:generateContent?key=$_apiKey';
    final response = await _dio.post(url, data: body);

    final text = response.data['candidates'][0]['content']['parts'][0]['text']
        as String;
    return _parse(text);
  }

  Future<String> moderateText(String text) async {
    final body = {
      'contents': [
        {
          'parts': [
            {
              'text': '''Moderate this user post for a Japan travel community app.
Respond ONLY in JSON: {"status": "approved"|"flagged"|"rejected", "score": 0.0-1.0, "reason": "brief"}

Post: "$text"'''
            }
          ]
        }
      ],
      'generationConfig': {'maxOutputTokens': 100, 'temperature': 0.1},
    };

    final url =
        '$_baseUrl/gemini-3.1-flash-lite:generateContent?key=$_apiKey';
    final response = await _dio.post(url, data: body);
    return response.data['candidates'][0]['content']['parts'][0]['text']
        as String;
  }

  Future<String> _compressAndEncode(File file) async {
    final bytes = await file.readAsBytes();
    if (bytes.length <= _maxImageBytes) return base64Encode(bytes);

    final decoded = await compute(_decodeImage, bytes);
    if (decoded == null) return base64Encode(bytes);
    final resized = img.copyResize(decoded, width: 1024);
    return base64Encode(img.encodeJpg(resized, quality: 80));
  }

  static img.Image? _decodeImage(Uint8List bytes) => img.decodeImage(bytes);

  String _getMimeType(String path) {
    switch (path.toLowerCase().split('.').last) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  CameraExplanation _parse(String text) {
    try {
      final clean = text.replaceAll(RegExp(r'```json|```'), '').trim();
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(clean);
      if (jsonMatch == null) throw FormatException('No JSON');

      final json = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      final p = json['phrase'] as Map<String, dynamic>? ?? {};
      return CameraExplanation(
        name: json['name'] ?? 'Unknown',
        description: json['description'] ?? '',
        historicalBackground: json['historical_background'] ?? '',
        howToExperience: json['how_to_experience'] ?? '',
        phrase: JapanesePhrase(
          japanese: p['japanese'] ?? '',
          romaji: p['romaji'] ?? '',
          english: p['english'] ?? '',
        ),
        rawText: text,
      );
    } catch (_) {
      return CameraExplanation(
        name: 'Japan',
        description: text,
        historicalBackground: '',
        howToExperience: '',
        phrase: const JapanesePhrase(
          japanese: 'ありがとうございます',
          romaji: 'Arigatou gozaimasu',
          english: 'Thank you very much',
        ),
        rawText: text,
      );
    }
  }

  // フォールバックが必要なエラーかどうか判定
  static bool isFallbackRequired(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      // 429 Rate Limit, 5xx Server Error, 接続失敗はフォールバック
      if (status == null || status == 429 || status >= 500) return true;
      // 403 は APIキー無効 → フォールバック
      if (status == 403) return true;
    }
    return true; // 不明なエラーはすべてフォールバック
  }
}
