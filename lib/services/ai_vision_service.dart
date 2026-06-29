import 'dart:io';
import 'package:logger/logger.dart';
import 'claude_vision_service.dart';
import 'google_gemini_service.dart';

enum AiProvider { gemini, claude }

class AiVisionResult {
  final CameraExplanation explanation;
  final AiProvider provider;
  final bool usedFallback;

  const AiVisionResult({
    required this.explanation,
    required this.provider,
    required this.usedFallback,
  });
}

/// Google Gemini Flash（廉価）→ Claude フォールバック
class AiVisionService {
  final GeminiVisionService _gemini;
  final ClaudeVisionService _claude;
  final _logger = Logger();

  AiVisionService({
    required GeminiVisionService gemini,
    required ClaudeVisionService claude,
  })  : _gemini = gemini,
        _claude = claude;

  Future<AiVisionResult> explainImage({
    required File imageFile,
    String language = 'en',
    String? nearbySpotHint,
  }) async {
    // 1st: Gemini Flash（廉価）
    try {
      _logger.d('Trying Gemini Flash...');
      final explanation = await _gemini.explainImage(
        imageFile: imageFile,
        language: language,
        nearbySpotHint: nearbySpotHint,
      );
      _logger.i('Gemini Flash succeeded');
      return AiVisionResult(
        explanation: explanation,
        provider: AiProvider.gemini,
        usedFallback: false,
      );
    } catch (e) {
      if (!GeminiVisionService.isFallbackRequired(e)) rethrow;
      _logger.w('Gemini failed ($e), falling back to Claude...');
    }

    // 2nd: Claude（フォールバック）
    final explanation = await _claude.explainImage(
      imageFile: imageFile,
      language: language,
      nearbySpotHint: nearbySpotHint,
    );
    _logger.i('Claude fallback succeeded');
    return AiVisionResult(
      explanation: explanation,
      provider: AiProvider.claude,
      usedFallback: true,
    );
  }

  Future<AiVisionResult> askFollowUp({
    required String originalExplanation,
    required String question,
    required String imageBase64,
    required String mediaType,
  }) async {
    // フォローアップは Claude を直接使用（会話継続のため）
    final explanation = await _claude.askFollowUp(
      originalExplanation: originalExplanation,
      question: question,
      imageBase64: imageBase64,
      mediaType: mediaType,
    );
    return AiVisionResult(
      explanation: explanation,
      provider: AiProvider.claude,
      usedFallback: false,
    );
  }
}
