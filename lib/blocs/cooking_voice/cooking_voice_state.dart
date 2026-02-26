import 'package:equatable/equatable.dart';

class CookingVoiceState extends Equatable {
  final List<String> steps;
  final int currentStepIndex;
  final bool isSpeaking;
  final bool isPaused;

  const CookingVoiceState({
    required this.steps,
    required this.currentStepIndex,
    required this.isSpeaking,
    required this.isPaused,
  });

  factory CookingVoiceState.initial() {
    return const CookingVoiceState(
      steps: [],
      currentStepIndex: 0,
      isSpeaking: false,
      isPaused: false,
    );
  }

  CookingVoiceState copyWith({
    List<String>? steps,
    int? currentStepIndex,
    bool? isSpeaking,
    bool? isPaused,
  }) {
    return CookingVoiceState(
      steps: steps ?? this.steps,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isPaused: isPaused ?? this.isPaused,
    );
  }

  String get currentStep => steps.isNotEmpty ? steps[currentStepIndex] : '';

  bool get isLastStep => currentStepIndex >= steps.length - 1;

  bool get isFirstStep => currentStepIndex == 0;

  @override
  List<Object?> get props => [steps, currentStepIndex, isSpeaking, isPaused];
}
