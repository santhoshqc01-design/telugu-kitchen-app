import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/tts_service.dart';
import '../../services/speech_service.dart';

part 'voice_event.dart';
part 'voice_state.dart';

class VoiceBloc extends Bloc<VoiceEvent, VoiceState> {
  final TTSService _ttsService;
  final SpeechService _speechService;
  bool _isSearchMode = false; // Track mode

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

  Future<void> _onInitializeVoice(
    InitializeVoice event,
    Emitter<VoiceState> emit,
  ) async {
    await _ttsService.initialize();
    await _speechService.initialize();
    emit(const VoiceReady());
  }

  Future<void> _onStartListening(
    StartListening event,
    Emitter<VoiceState> emit,
  ) async {
    _isSearchMode = event.isSearchMode; // Store mode
    emit(const VoiceListening());
    await _speechService.startListening(
      onResult: (text) => add(SpeechResultReceived(text)),
      localeId: event.localeId,
    );
  }

  Future<void> _onStopListening(
    StopListening event,
    Emitter<VoiceState> emit,
  ) async {
    await _speechService.stopListening();
    emit(const VoiceReady());
  }

  void _onSpeechResultReceived(
    SpeechResultReceived event,
    Emitter<VoiceState> emit,
  ) {
    if (_isSearchMode) {
      emit(VoiceSearchResult(event.text));
    } else {
      emit(VoiceTextRecognized(event.text)); // Use new state name
      add(ProcessVoiceCommand(event.text));
    }
  }

  Future<void> _onSpeakText(
    SpeakText event,
    Emitter<VoiceState> emit,
  ) async {
    emit(const VoiceSpeaking());
    await _ttsService.speak(
      event.text,
      language: event.language,
      rate: event.rate,
    );
    emit(const VoiceReady());
  }

  Future<void> _onStopSpeaking(
    StopSpeaking event,
    Emitter<VoiceState> emit,
  ) async {
    await _ttsService.stop();
    emit(const VoiceReady());
  }

  void _onProcessVoiceCommand(
    ProcessVoiceCommand event,
    Emitter<VoiceState> emit,
  ) {
    final command = event.command.toLowerCase();

    if (command.contains('next') ||
        command.contains('తర్వాత') ||
        command.contains('ముందు')) {
      emit(const VoiceCommandExecuted('next_step'));
    } else if (command.contains('previous') ||
        command.contains('వెనక') ||
        command.contains('మునుపటి')) {
      emit(const VoiceCommandExecuted('previous_step'));
    } else if (command.contains('repeat') ||
        command.contains('మళ్ళీ') ||
        command.contains('తిరిగి')) {
      emit(const VoiceCommandExecuted('repeat'));
    } else if (command.contains('stop') ||
        command.contains('ఆపు') ||
        command.contains('ఆగు')) {
      emit(const VoiceCommandExecuted('stop'));
    } else if (command.contains('ingredients') ||
        command.contains('పదార్థాలు')) {
      emit(const VoiceCommandExecuted('show_ingredients'));
    } else {
      emit(VoiceCommandUnknown(event.command));
    }
  }
}
