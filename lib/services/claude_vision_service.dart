import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class CameraExplanation {
  final String name;
  final String description;
  final String historicalBackground;
  final String howToExperience;
  final JapanesePhrase phrase;
  final String rawText;

  const CameraExplanation({
    required this.name,
    required this.description,
    required this.historicalBackground,
    required this.howToExperience,
    required this.phrase,
    required this.rawText,
  });
}

class JapanesePhrase {
  final String japanese;
  final String romaji;
  final String english;

  const JapanesePhrase({
    required this.japanese,
    required this.romaji,
    required this.english,
  });
}

class ClaudeVisionService {
  static const _model = 'claude-sonnet-4-6';
  static const _maxImageBytes = 1024 * 1024; // 1MB
  static const _maxTokens = 600;

  final Dio _dio;
  final String _apiKey;
  final _logger = Logger();

  // Prompt Caching 用のシステムプロンプト（共通背景知識）
  static const _systemPrompt = '''You are a Japanese culture expert guide for international visitors.
When given an image, identify and explain it with cultural depth.

Always respond in this exact JSON format:
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
}

Focus on making visitors feel connected to Japanese culture.
Be concise — the explanation should be readable in 2-3 minutes.''';

  ClaudeVisionService({required String apiKey})
      : _apiKey = apiKey,
        _dio = Dio(BaseOptions(
          baseUrl: 'https://api.anthropic.com/v1',
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
            'content-type': 'application/json',
          },
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ));

  Future<CameraExplanation> explainImage({
    required File imageFile,
    String language = 'en',
    String? nearbySpotHint,
  }) async {
    final imageBase64 = await _compressAndEncode(imageFile);
    final mediaType = _getMediaType(imageFile.path);

    final hintText = nearbySpotHint != null
        ? ' Note: the user is physically near "$nearbySpotHint" — use as context but verify from the image.'
        : '';

    final body = {
      'model': _model,
      'max_tokens': _maxTokens,
      'system': [
        {
          'type': 'text',
          'text': _systemPrompt,
          'cache_control': {'type': 'ephemeral'}, // Prompt Caching
        }
      ],
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image',
              'source': {
                'type': 'base64',
                'media_type': mediaType,
                'data': imageBase64,
              },
            },
            {
              'type': 'text',
              'text':
                  'Please explain what you see in this image. Language: $language$hintText',
            },
          ],
        }
      ],
    };

    try {
      final response = await _dio.post('/messages', data: body);
      final text = response.data['content'][0]['text'] as String;
      return _parseResponse(text);
    } on DioException catch (e) {
      _logger.e('Claude Vision API error', error: e);
      rethrow;
    }
  }

  Future<CameraExplanation> askFollowUp({
    required String originalExplanation,
    required String question,
    required String imageBase64,
    required String mediaType,
  }) async {
    final body = {
      'model': _model,
      'max_tokens': _maxTokens,
      'system': [
        {
          'type': 'text',
          'text': _systemPrompt,
          'cache_control': {'type': 'ephemeral'},
        }
      ],
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image',
              'source': {
                'type': 'base64',
                'media_type': mediaType,
                'data': imageBase64,
              },
            },
            {'type': 'text', 'text': 'Please explain this image.'},
          ],
        },
        {'role': 'assistant', 'content': originalExplanation},
        {
          'role': 'user',
          'content': question,
        },
      ],
    };

    final response = await _dio.post('/messages', data: body);
    final text = response.data['content'][0]['text'] as String;
    return _parseResponse(text);
  }

  Future<String> _compressAndEncode(File file) async {
    final bytes = await file.readAsBytes();

    if (bytes.length <= _maxImageBytes) {
      return base64Encode(bytes);
    }

    // 1MB超えたら圧縮
    final decoded = await compute(_decodeImage, bytes);
    if (decoded == null) return base64Encode(bytes);

    final resized = img.copyResize(decoded, width: 1024);
    final compressed = img.encodeJpg(resized, quality: 80);
    return base64Encode(compressed);
  }

  static img.Image? _decodeImage(Uint8List bytes) {
    return img.decodeImage(bytes);
  }

  String _getMediaType(String path) {
    final ext = path.toLowerCase().split('.').last;
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
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

  CameraExplanation _parseResponse(String text) {
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch == null) throw FormatException('No JSON in response');

      final json = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      final phraseData = json['phrase'] as Map<String, dynamic>? ?? {};

      return CameraExplanation(
        name: json['name'] ?? 'Unknown',
        description: json['description'] ?? '',
        historicalBackground: json['historical_background'] ?? '',
        howToExperience: json['how_to_experience'] ?? '',
        phrase: JapanesePhrase(
          japanese: phraseData['japanese'] ?? '',
          romaji: phraseData['romaji'] ?? '',
          english: phraseData['english'] ?? '',
        ),
        rawText: text,
      );
    } catch (e) {
      _logger.w('Failed to parse Claude response, using raw text: $e');
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
}
