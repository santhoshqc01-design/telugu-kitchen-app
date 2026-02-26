import 'dart:async';
import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/language/language_bloc.dart';
import '../blocs/voice/voice_bloc.dart';
import '../l10n/app_localizations.dart';
import '../models/recipe_model.dart';

class CookingModeScreen extends StatefulWidget {
  final Recipe recipe;
  const CookingModeScreen({super.key, required this.recipe});

  @override
  State<CookingModeScreen> createState() => _CookingModeScreenState();
}

class _CookingModeScreenState extends State<CookingModeScreen>
    with TickerProviderStateMixin {
  int currentStep = 0;
  Timer? _timer;
  int _secondsRemaining = 0;
  bool _isTimerRunning = false;
  int _totalTimeForStep = 0;
  late AnimationController _pulseController;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _setTimerForCurrentStep();
    _speakCurrentStep();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _setTimerForCurrentStep() {
    _totalTimeForStep = _getTimeForStep(currentStep);
    _secondsRemaining = _totalTimeForStep;
    _isTimerRunning = false;
    _timer?.cancel();
    _progressController.value = 1.0;
  }

  int _getTimeForStep(int step) {
    final stepTimes = [300, 600, 300, 180, 120, 240, 300];
    if (step < stepTimes.length) return stepTimes[step];
    return 300;
  }

  void _startTimer() {
    if (_isTimerRunning) return;
    setState(() => _isTimerRunning = true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
          _progressController.value = _secondsRemaining / _totalTimeForStep;
        } else {
          _timerComplete();
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isTimerRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = _totalTimeForStep;
      _isTimerRunning = false;
      _progressController.value = 1.0;
    });
  }

  void _addTime(int minutes) {
    setState(() {
      _secondsRemaining += minutes * 60;
      _totalTimeForStep += minutes * 60;
      _progressController.value = _secondsRemaining / _totalTimeForStep;
    });
  }

  void _timerComplete() {
    _timer?.cancel();
    setState(() => _isTimerRunning = false);

    final isTelugu = context.read<LanguageBloc>().state.isTelugu;
    context.read<VoiceBloc>().add(
          SpeakText(
            isTelugu ? 'సమయం ముగిసింది' : 'Time is up',
            language: isTelugu ? 'te-IN' : 'en-US',
          ),
        );

    _showTimerCompleteDialog(isTelugu);
  }

  void _showTimerCompleteDialog(bool isTelugu) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(
              Icons.timer_off,
              size: 64,
              color: Colors.orange.shade800,
            ),
            const SizedBox(height: 16),
            Text(
              isTelugu ? '⏰ టైమర్ పూర్తయింది!' : '⏰ Timer Complete!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22),
            ),
          ],
        ),
        content: Text(
          isTelugu
              ? 'ఈ అడుగు కోసం సమయం ముగిసింది.\nతదుపరి అడుగుకు వెళ్ళాలా?'
              : 'Time for this step is complete.\nGo to next step?',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isTelugu ? 'ఇక్కడే ఉండండి' : 'Stay Here'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _goToNextStep();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(isTelugu ? 'తదుపరి అడుగు →' : 'Next Step →'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _speakCurrentStep() {
    final isTelugu = context.read<LanguageBloc>().state.isTelugu;
    final instructions =
        isTelugu ? widget.recipe.instructionsTe : widget.recipe.instructions;

    if (currentStep < instructions.length) {
      context.read<VoiceBloc>().add(
            SpeakText(
              instructions[currentStep],
              language: isTelugu ? 'te-IN' : 'en-US',
            ),
          );
    }
  }

  void _goToNextStep() {
    final instructions = context.read<LanguageBloc>().state.isTelugu
        ? widget.recipe.instructionsTe
        : widget.recipe.instructions;

    if (currentStep < instructions.length - 1) {
      setState(() {
        currentStep++;
        _setTimerForCurrentStep();
      });
      _speakCurrentStep();
    } else {
      _showCompletionDialog();
    }
  }

  void _goToPreviousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
        _setTimerForCurrentStep();
      });
      _speakCurrentStep();
    }
  }

  void _showCompletionDialog() {
    final isTelugu = context.read<LanguageBloc>().state.isTelugu;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            const Icon(
              Icons.celebration,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              isTelugu ? '🎉 అభినందనలు!' : '🎉 Congratulations!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24),
            ),
          ],
        ),
        content: Text(
          isTelugu
              ? 'మీరు ${widget.recipe.titleTe} వంటకాన్ని విజయవంతంగా పూర్తి చేశారు!'
              : 'You have successfully completed ${widget.recipe.title}!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.home),
            label: Text(isTelugu ? 'హోమ్ కు వెళ్ళండి' : 'Go to Home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTelugu = context.watch<LanguageBloc>().state.isTelugu;
    final instructions =
        isTelugu ? widget.recipe.instructionsTe : widget.recipe.instructions;

    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return BlocListener<VoiceBloc, VoiceState>(
      listener: (context, state) {
        if (state is VoiceCommandExecuted) {
          switch (state.command) {
            case 'next_step':
              _goToNextStep();
              break;
            case 'previous_step':
              _goToPreviousStep();
              break;
            case 'repeat':
              _speakCurrentStep();
              break;
            case 'stop':
              context.read<VoiceBloc>().add(const StopSpeaking());
              _pauseTimer();
              break;
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isTelugu ? widget.recipe.titleTe : widget.recipe.title,
                style: const TextStyle(fontSize: 18),
              ),
              Text(
                isTelugu ? 'తయారీ విధానం' : 'Cooking Mode',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade800,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Column(
          children: [
            // Progress bar with step indicator
            _buildProgressBar(instructions.length),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isTablet ? 32 : 16),
                child: Column(
                  children: [
                    _buildStepIndicator(instructions.length, isTablet),
                    SizedBox(height: isTablet ? 32 : 24),
                    _buildTimerCard(isTelugu, isTablet),
                    SizedBox(height: isTablet ? 32 : 24),
                    _buildInstructionCard(
                        instructions[currentStep], isTelugu, isTablet),
                    SizedBox(height: isTablet ? 32 : 24),
                    _buildVoiceControl(l10n, isTelugu, isTablet),
                  ],
                ),
              ),
            ),
            _buildNavigationControls(
                l10n, instructions.length, isTelugu, isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(int totalSteps) {
    return LinearProgressIndicator(
      value: (currentStep + 1) / totalSteps,
      backgroundColor: Colors.grey.shade200,
      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade800),
      minHeight: 6,
    );
  }

  Widget _buildStepIndicator(int totalSteps, bool isTablet) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalSteps, (index) {
            final isActive = index == currentStep;
            final isCompleted = index < currentStep;

            return Row(
              children: [
                if (index > 0)
                  Container(
                    width: isTablet ? 24 : 16,
                    height: 2,
                    color: isCompleted ? Colors.green : Colors.grey.shade300,
                  ),
                GestureDetector(
                  onTap: () {
                    if (index <= currentStep) {
                      setState(() {
                        currentStep = index;
                        _setTimerForCurrentStep();
                      });
                      _speakCurrentStep();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isTablet ? 40 : 32,
                    height: isTablet ? 40 : 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? Colors.orange.shade800
                          : isCompleted
                              ? Colors.green
                              : Colors.grey.shade300,
                      border: isActive
                          ? Border.all(color: Colors.orange.shade200, width: 3)
                          : null,
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: isCompleted && !isActive
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 16)
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isActive || isCompleted
                                    ? Colors.white
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                                fontSize: isTablet ? 14 : 12,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          'Step ${currentStep + 1} of $totalSteps',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: isTablet ? 14 : 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTimerCard(bool isTelugu, bool isTablet) {
    final isWarning = _secondsRemaining < 60 && _secondsRemaining > 0;
    final isComplete = _secondsRemaining == 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isTablet ? 40 : 28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: _isTimerRunning
              ? LinearGradient(
                  colors: [Colors.orange.shade50, Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
        ),
        child: Column(
          children: [
            // Circular progress indicator
            SizedBox(
              height: isTablet ? 180 : 140,
              width: isTablet ? 180 : 140,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: _progressController.value,
                    strokeWidth: isTablet ? 12 : 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isComplete
                          ? Colors.green
                          : isWarning
                              ? Colors.red
                              : Colors.orange.shade800,
                    ),
                  ),
                  Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: TextStyle(
                        fontSize: isTablet ? 48 : 38,
                        fontWeight: FontWeight.bold,
                        color: isComplete
                            ? Colors.green
                            : isWarning
                                ? Colors.red
                                : Colors.orange.shade800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      child: Text(_formatTime(_secondsRemaining)),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isTablet ? 20 : 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _isTimerRunning
                    ? Colors.green.shade100
                    : isComplete
                        ? Colors.blue.shade100
                        : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _isTimerRunning
                    ? (isTelugu ? '⏱️ టైమర్ పనిచేస్తోంది' : '⏱️ Timer Running')
                    : isComplete
                        ? (isTelugu ? '✅ పూర్తయింది' : '✅ Complete')
                        : (isTelugu ? '⏸️ ఆగిపోయింది' : '⏸️ Paused'),
                style: TextStyle(
                  color: _isTimerRunning
                      ? Colors.green.shade800
                      : isComplete
                          ? Colors.blue.shade800
                          : Colors.grey.shade700,
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: isTablet ? 24 : 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTimerButton(
                  icon: _isTimerRunning ? Icons.pause : Icons.play_arrow,
                  label: _isTimerRunning
                      ? (isTelugu ? 'పాజ్' : 'Pause')
                      : (isTelugu ? 'ప్రారంభించు' : 'Start'),
                  color: _isTimerRunning ? Colors.orange : Colors.green,
                  onPressed: _isTimerRunning ? _pauseTimer : _startTimer,
                  isTablet: isTablet,
                ),
                SizedBox(width: isTablet ? 16 : 12),
                _buildTimerButton(
                  icon: Icons.refresh,
                  label: isTelugu ? 'రీసెట్' : 'Reset',
                  color: Colors.grey.shade600,
                  onPressed: _resetTimer,
                  isTablet: isTablet,
                ),
              ],
            ),
            SizedBox(height: isTablet ? 16 : 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildAddTimeButton(1, isTelugu, isTablet),
                _buildAddTimeButton(5, isTelugu, isTablet),
                _buildAddTimeButton(10, isTelugu, isTablet),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    required bool isTablet,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: isTablet ? 24 : 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 24 : 20,
          vertical: isTablet ? 16 : 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildAddTimeButton(int minutes, bool isTelugu, bool isTablet) {
    return ActionChip(
      onPressed: () => _addTime(minutes),
      backgroundColor: Colors.orange.shade50,
      side: BorderSide(color: Colors.orange.shade200),
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 12 : 8,
        vertical: isTablet ? 8 : 4,
      ),
      label: Text(
        '+$minutes ${isTelugu ? 'నిమి' : 'min'}',
        style: TextStyle(
          color: Colors.orange.shade800,
          fontSize: isTablet ? 14 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      avatar: Icon(
        Icons.add,
        size: isTablet ? 18 : 16,
        color: Colors.orange.shade800,
      ),
    );
  }

  Widget _buildInstructionCard(
      String instruction, bool isTelugu, bool isTablet) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isTablet ? 32 : 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.orange.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.format_quote,
                  size: isTablet ? 28 : 24,
                  color: Colors.orange.shade300,
                ),
              ],
            ),
            SizedBox(height: isTablet ? 20 : 16),
            Text(
              instruction,
              style: TextStyle(
                fontSize: isTablet ? 26 : 22,
                height: 1.7,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade900,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isTablet ? 20 : 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.format_quote,
                  size: isTablet ? 28 : 24,
                  color: Colors.orange.shade300,
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceControl(
      AppLocalizations l10n, bool isTelugu, bool isTablet) {
    return BlocConsumer<VoiceBloc, VoiceState>(
      listener: (context, state) {
        if (state is VoiceListening) {
          _pulseController.repeat();
        } else {
          _pulseController.stop();
        }
      },
      builder: (context, state) {
        final isListening = state is VoiceListening;

        return Column(
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale:
                      isListening ? 1.0 + (_pulseController.value * 0.15) : 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: isListening
                          ? [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 10,
                              ),
                            ]
                          : null,
                    ),
                    child: FloatingActionButton.large(
                      onPressed: () {
                        if (isListening) {
                          context.read<VoiceBloc>().add(const StopListening());
                        } else {
                          context.read<VoiceBloc>().add(
                                StartListening(
                                  localeId: isTelugu ? 'te_IN' : 'en_US',
                                ),
                              );
                        }
                      },
                      backgroundColor: isListening ? Colors.red : Colors.orange,
                      child: Icon(
                        isListening ? Icons.mic : Icons.mic_none,
                        size: isTablet ? 40 : 32,
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: isTablet ? 16 : 12),
            Text(
              isListening ? l10n.listening : l10n.voiceCommands,
              style: TextStyle(
                color: isListening ? Colors.red : Colors.grey.shade600,
                fontSize: isTablet ? 18 : 16,
                fontWeight: isListening ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (!isListening)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '"${l10n.nextStep}", "${l10n.previousStep}", "${l10n.repeat}"',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: isTablet ? 13 : 11,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildNavigationControls(
      AppLocalizations l10n, int totalSteps, bool isTelugu, bool isTablet) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(isTablet ? 24 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: currentStep > 0 ? _goToPreviousStep : null,
                icon: const Icon(Icons.arrow_back),
                label: Text(l10n.previousStep),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black87,
                  padding: EdgeInsets.symmetric(vertical: isTablet ? 18 : 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(width: isTablet ? 20 : 16),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: currentStep < totalSteps - 1
                    ? _goToNextStep
                    : () => _showCompletionDialog(),
                icon: Icon(
                  currentStep < totalSteps - 1
                      ? Icons.arrow_forward
                      : Icons.check_circle,
                ),
                label: Text(
                  currentStep < totalSteps - 1
                      ? l10n.nextStep
                      : (isTelugu ? 'పూర్తయింది!' : 'Finish!'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade800,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: isTablet ? 18 : 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
