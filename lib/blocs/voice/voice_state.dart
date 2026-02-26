part of 'voice_bloc.dart';

abstract class VoiceState extends Equatable {
  const VoiceState();

  @override
  List<Object?> get props => [];
}

class VoiceInitial extends VoiceState {
  const VoiceInitial();
}

class VoiceReady extends VoiceState {
  const VoiceReady();
}

class VoiceListening extends VoiceState {
  const VoiceListening();
}

class VoiceSpeaking extends VoiceState {
  const VoiceSpeaking();
}

// For cooking mode - commands like next, previous
// NEW - unique name
class VoiceTextRecognized extends VoiceState {
  final String text;
  const VoiceTextRecognized(this.text);

  @override
  List<Object?> get props => [text];
}

// NEW: For search mode - just returns recognized text
class VoiceSearchResult extends VoiceState {
  final String text;
  const VoiceSearchResult(this.text);

  @override
  List<Object?> get props => [text];
}

class VoiceCommandExecuted extends VoiceState {
  final String command;
  const VoiceCommandExecuted(this.command);

  @override
  List<Object?> get props => [command];
}

class VoiceCommandUnknown extends VoiceState {
  final String command;
  const VoiceCommandUnknown(this.command);

  @override
  List<Object?> get props => [command];
}

class VoiceError extends VoiceState {
  final String message;
  const VoiceError(this.message);

  @override
  List<Object?> get props => [message];
}
