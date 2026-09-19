import 'package:flutter_tts/flutter_tts.dart';

/// Singleton service for managing TTS across the app.
/// Ensures a single FlutterTts instance is used, reducing resource overhead.
class TtsService {
  static final TtsService _instance = TtsService._internal();

  factory TtsService() => _instance;

  TtsService._internal() : _tts = FlutterTts();

  final FlutterTts _tts;

  FlutterTts get tts => _tts;

  Future<void> setLanguage(String locale) => _tts.setLanguage(locale);
  Future<void> setSpeechRate(double rate) => _tts.setSpeechRate(rate);
  Future<void> setPitch(double pitch) => _tts.setPitch(pitch);
  Future<dynamic> speak(String text) => _tts.speak(text);
  Future<dynamic> stop() => _tts.stop();
  Future<dynamic> pause() => _tts.pause();

  void setStartHandler(Function() handler) => _tts.setStartHandler(handler);
  void setCompletionHandler(Function() handler) => _tts.setCompletionHandler(handler);
  void setErrorHandler(Function(dynamic) handler) => _tts.setErrorHandler(handler);
  void setProgressHandler(Function(String, int, int, String) handler) =>
      _tts.setProgressHandler(handler);

  Future<void> dispose() async {
    await _tts.stop();
  }
}

final ttsService = TtsService();
