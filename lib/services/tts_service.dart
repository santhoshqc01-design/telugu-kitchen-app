import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class TTSService {
  late FlutterTts _flutterTts;
  bool _isInitialized = false;
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  Future<void> initialize() async {
    _flutterTts = FlutterTts();

    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);

    if (kIsWeb) {
      await _flutterTts.awaitSpeakCompletion(true);
    }

    // Track speaking state
    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
    });

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
    });

    _flutterTts.setCancelHandler(() {
      _isSpeaking = false;
    });

    _isInitialized = true;
  }

  Future<void> speak(
    String text, {
    String language = 'te-IN',
    double rate = 0.5,
  }) async {
    if (!_isInitialized) await initialize();

    // Prevent overlapping speech
    await _flutterTts.stop();

    if (kIsWeb) {
      final languages = await _flutterTts.getLanguages;
      final langToUse = languages.contains(language) ? language : 'en-US';
      await _flutterTts.setLanguage(langToUse);
    } else {
      await _flutterTts.setLanguage(language);
    }

    await _flutterTts.setSpeechRate(rate);
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    if (!_isInitialized) return;
    await _flutterTts.stop();
    _isSpeaking = false;
  }

  /// Optional: Wait until speaking completes
  Future<void> waitForCompletion() async {
    if (!_isInitialized) return;
    while (_isSpeaking) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
}
