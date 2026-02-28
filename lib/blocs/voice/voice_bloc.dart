import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/tts_service.dart';
import '../../services/speech_service.dart';

part 'voice_event.dart';
part 'voice_state.dart';

class VoiceBloc extends Bloc<VoiceEvent, VoiceState> {
  final TTSService _ttsService;
  final SpeechService _speechService;

  /// Whether the current listening session should emit VoiceSearchResult
  /// (true) or run through the command parser (false).
  bool _isSearchMode = false;

  VoiceBloc({
    required TTSService ttsService,
    required SpeechService speechService,
  })  : _ttsService = ttsService,
        _speechService = speechService,
        super(const VoiceInitial()) {
    on<InitializeVoice>(_onInitializeVoice);
    on<StartListening>(_onStartListening);
    on<StopListening>(_onStopListening);
    on<SpeechResultReceived>(_onSpeechResultReceived);
    on<SpeakText>(_onSpeakText);
    on<StopSpeaking>(_onStopSpeaking);
    on<ProcessVoiceCommand>(_onProcessVoiceCommand);
  }

  // ── Initialization ─────────────────────────────────────────────────────────

  Future<void> _onInitializeVoice(
    InitializeVoice event,
    Emitter<VoiceState> emit,
  ) async {
    try {
      await _ttsService.initialize();
      await _speechService.initialize();
      emit(const VoiceReady());
    } catch (e) {
      emit(VoiceError('Failed to initialize voice: $e'));
    }
  }

  // ── Listening ──────────────────────────────────────────────────────────────

  Future<void> _onStartListening(
    StartListening event,
    Emitter<VoiceState> emit,
  ) async {
    _isSearchMode = event.isSearchMode;
    emit(const VoiceListening());
    try {
      await _speechService.startListening(
        onResult: (text) => add(SpeechResultReceived(text)),
        localeId: event.localeId,
      );
    } catch (e) {
      emit(VoiceError('Could not start microphone: $e'));
    }
  }

  Future<void> _onStopListening(
    StopListening event,
    Emitter<VoiceState> emit,
  ) async {
    await _speechService.stopListening();
    emit(const VoiceReady());
  }

  // ── Speech Result ──────────────────────────────────────────────────────────

  void _onSpeechResultReceived(
    SpeechResultReceived event,
    Emitter<VoiceState> emit,
  ) {
    if (_isSearchMode) {
      emit(VoiceSearchResult(event.text));
    } else {
      emit(VoiceTextRecognized(event.text));
      add(ProcessVoiceCommand(event.text));
    }
  }

  // ── TTS ────────────────────────────────────────────────────────────────────

  Future<void> _onSpeakText(
    SpeakText event,
    Emitter<VoiceState> emit,
  ) async {
    emit(const VoiceSpeaking());
    try {
      await _ttsService.speak(
        event.text,
        language: event.language ?? 'en-US',
        rate: event.rate,
      );
    } finally {
      emit(const VoiceReady());
    }

    // After reading a cooking step, check if it mentions a cook time.
    // CookingModeScreen listens for VoiceTimerSuggested and can auto-start
    // its timer. The screen owns the countdown state — this is advisory only.
    if (event.suggestTimer) {
      final seconds = _extractTimerSeconds(event.text);
      if (seconds != null) emit(VoiceTimerSuggested(seconds));
    }
  }

  Future<void> _onStopSpeaking(
    StopSpeaking event,
    Emitter<VoiceState> emit,
  ) async {
    await _ttsService.stop();
    emit(const VoiceReady());
  }

  // ── Command Parser ─────────────────────────────────────────────────────────
  //
  // Commands consumed by CookingModeScreen's BlocListener.
  // To add a command: add keywords here AND a case in cooking_mode_screen.dart.

  static const _commands = <String, List<String>>{
    'next_step': ['next', 'తర్వాత', 'తరువాతి', 'forward'],
    'previous_step': ['previous', 'back', 'వెనక', 'వెనక్కి', 'మునుపటి'],
    'repeat': ['repeat', 'మళ్ళీ', 'తిరిగి', 'again'],
    'start_timer': ['timer', 'start timer', 'టైమర్', 'begin'],
    'pause_timer': ['pause', 'pause timer', 'పాజ్', 'wait', 'hold'],
    'stop': ['stop', 'ఆపు', 'ఆగు', 'quit', 'exit', 'cancel'],
    'show_ingredients': ['ingredients', 'పదార్థాలు', 'list', 'జాబితా'],
  };

  void _onProcessVoiceCommand(
    ProcessVoiceCommand event,
    Emitter<VoiceState> emit,
  ) {
    final input = event.command.toLowerCase().trim();
    for (final entry in _commands.entries) {
      if (entry.value.any((kw) => input.contains(kw))) {
        emit(VoiceCommandExecuted(entry.key));
        return;
      }
    }
    emit(VoiceCommandUnknown(event.command));
  }

  // ── Timer Extraction ───────────────────────────────────────────────────────
  // Parses "cook for 5 minutes", "fry 2 min", "5 నిమిషాలు వేయించండి" etc.
  // Returns seconds, or null if no time mention found.

  static int? _extractTimerSeconds(String text) {
    final lower = text.toLowerCase();

    // English patterns
    final enPatterns = [
      (RegExp(r'(\d+)\s*(?:hour|hr)s?'), 3600),
      (RegExp(r'(\d+)\s*(?:minute|min)s?'), 60),
      (RegExp(r'(\d+)\s*(?:second|sec)s?'), 1),
    ];
    for (final (regex, mult) in enPatterns) {
      final m = regex.firstMatch(lower);
      if (m != null) {
        final n = int.tryParse(m.group(1)!);
        if (n != null && n > 0) return n * mult;
      }
    }

    // Telugu patterns
    final tePatterns = [
      (RegExp(r'(\d+)\s*గంటలు'), 3600),
      (RegExp(r'(\d+)\s*నిమిషాలు'), 60),
      (RegExp(r'(\d+)\s*సెకన్లు'), 1),
    ];
    for (final (regex, mult) in tePatterns) {
      final m = regex.firstMatch(text);
      if (m != null) {
        final n = int.tryParse(m.group(1)!);
        if (n != null && n > 0) return n * mult;
      }
    }

    return null;
  }
}
