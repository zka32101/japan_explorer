import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/audio_guide.dart';
import '../services/audio_guide_service.dart';

const _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
const _claudeApiKey = String.fromEnvironment('CLAUDE_API_KEY');

final audioGuideServiceProvider = Provider<AudioGuideService>((ref) {
  return AudioGuideService(
    geminiKey: _geminiApiKey,
    claudeKey: _claudeApiKey,
  );
});

// ── State ─────────────────────────────────────────────────────────────────────

enum AudioGuidePlayback { idle, playing, paused }

class AudioGuideState {
  final String curationId;
  final AudioGuide? guide;
  final bool isGenerating;
  final bool isCached; // true = loaded from cache, no network needed
  final AudioGuidePlayback playback;
  final double speechRate; // 0.5 – 1.5
  final String language;
  final String? error;
  final int highlightParagraph; // currently-reading paragraph index

  const AudioGuideState({
    required this.curationId,
    this.guide,
    this.isGenerating = false,
    this.isCached = false,
    this.playback = AudioGuidePlayback.idle,
    this.speechRate = 1.0,
    this.language = 'en',
    this.error,
    this.highlightParagraph = 0,
  });

  bool get isPlaying => playback == AudioGuidePlayback.playing;
  bool get isPaused => playback == AudioGuidePlayback.paused;
  bool get hasGuide => guide != null;

  AudioGuideState copyWith({
    AudioGuide? guide,
    bool? isGenerating,
    bool? isCached,
    AudioGuidePlayback? playback,
    double? speechRate,
    String? language,
    String? error,
    int? highlightParagraph,
  }) =>
      AudioGuideState(
        curationId: curationId,
        guide: guide ?? this.guide,
        isGenerating: isGenerating ?? this.isGenerating,
        isCached: isCached ?? this.isCached,
        playback: playback ?? this.playback,
        speechRate: speechRate ?? this.speechRate,
        language: language ?? this.language,
        error: error,
        highlightParagraph: highlightParagraph ?? this.highlightParagraph,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AudioGuideNotifier extends StateNotifier<AudioGuideState> {
  final AudioGuideService _service;
  final FlutterTts _tts = FlutterTts();
  int _currentParagraph = 0;

  AudioGuideNotifier(this._service, String curationId)
      : super(AudioGuideState(curationId: curationId)) {
    _initTts();
  }

  void _initTts() {
    _tts.setCompletionHandler(() {
      if (mounted) {
        state = state.copyWith(
            playback: AudioGuidePlayback.idle, highlightParagraph: 0);
        _currentParagraph = 0;
      }
    });
  }

  // ── Language ──────────────────────────────────────────────────────────────

  void setLanguage(String lang) {
    state = state.copyWith(language: lang);
    _tts.setLanguage(_ttsLocale(lang));
  }

  // ── Generate ──────────────────────────────────────────────────────────────

  Future<void> generate({
    required String title,
    required String description,
    required String city,
    required String category,
  }) async {
    if (state.isGenerating) return;

    // Check cache first (instant)
    final cached =
        await _service.getCached(state.curationId, state.language);
    if (cached != null) {
      state = state.copyWith(guide: cached, isCached: true);
      return;
    }

    state = state.copyWith(isGenerating: true, error: null);
    try {
      final guide = await _service.generate(
        curationId: state.curationId,
        title: title,
        description: description,
        city: city,
        category: category,
        language: state.language,
      );
      state = state.copyWith(
          guide: guide, isGenerating: false, isCached: false);
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        error: 'Failed to generate audio guide. Please try again.',
      );
    }
  }

  // ── Playback ─────────────────────────────────────────────────────────────

  Future<void> play() async {
    final guide = state.guide;
    if (guide == null) return;

    await _tts.setLanguage(_ttsLocale(state.language));
    await _tts.setSpeechRate(state.speechRate);
    await _tts.setPitch(1.0);

    if (state.isPaused) {
      // Resume — re-speak from current paragraph
      final paragraphs = guide.paragraphs;
      if (_currentParagraph < paragraphs.length) {
        final remaining =
            paragraphs.sublist(_currentParagraph).join('\n\n');
        await _tts.speak(remaining);
        state = state.copyWith(playback: AudioGuidePlayback.playing);
      }
    } else {
      // Fresh play — speak paragraph by paragraph so we can track position
      _currentParagraph = 0;
      state = state.copyWith(
          playback: AudioGuidePlayback.playing, highlightParagraph: 0);
      _speakNextParagraph(guide);
    }
  }

  void _speakNextParagraph(AudioGuide guide) {
    final paragraphs = guide.paragraphs;
    if (_currentParagraph >= paragraphs.length) {
      state = state.copyWith(
          playback: AudioGuidePlayback.idle, highlightParagraph: 0);
      _currentParagraph = 0;
      return;
    }

    state =
        state.copyWith(highlightParagraph: _currentParagraph);

    _tts.setCompletionHandler(() {
      if (!mounted) return;
      _currentParagraph++;
      if (state.isPlaying) {
        _speakNextParagraph(guide);
      }
    });

    _tts.speak(paragraphs[_currentParagraph]);
  }

  Future<void> pause() async {
    await _tts.pause();
    state = state.copyWith(playback: AudioGuidePlayback.paused);
  }

  Future<void> stop() async {
    await _tts.stop();
    _currentParagraph = 0;
    state = state.copyWith(
        playback: AudioGuidePlayback.idle, highlightParagraph: 0);
  }

  Future<void> setSpeechRate(double rate) async {
    final clampedRate = rate.clamp(0.4, 1.6);
    state = state.copyWith(speechRate: clampedRate);
    if (state.isPlaying) {
      await _tts.setSpeechRate(clampedRate);
    }
  }

  Future<void> regenerate({
    required String title,
    required String description,
    required String city,
    required String category,
  }) async {
    await _service.clearCache(state.curationId, state.language);
    state = state.copyWith(guide: null, isCached: false, error: null);
    await generate(
        title: title, description: description, city: city, category: category);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _ttsLocale(String lang) {
    switch (lang) {
      case 'ja': return 'ja-JP';
      case 'zh': return 'zh-CN';
      case 'ko': return 'ko-KR';
      case 'fr': return 'fr-FR';
      default:   return 'en-US';
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}

// ── Provider factory ──────────────────────────────────────────────────────────

final audioGuideProvider = StateNotifierProvider.family<
    AudioGuideNotifier, AudioGuideState, String>(
  (ref, curationId) =>
      AudioGuideNotifier(ref.read(audioGuideServiceProvider), curationId),
);
