part of 'voice_bloc.dart';

abstract class VoiceEvent extends Equatable {
  const VoiceEvent();

  @override
  List<Object> get props => [];
}

class InitializeVoice extends VoiceEvent {
  const InitializeVoice();
}

class StartListening extends VoiceEvent {
  final String localeId;
  final bool isSearchMode; // ADDED

  const StartListening({
    this.localeId = 'te_IN',
    this.isSearchMode = false, // ADDED
  });

  @override
  List<Object> get props => [localeId, isSearchMode]; // ADDED
}

class StopListening extends VoiceEvent {
  const StopListening();
}

class SpeechResultReceived extends VoiceEvent {
  final String text;

  const SpeechResultReceived(this.text);

  @override
  List<Object> get props => [text];
}

class SpeakText extends VoiceEvent {
  final String text;
  final String language;
  final double rate;

  const SpeakText(
    this.text, {
    this.language = 'te-IN',
    this.rate = 0.5,
  });

  @override
  List<Object> get props => [text, language, rate];
}

class StopSpeaking extends VoiceEvent {
  const StopSpeaking();
}

class ProcessVoiceCommand extends VoiceEvent {
  final String command;

  const ProcessVoiceCommand(this.command);

  @override
  List<Object> get props => [command];
}
