import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/scan_history.dart';
import '../services/ai_vision_service.dart';
import '../services/claude_vision_service.dart';
import '../services/firebase_service.dart';
import '../services/google_gemini_service.dart';
import '../utils/constants.dart';
import 'auth_provider.dart';

const _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
const _claudeApiKey = String.fromEnvironment('CLAUDE_API_KEY');

const _langPrefKey = 'camera_language';
const _uuid = Uuid();

final aiVisionServiceProvider = Provider<AiVisionService>((ref) {
  return AiVisionService(
    gemini: GeminiVisionService(apiKey: _geminiApiKey),
    claude: ClaudeVisionService(apiKey: _claudeApiKey),
  );
});

// ── Supported response languages ─────────────────────────────────────────────
const cameraLanguages = <String, String>{
  'en': '🇬🇧 EN',
  'ja': '🇯🇵 JA',
  'zh': '🇨🇳 ZH',
  'ko': '🇰🇷 KO',
  'fr': '🇫🇷 FR',
};

// ── CameraState ───────────────────────────────────────────────────────────────

class CameraState {
  final File? capturedImage;
  final CameraExplanation? explanation;
  final bool isAnalyzing;
  final String? error;
  final String? imageBase64;
  final String mediaType;
  final AiProvider? lastProvider;
  final bool usedFallback;
  final String language;
  final bool xpAwarded;
  // Level-up / badge-unlock feedback (shown once then cleared)
  final bool leveledUp;
  final int? newLevel;
  final List<String> newBadgeIds;

  const CameraState({
    this.capturedImage,
    this.explanation,
    this.isAnalyzing = false,
    this.error,
    this.imageBase64,
    this.mediaType = 'image/jpeg',
    this.lastProvider,
    this.usedFallback = false,
    this.language = 'en',
    this.xpAwarded = false,
    this.leveledUp = false,
    this.newLevel,
    this.newBadgeIds = const [],
  });

  CameraState copyWith({
    File? capturedImage,
    CameraExplanation? explanation,
    bool? isAnalyzing,
    String? error,
    String? imageBase64,
    String? mediaType,
    AiProvider? lastProvider,
    bool? usedFallback,
    String? language,
    bool? xpAwarded,
    bool? leveledUp,
    int? newLevel,
    List<String>? newBadgeIds,
  }) =>
      CameraState(
        capturedImage: capturedImage ?? this.capturedImage,
        explanation: explanation ?? this.explanation,
        isAnalyzing: isAnalyzing ?? this.isAnalyzing,
        error: error,
        imageBase64: imageBase64 ?? this.imageBase64,
        mediaType: mediaType ?? this.mediaType,
        lastProvider: lastProvider ?? this.lastProvider,
        usedFallback: usedFallback ?? this.usedFallback,
        language: language ?? this.language,
        xpAwarded: xpAwarded ?? this.xpAwarded,
        leveledUp: leveledUp ?? this.leveledUp,
        newLevel: newLevel ?? this.newLevel,
        newBadgeIds: newBadgeIds ?? this.newBadgeIds,
      );

  CameraState reset() => CameraState(language: language); // preserve language
  CameraState clearFeedback() => copyWith(
        leveledUp: false,
        newLevel: null,
        newBadgeIds: [],
      );
}

// ── CameraNotifier ────────────────────────────────────────────────────────────

class CameraNotifier extends StateNotifier<CameraState> {
  final AiVisionService _service;
  final Ref _ref;

  CameraNotifier(this._service, this._ref) : super(const CameraState()) {
    _loadLanguagePref();
  }

  Future<void> _loadLanguagePref() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_langPrefKey) ?? 'en';
    state = state.copyWith(language: saved);
  }

  Future<void> setLanguage(String lang) async {
    state = state.copyWith(language: lang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langPrefKey, lang);
  }

  Future<void> analyzeImage(
    File image, {
    String? nearbyCurationId,
    String? nearbyCurationName,
  }) async {
    // Pre-encode to base64 so follow-up questions can reuse the same image
    final bytes = await image.readAsBytes();
    final base64Image = base64Encode(bytes);
    final ext = image.path.split('.').last.toLowerCase();
    final mediaType = ext == 'png' ? 'image/png' : 'image/jpeg';

    state = state.copyWith(
      capturedImage: image,
      isAnalyzing: true,
      error: null,
      explanation: null,
      imageBase64: base64Image,
      mediaType: mediaType,
      xpAwarded: false,
    );

    try {
      final result = await _service.explainImage(
        imageFile: image,
        language: state.language,
        nearbySpotHint: nearbyCurationName,
      );

      state = state.copyWith(
        isAnalyzing: false,
        explanation: result.explanation,
        lastProvider: result.provider,
        usedFallback: result.usedFallback,
      );

      // Side-effects: XP + scan history (fire-and-forget)
      _awardXp();
      _saveScanRecord(
        result,
        image.path,
        nearbyCurationId: nearbyCurationId,
      );
    } catch (e) {
      state = state.copyWith(
        isAnalyzing: false,
        error: 'Failed to analyze image. Please try again.',
      );
    }
  }

  Future<void> _awardXp() async {
    if (state.xpAwarded) return;
    try {
      final user = _ref.read(appUserProvider).valueOrNull;
      if (user == null) return;
      final service = _ref.read(firebaseServiceProvider);
      final result =
          await service.updateUserXP(user.uid, AppConstants.xpSpotVisit);

      state = state.copyWith(
        xpAwarded: true,
        leveledUp: result.leveledUp,
        newLevel: result.newLevel,
        newBadgeIds: result.newBadgeIds,
      );

      // Check ai_explorer badge: 20 scans
      _checkAiExplorerBadge(user.uid, service);
    } catch (_) {
      // Non-critical — don't break the camera flow
    }
  }

  Future<void> _checkAiExplorerBadge(
      String userId, FirebaseService service) async {
    try {
      final scans = await scanHistoryRepository.getAll();
      if (scans.length >= 20) {
        final awarded = await service.awardBadgeIfNew(userId, 'ai_explorer');
        if (awarded.isNotEmpty) {
          // Append to existing badge list if present
          final updated = [...state.newBadgeIds, ...awarded];
          state = state.copyWith(newBadgeIds: updated);
        }
      }
    } catch (_) {}
  }

  void clearFeedback() => state = state.clearFeedback();

  Future<void> _saveScanRecord(
    AiVisionResult result,
    String imagePath, {
    String? nearbyCurationId,
  }) async {
    try {
      final exp = result.explanation;
      final record = ScanRecord(
        id: _uuid.v4(),
        landmarkName: exp.name,
        description: exp.description,
        historicalBackground: exp.historicalBackground,
        howToExperience: exp.howToExperience,
        phraseJapanese: exp.phrase.japanese,
        phraseRomaji: exp.phrase.romaji,
        phraseEnglish: exp.phrase.english,
        scannedAt: DateTime.now(),
        provider: result.provider == AiProvider.gemini ? 'gemini' : 'claude',
        imagePath: imagePath,
        nearbyCurationId: nearbyCurationId,
      );
      await scanHistoryRepository.add(record);
    } catch (_) {}
  }

  Future<void> askFollowUp(String question) async {
    final current = state.explanation;
    final imageBase64 = state.imageBase64;
    if (current == null || imageBase64 == null) return;

    state = state.copyWith(isAnalyzing: true, error: null);
    try {
      final result = await _service.askFollowUp(
        originalExplanation: current.rawText,
        question: question,
        imageBase64: imageBase64,
        mediaType: state.mediaType,
      );
      state = state.copyWith(
        isAnalyzing: false,
        explanation: result.explanation,
        lastProvider: result.provider,
      );
    } catch (e) {
      state = state.copyWith(
        isAnalyzing: false,
        error: 'Failed to get answer. Please try again.',
      );
    }
  }

  void reset() => state = state.reset();
}

final cameraNotifierProvider =
    StateNotifierProvider<CameraNotifier, CameraState>((ref) {
  return CameraNotifier(ref.read(aiVisionServiceProvider), ref);
});
