part of 'voice_bloc.dart';

abstract class VoiceEvent extends Equatable {
  const VoiceEvent();

  @override
  List<Object?> get props => [];
}

class InitializeVoice extends VoiceEvent {
  const InitializeVoice();
}

class StartListening extends VoiceEvent {
  final String localeId;

  /// If true, result emits VoiceSearchResult; if false, runs command parser.
  final bool isSearchMode;

  const StartListening({
    this.localeId = 'en_US',
    this.isSearchMode = false,
  });

  @override
  List<Object?> get props => [localeId, isSearchMode];
}

class StopListening extends VoiceEvent {
  const StopListening();
}

class SpeechResultReceived extends VoiceEvent {
  final String text;
  final bool isFinal;
  const SpeechResultReceived(this.text, {this.isFinal = true});

  @override
  List<Object?> get props => [text, isFinal];
}

class SpeakText extends VoiceEvent {
  final String text;
  final String? language; // e.g. 'te-IN', 'en-US'
  final double rate;

  /// When true, VoiceBloc checks the text for time mentions after speaking
  /// and emits VoiceTimerSuggested if found. Set to true from CookingModeScreen.
  final bool suggestTimer;

  const SpeakText(
    this.text, {
    this.language,
    this.rate = 0.5,
    this.suggestTimer = false,
  });

  @override
  List<Object?> get props => [text, language, rate, suggestTimer];
}

class StopSpeaking extends VoiceEvent {
  const StopSpeaking();
}

class ProcessVoiceCommand extends VoiceEvent {
  final String command;
  const ProcessVoiceCommand(this.command);

  @override
  List<Object?> get props => [command];
}
