part of 'voice_bloc.dart';

abstract class VoiceState extends Equatable {
  const VoiceState();

  @override
  List<Object?> get props => [];
}

/// Bloc just created — services not yet initialized.
class VoiceInitial extends VoiceState {
  const VoiceInitial();
}

/// Services initialized, idle.
class VoiceReady extends VoiceState {
  const VoiceReady();
}

/// Microphone open, awaiting speech.
class VoiceListening extends VoiceState {
  const VoiceListening();
}

/// TTS is speaking.
class VoiceSpeaking extends VoiceState {
  const VoiceSpeaking();
}

/// Raw text recognized (command mode) — emitted before ProcessVoiceCommand runs.
/// UI can show "I heard: ..." feedback.
class VoiceTextRecognized extends VoiceState {
  final String text;
  const VoiceTextRecognized(this.text);

  @override
  List<Object?> get props => [text];
}

/// Search mode result — forward to RecipeBloc.add(SearchRecipes(text)).
class VoiceSearchResult extends VoiceState {
  final String text;
  const VoiceSearchResult(this.text);

  @override
  List<Object?> get props => [text];
}

/// A recognized cooking command — see VoiceBloc._commands for valid strings.
class VoiceCommandExecuted extends VoiceState {
  final String command;
  const VoiceCommandExecuted(this.command);

  @override
  List<Object?> get props => [command];
}

/// Speech recognized but matched no known command.
class VoiceCommandUnknown extends VoiceState {
  final String spokenText;
  const VoiceCommandUnknown(this.spokenText);

  @override
  List<Object?> get props => [spokenText];
}

/// Emitted after SpeakText (with suggestTimer: true) when the step text
/// contains a time reference ("cook for 5 minutes", "5 నిమిషాలు వేయించండి").
/// CookingModeScreen listens and can auto-start its built-in timer.
/// The screen owns the countdown — this is advisory only.
class VoiceTimerSuggested extends VoiceState {
  final int seconds;
  const VoiceTimerSuggested(this.seconds);

  @override
  List<Object?> get props => [seconds];
}

/// Error state.
class VoiceError extends VoiceState {
  final String message;
  const VoiceError(this.message);

  @override
  List<Object?> get props => [message];
}
