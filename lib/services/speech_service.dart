import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SpeechService {
  late SpeechToText _speechToText;
  bool _isInitialized = false;
  bool _isListening = false;

  Future<void> initialize() async {
    _speechToText = SpeechToText();
    _isInitialized = await _speechToText.initialize(
      onError: (error) => print('Speech error: $error'),
      onStatus: (status) => print('Speech status: $status'),
      debugLogging: kIsWeb,
    );
  }

  Future<bool> startListening({
    required Function(String) onResult,
    String localeId = 'te_IN',
  }) async {
    if (!_isInitialized) await initialize();
    if (_isListening) return false;

    _isListening = true;
    final effectiveLocale = kIsWeb && localeId == 'te_IN' ? 'en_US' : localeId;

    await _speechToText.listen(
      onResult: (SpeechRecognitionResult result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
          _isListening = false;
        }
      },
      localeId: effectiveLocale,
    );

    return true;
  }

  Future<void> stopListening() async {
    if (!_isListening) return;
    await _speechToText.stop();
    _isListening = false;
  }

  bool get isListening => _isListening;
  bool get isAvailable => _isInitialized;
}
