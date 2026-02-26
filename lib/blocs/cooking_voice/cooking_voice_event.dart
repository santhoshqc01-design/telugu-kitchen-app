import 'package:equatable/equatable.dart';

abstract class CookingVoiceEvent extends Equatable {
  const CookingVoiceEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize cooking session
class InitializeCookingVoice extends CookingVoiceEvent {
  final List<String> steps;

  const InitializeCookingVoice(this.steps);

  @override
  List<Object?> get props => [steps];
}

/// Move to next step
class NextStepRequested extends CookingVoiceEvent {}

/// Move to previous step
class PreviousStepRequested extends CookingVoiceEvent {}

/// Pause speaking
class PauseCookingRequested extends CookingVoiceEvent {}

/// Resume speaking
class ResumeCookingRequested extends CookingVoiceEvent {}

/// Voice command received from speech recognition
class VoiceCommandReceived extends CookingVoiceEvent {
  final String command;

  const VoiceCommandReceived(this.command);

  @override
  List<Object?> get props => [command];
}

class StartTimerRequested extends CookingVoiceEvent {
  final int seconds;

  const StartTimerRequested(this.seconds);

  @override
  List<Object?> get props => [seconds];
}
