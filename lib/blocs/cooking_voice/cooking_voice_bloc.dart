import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cooking_voice_event.dart';
import 'cooking_voice_state.dart';
import '../../services/tts_service.dart';
import '../../services/speech_service.dart';

class CookingVoiceBloc extends Bloc<CookingVoiceEvent, CookingVoiceState> {
  final TTSService ttsService;
  final SpeechService speechService;

  Timer? _activeTimer;

  CookingVoiceBloc(this.ttsService, this.speechService)
      : super(CookingVoiceState.initial()) {
    on<InitializeCookingVoice>(_onInitialize);
    on<NextStepRequested>(_onNextStep);
    on<PreviousStepRequested>(_onPreviousStep);
    on<PauseCookingRequested>(_onPause);
    on<ResumeCookingRequested>(_onResume);
    on<VoiceCommandReceived>(_onVoiceCommand);
    on<StartTimerRequested>(_onStartTimer); // ✅ Correct placement
  }

  // ================= INITIALIZE =================

  Future<void> _onInitialize(
    InitializeCookingVoice event,
    Emitter<CookingVoiceState> emit,
  ) async {
    emit(state.copyWith(
      steps: event.steps,
      currentStepIndex: 0,
      isSpeaking: true,
      isPaused: false,
    ));

    await _speakCurrentStep();

    speechService.startListening(
      onResult: (text) {
        add(VoiceCommandReceived(text));
      },
    );
  }

  // ================= STEP NAVIGATION =================

  Future<void> _onNextStep(
    NextStepRequested event,
    Emitter<CookingVoiceState> emit,
  ) async {
    if (!state.isLastStep) {
      _activeTimer?.cancel();

      emit(state.copyWith(
        currentStepIndex: state.currentStepIndex + 1,
        isSpeaking: true,
        isPaused: false,
      ));

      await _speakCurrentStep();
    }
  }

  Future<void> _onPreviousStep(
    PreviousStepRequested event,
    Emitter<CookingVoiceState> emit,
  ) async {
    if (!state.isFirstStep) {
      _activeTimer?.cancel();

      emit(state.copyWith(
        currentStepIndex: state.currentStepIndex - 1,
        isSpeaking: true,
        isPaused: false,
      ));

      await _speakCurrentStep();
    }
  }

  // ================= PAUSE / RESUME =================

  Future<void> _onPause(
    PauseCookingRequested event,
    Emitter<CookingVoiceState> emit,
  ) async {
    _activeTimer?.cancel();
    await ttsService.stop();

    emit(state.copyWith(
      isPaused: true,
      isSpeaking: false,
    ));
  }

  Future<void> _onResume(
    ResumeCookingRequested event,
    Emitter<CookingVoiceState> emit,
  ) async {
    await ttsService.speak(state.currentStep);

    emit(state.copyWith(
      isPaused: false,
      isSpeaking: true,
    ));
  }

  // ================= VOICE COMMANDS =================

  Future<void> _onVoiceCommand(
    VoiceCommandReceived event,
    Emitter<CookingVoiceState> emit,
  ) async {
    final command = event.command.toLowerCase();

    if (_isNext(command)) {
      add(NextStepRequested());
    } else if (_isPrevious(command)) {
      add(PreviousStepRequested());
    } else if (_isPause(command)) {
      add(PauseCookingRequested());
    } else if (_isResume(command)) {
      add(ResumeCookingRequested());
    }
  }

  bool _isNext(String command) =>
      command.contains("next") ||
      command.contains("తర్వాత") ||
      command.contains("తరువాతి");

  bool _isPrevious(String command) =>
      command.contains("back") ||
      command.contains("previous") ||
      command.contains("ముందు") ||
      command.contains("మునుపటి");

  bool _isPause(String command) =>
      command.contains("pause") || command.contains("ఆపు");

  bool _isResume(String command) =>
      command.contains("resume") ||
      command.contains("మళ్ళీ") ||
      command.contains("కొనసాగించు");

  // ================= SPEAK STEP =================

  Future<void> _speakCurrentStep() async {
    final step = state.currentStep;

    await ttsService.speak(step);

    final seconds = _extractTimerFromText(step);
    if (seconds != null) {
      add(StartTimerRequested(seconds));
    }
  }

  // ================= TIMER =================

  Future<void> _onStartTimer(
    StartTimerRequested event,
    Emitter<CookingVoiceState> emit,
  ) async {
    _activeTimer?.cancel();

    await ttsService.speak(
      "Timer started for ${event.seconds ~/ 60} minutes",
    );

    _activeTimer = Timer(Duration(seconds: event.seconds), () async {
      await ttsService.speak("Timer completed");
    });
  }

  int? _extractTimerFromText(String text) {
    final minuteRegex = RegExp(r'(\d+)\s*(minutes|min)');
    final teluguRegex = RegExp(r'(\d+)\s*నిమిషాలు');

    final match = minuteRegex.firstMatch(text.toLowerCase()) ??
        teluguRegex.firstMatch(text);

    if (match != null) {
      final minutes = int.tryParse(match.group(1)!);
      if (minutes != null) {
        return minutes * 60;
      }
    }

    return null;
  }

  // ================= CLEANUP =================

  @override
  Future<void> close() {
    _activeTimer?.cancel();
    speechService.stopListening();
    ttsService.stop();
    return super.close();
  }
}
