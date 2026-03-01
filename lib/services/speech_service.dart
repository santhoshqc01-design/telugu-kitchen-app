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
      onError: (error) => print('Speech error: ${error.errorMsg}'),
      onStatus: (status) {
        print('Speech status: $status');
        if (status == 'done' || status == 'notListening') {
          _isListening = false;
        }
      },
      debugLogging: kIsWeb,
    );
  }

  Future<bool> startListening({
    required Function(String) onPartialResult,
    required Function(String) onFinalResult,
    String localeId = 'te_IN',
  }) async {
    if (!_isInitialized) await initialize();
    if (!_isInitialized) return false;

    _isListening = true;
    final effectiveLocale = kIsWeb && localeId == 'te_IN' ? 'en_US' : localeId;

    await _speechToText.listen(
      onResult: (SpeechRecognitionResult result) {
        if (result.finalResult) {
          _isListening = false;
          onFinalResult(result.recognizedWords);
        } else {
          onPartialResult(result.recognizedWords);
        }
      },
      localeId: effectiveLocale,
      listenOptions: SpeechListenOptions(
        cancelOnError: true,
        partialResults: true,
        listenMode: ListenMode.search,
      ),
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
