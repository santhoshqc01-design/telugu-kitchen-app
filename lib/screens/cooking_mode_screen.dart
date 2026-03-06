import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/language/language_bloc.dart';
import '../blocs/voice/voice_bloc.dart';
import '../l10n/app_localizations.dart';
import '../models/recipe_model.dart';
import '../widgets/ingredient_tile.dart';
import '../services/ingredient_download_service.dart';
import '../services/step_timer_analyzer.dart';
import '../services/adaptive_timer_service.dart';
import '../repositories/timer_learning_repository.dart';

class CookingModeScreen extends StatefulWidget {
  final Recipe recipe;
  final TimerLearningRepository learningRepo;
  const CookingModeScreen({
    super.key,
    required this.recipe,
    required this.learningRepo,
  });

  @override
  State<CookingModeScreen> createState() => _CookingModeScreenState();
}

class _CookingModeScreenState extends State<CookingModeScreen>
    with TickerProviderStateMixin {
  // ── Step state ─────────────────────────────────────────────────────────────
  int _currentStep = 0;

  // ── Timer state ────────────────────────────────────────────────────────────
  Timer? _ticker;
  int _secondsRemaining = 0;
  int _totalTimeForStep = 0;
  bool _isTimerRunning = false;
  bool _isPassive = false; // marinate/soak → show skip prompt, no auto-start
  bool _autoStarted = false; // guard: only auto-start once per step
  StepTimerSource _timerSource = StepTimerSource.estimated;

  // ── Animation controllers ──────────────────────────────────────────────────
  late AnimationController _pulseController; // mic pulsing
  late AnimationController _ringController; // circular timer ring (smooth)
  late AnimationController _stepSlideController; // instruction card slide
  late AnimationController _warningController; // last-30s ring flash
  late Animation<Offset> _stepSlideAnim;

  // ── Scroll ─────────────────────────────────────────────────────────────────
  final ScrollController _stepScrollController = ScrollController();
  static const double _stepDotWidth = 48.0;

  // ── Adaptive timer service ────────────────────────────────────────────────
  late final AdaptiveTimerService _timerService;

  int _predictedSeconds = 0;
  int _actualElapsedSeconds = 0;
  Timer? _elapsedTicker;
  bool _userAddedTime = false;

  // ── Wakelock ──────────────────────────────────────────────────────────────
  // import 'package:wakelock_plus/wakelock_plus.dart';

  @override
  void initState() {
    super.initState();

    _timerService = AdaptiveTimerService(
      analyzer: StepTimerAnalyzer(
        totalCookMinutes: widget.recipe.cookTimeMinutes,
        totalSteps: widget.recipe.instructions.length,
      ),
      repo: widget.learningRepo,
      category: widget.recipe.category,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _ringController = AnimationController(
      vsync: this,
      value: 1.0,
      duration: const Duration(hours: 1),
    );
    _stepSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _warningController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _stepSlideAnim =
        Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _stepSlideController,
        curve: Curves.easeOutCubic,
      ),
    );

    // WakelockPlus.enable();
    _loadStep(_currentStep);
    _stepSlideController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakCurrentStep());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _elapsedTicker?.cancel();
    _pulseController.dispose();
    _ringController.dispose();
    _stepSlideController.dispose();
    _warningController.dispose();
    _stepScrollController.dispose();
    // WakelockPlus.disable();
    super.dispose();
  }

  // ── Step loading ───────────────────────────────────────────────────────────

  void _loadStep(int index) {
    _ticker?.cancel();
    _isTimerRunning = false;
    _autoStarted = false;

    final englishStep = index < widget.recipe.instructions.length
        ? widget.recipe.instructions[index]
        : '';

    _timerSource = _timerService.sourceFor(englishStep);
    _isPassive = _timerService.isPassiveStep(englishStep);
    _predictedSeconds = _timerService.predictSeconds(
      englishStep,
      stepIndex: index,
    );
    _totalTimeForStep = _predictedSeconds;
    _actualElapsedSeconds = 0;
    _userAddedTime = false;
    _secondsRemaining = _totalTimeForStep;

    _ringController.duration = Duration(seconds: _totalTimeForStep);
    _ringController.value = 1.0;
    _warningController.reset();
  }

  // ── Timer operations ───────────────────────────────────────────────────────

  void _startTimer() {
    if (_isTimerRunning || _secondsRemaining <= 0) return;

    HapticFeedback.lightImpact();
    setState(() => _isTimerRunning = true);
    _pulseController.repeat(reverse: true); // pulse while timer runs

    _ringController.duration = Duration(seconds: _secondsRemaining);
    _ringController.reverse(from: _secondsRemaining / _totalTimeForStep);

    _elapsedTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _actualElapsedSeconds++;
    });

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
          if (_secondsRemaining == 30) _onWarningThreshold();
        } else {
          _timerComplete();
        }
      });
    });
  }

  void _pauseTimer() {
    _ticker?.cancel();
    _elapsedTicker?.cancel();
    _ringController.stop();
    _pulseController.stop();
    _pulseController.reset();
    HapticFeedback.lightImpact();
    setState(() => _isTimerRunning = false);
  }

  void _resetTimer() {
    _ticker?.cancel();
    _elapsedTicker?.cancel();
    _ringController.stop();
    setState(() {
      _secondsRemaining = _totalTimeForStep;
      _isTimerRunning = false;
      _autoStarted = false;
      _actualElapsedSeconds = 0;
      _warningController.reset();
    });
    _ringController.value = 1.0;
  }

  void _addTime(int minutes) {
    final extra = minutes * 60;
    _secondsRemaining += extra;
    _totalTimeForStep += extra;
    _userAddedTime = true;

    if (_isTimerRunning) {
      _ringController.stop();
      _ringController.duration = Duration(seconds: _secondsRemaining);
      _ringController.reverse(from: _secondsRemaining / _totalTimeForStep);
    } else {
      _ringController.value = _secondsRemaining / _totalTimeForStep;
    }
    _warningController.reset();
    setState(() {});
  }

  void _onWarningThreshold() {
    HapticFeedback.mediumImpact();
    _warningController.repeat(reverse: true);
  }

  void _timerComplete() {
    _ticker?.cancel();
    _elapsedTicker?.cancel();
    _ringController.stop();
    _ringController.value = 0;
    _warningController.stop();
    HapticFeedback.heavyImpact();
    setState(() => _isTimerRunning = false);
    if (!mounted) return;

    _recordLearning(reason: StepEndReason.timerComplete);

    final isTelugu = context.read<LanguageBloc>().state.isTelugu;
    context.read<VoiceBloc>().add(
          SpeakText(
            isTelugu ? 'సమయం ముగిసింది' : 'Time is up',
            language: isTelugu ? 'te-IN' : 'en-US',
          ),
        );
    _showTimerCompleteDialog(isTelugu);
  }

  // ── Auto-start logic ───────────────────────────────────────────────────────

  void _maybeAutoStart() {
    if (_autoStarted) return;
    _autoStarted = true;
    final englishStep = _currentStep < widget.recipe.instructions.length
        ? widget.recipe.instructions[_currentStep]
        : '';
    if (_timerService.shouldAutoStart(englishStep)) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && !_isTimerRunning) _startTimer();
      });
    }
  }

  // ── Time formatting ────────────────────────────────────────────────────────

  String _formatTime(int seconds) {
    if (seconds >= 3600) {
      final h = seconds ~/ 3600;
      final m = (seconds % 3600) ~/ 60;
      final s = seconds % 60;
      return '${_pad(h)}:${_pad(m)}:${_pad(s)}';
    }
    return '${_pad(seconds ~/ 60)}:${_pad(seconds % 60)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  // ── Learning ───────────────────────────────────────────────────────────────

  void _recordLearning({required StepEndReason reason}) {
    if (_predictedSeconds < 30) return;
    final englishStep = _currentStep < widget.recipe.instructions.length
        ? widget.recipe.instructions[_currentStep]
        : '';
    _timerService.recordActual(
      predicted: _predictedSeconds,
      actual: _actualElapsedSeconds.clamp(30, 7200),
      stepText: englishStep,
      reason: reason,
    );
  }

  StepEndReason _reasonForManualNext() {
    if (_userAddedTime) return StepEndReason.userAddedTime;
    final remainingFraction =
        _predictedSeconds > 0 ? _secondsRemaining / _predictedSeconds : 0.0;
    if (remainingFraction > 0.20) return StepEndReason.userSkippedEarly;
    return StepEndReason.timerComplete;
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  List<String> get _instructions {
    final isTelugu = context.read<LanguageBloc>().state.isTelugu;
    return isTelugu ? widget.recipe.instructionsTe : widget.recipe.instructions;
  }

  void _speakCurrentStep() {
    final isTelugu = context.read<LanguageBloc>().state.isTelugu;
    final steps = _instructions;
    if (_currentStep < steps.length) {
      context.read<VoiceBloc>().add(
            SpeakText(steps[_currentStep],
                language: isTelugu ? 'te-IN' : 'en-US'),
          );
    }
  }

  void _goToStep(int index, {bool forward = true}) {
    if (index < 0 || index >= _instructions.length) return;

    if (_actualElapsedSeconds >= 30) {
      _recordLearning(reason: _reasonForManualNext());
    }

    _stepSlideAnim = Tween<Offset>(
      begin: Offset(forward ? 1.0 : -1.0, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _stepSlideController,
        curve: Curves.easeOutCubic,
      ),
    );
    _stepSlideController.forward(from: 0);

    setState(() {
      _currentStep = index;
      _loadStep(index);
    });

    _speakCurrentStep();
    _scrollToCurrentStep();
  }

  void _goToNextStep() {
    if (_currentStep < _instructions.length - 1) {
      _goToStep(_currentStep + 1, forward: true);
    } else {
      _showCompletionDialog();
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) _goToStep(_currentStep - 1, forward: false);
  }

  void _scrollToCurrentStep() {
    if (!_stepScrollController.hasClients || _instructions.length <= 5) return;
    final target = _currentStep * _stepDotWidth -
        _stepScrollController.position.viewportDimension / 2 +
        _stepDotWidth / 2;
    _stepScrollController.animateTo(
      target.clamp(0.0, _stepScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  void _showTimerCompleteDialog(bool isTelugu) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(Icons.timer_off_rounded,
                size: 60, color: Colors.orange.shade800),
            const SizedBox(height: 12),
            Text(
              isTelugu ? '⏰ టైమర్ పూర్తయింది!' : '⏰ Timer Complete!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20),
            ),
          ],
        ),
        content: Text(
          isTelugu
              ? 'ఈ అడుగు సమయం ముగిసింది.\nతదుపరి అడుగుకు వెళ్ళాలా?'
              : 'Time for this step is up.\nMove to the next step?',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isTelugu ? 'ఇక్కడే ఉండండి' : 'Stay Here'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _goToNextStep();
            },
            style:
                FilledButton.styleFrom(backgroundColor: Colors.orange.shade800),
            child: Text(isTelugu ? 'తదుపరి అడుగు →' : 'Next Step →'),
          ),
        ],
      ),
    );
  }

  void _showPassiveStepInfo(bool isTelugu) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.hourglass_top_rounded, color: Colors.blue.shade700),
            const SizedBox(width: 10),
            Text(
              isTelugu ? 'నిష్క్రియ దశ' : 'Passive Step',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
        content: Text(
          isTelugu
              ? 'ఈ దశ నిరీక్షణ సమయం (మ్యారినేట్/నానపెట్టడం). '
                  'టైమర్ మీరు మానవీయంగా ప్రారంభించాలి.\n\n'
                  'సమయం పూర్తైనప్పుడు మీరు తిరిగి వస్తే, '
                  '"తర్వాత" అని చెప్పండి.'
              : 'This step is a waiting period (marinate/soak). '
                  'Start the timer manually when ready.\n\n'
                  'When the time is up, say "next" to continue.',
          style: const TextStyle(height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _startTimer();
            },
            style:
                FilledButton.styleFrom(backgroundColor: Colors.blue.shade700),
            child: Text(isTelugu ? 'టైమర్ ప్రారంభించు' : 'Start Timer'),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog() {
    if (!mounted) return;
    final isTelugu = context.read<LanguageBloc>().state.isTelugu;
    context.read<VoiceBloc>().add(
          SpeakText(
            isTelugu
                ? 'అభినందనలు! వంట పూర్తయింది.'
                : 'Congratulations! Cooking complete.',
            language: isTelugu ? 'te-IN' : 'en-US',
          ),
        );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            const Icon(Icons.celebration_rounded,
                size: 64, color: Colors.orange),
            const SizedBox(height: 12),
            Text(
              isTelugu ? '🎉 అభినందనలు!' : '🎉 Congratulations!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22),
            ),
          ],
        ),
        content: Text(
          isTelugu
              ? 'మీరు ${widget.recipe.titleTe} విజయవంతంగా పూర్తి చేశారు!'
              : '${widget.recipe.title} is ready to serve!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            icon: const Icon(Icons.home_rounded),
            label: Text(isTelugu ? 'హోమ్ కు వెళ్ళండి' : 'Back to Home'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTelugu = context.watch<LanguageBloc>().state.isTelugu;
    final instructions =
        isTelugu ? widget.recipe.instructionsTe : widget.recipe.instructions;
    final isTablet = MediaQuery.of(context).size.width > 600;

    return BlocListener<VoiceBloc, VoiceState>(
      listener: (context, state) {
        if (state is VoiceReady) {
          _maybeAutoStart();
          return;
        }
        if (state is VoiceTimerSuggested) {
          if (!_isTimerRunning && _secondsRemaining == _totalTimeForStep) {
            setState(() {
              _totalTimeForStep = state.seconds;
              _secondsRemaining = state.seconds;
              _ringController.value = 1.0;
            });
          }
          return;
        }
        if (state is! VoiceCommandExecuted) return;
        switch (state.command) {
          case 'next_step':
            _goToNextStep();
          case 'previous_step':
            _goToPreviousStep();
          case 'repeat':
            _speakCurrentStep();
          case 'start_timer':
            _startTimer();
          case 'pause_timer':
            _pauseTimer();
          case 'stop':
            context.read<VoiceBloc>().add(const StopSpeaking());
            _pauseTimer();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: _buildAppBar(isTelugu, instructions.length),
        bottomNavigationBar:
            _buildNavigationBar(l10n, instructions.length, isTelugu, isTablet),
        body: Column(
          children: [
            _buildTopProgressBar(instructions.length),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  isTablet ? 32 : 16,
                  10,
                  isTablet ? 32 : 16,
                  16, // bottom padding
                ),
                child: Column(
                  children: [
                    _buildStepIndicator(
                        instructions.length, isTelugu, isTablet),
                    SizedBox(height: isTablet ? 16 : 10),
                    _buildSmartTimerCard(isTelugu, isTablet),
                    SizedBox(height: isTablet ? 16 : 10),
                    if (instructions.isNotEmpty &&
                        _currentStep < instructions.length)
                      _buildInstructionCard(
                          instructions[_currentStep], isTablet),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── App Bar ────────────────────────────────────────────────────────────────

  AppBar _buildAppBar(bool isTelugu, int totalSteps) => AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTelugu ? widget.recipe.titleTe : widget.recipe.title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            Text(
              isTelugu ? 'తయారీ విధానం' : 'Cooking Mode',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_rounded),
            tooltip: isTelugu ? 'పదార్థాలు' : 'Ingredients',
            onPressed: () => _showIngredientsSheet(isTelugu),
          ),
        ],
      );

  void _showIngredientsSheet(bool isTelugu) {
    final ingredients =
        isTelugu ? widget.recipe.ingredientsTe : widget.recipe.ingredients;
    showModalBottomSheet(
      context: context,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, ctrl) {
          final englishIngredients = widget.recipe.ingredients;
          final GlobalKey boundaryKey = GlobalKey();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        isTelugu ? 'పదార్థాలు' : 'Ingredients',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _SheetDownloadButton(
                      icon: Icons.text_snippet_outlined,
                      label: isTelugu ? 'టెక్స్ట్' : 'Text',
                      onTap: () =>
                          IngredientDownloadService.instance.shareAsText(
                        recipe: widget.recipe,
                        ingredients: ingredients,
                        isTelugu: isTelugu,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _SheetDownloadButton(
                      icon: Icons.image_outlined,
                      label: isTelugu ? 'చిత్రం' : 'Image',
                      onTap: () =>
                          IngredientDownloadService.instance.shareAsImage(
                        boundaryKey: boundaryKey,
                        recipeTitle: isTelugu
                            ? widget.recipe.titleTe
                            : widget.recipe.title,
                        isTelugu: isTelugu,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: RepaintBoundary(
                  key: boundaryKey,
                  child: Container(
                    color: Colors.white,
                    child: ListView.separated(
                      controller: ctrl,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      itemCount: ingredients.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: Colors.grey.shade100),
                      itemBuilder: (_, i) => IngredientTile(
                        rawIngredient: ingredients[i],
                        englishRaw: i < englishIngredients.length
                            ? englishIngredients[i]
                            : null,
                        imageSize: 44,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Progress bar ───────────────────────────────────────────────────────────

  Widget _buildTopProgressBar(int totalSteps) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: (_currentStep + 1) / totalSteps),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        builder: (_, v, __) => LinearProgressIndicator(
          value: v,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation(Colors.orange.shade800),
          minHeight: 5,
        ),
      );

  // ── Step indicator ─────────────────────────────────────────────────────────

  Widget _buildStepIndicator(int totalSteps, bool isTelugu, bool isTablet) {
    final needsScroll = totalSteps > 7;
    final dots = Row(
      mainAxisSize: needsScroll ? MainAxisSize.min : MainAxisSize.max,
      mainAxisAlignment:
          needsScroll ? MainAxisAlignment.start : MainAxisAlignment.center,
      children: List.generate(totalSteps, (i) {
        final isActive = i == _currentStep;
        final isDone = i < _currentStep;
        return Row(
          children: [
            if (i > 0)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isTablet ? 18 : 10, // ↓ was 20/14
                height: 2,
                color: isDone ? Colors.green : Colors.grey.shade300,
              ),
            GestureDetector(
              onTap: () {
                if (i <= _currentStep) _goToStep(i, forward: i > _currentStep);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isTablet ? 36 : 26, // ↓ was 40/32
                height: isTablet ? 36 : 26, // ↓ was 40/32
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? Colors.orange.shade800
                      : isDone
                          ? Colors.green
                          : Colors.grey.shade300,
                  border: isActive
                      ? Border.all(
                          color: Colors.orange.shade200, width: 2) // ↓ was 3
                      : null,
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.3),
                            blurRadius: 6, // ↓ was 8
                            spreadRadius: 1, // ↓ was 2
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: isDone && !isActive
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 12)
                      : Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: (isActive || isDone)
                                ? Colors.white
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                            fontSize: isTablet ? 13 : 10, // ↓ was 14/11
                          ),
                        ),
                ),
              ),
            ),
          ],
        );
      }),
    );

    return Column(
      children: [
        if (needsScroll)
          SingleChildScrollView(
            controller: _stepScrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: dots,
          )
        else
          dots,
        const SizedBox(height: 4), // ↓ was 8
        Text(
          isTelugu
              ? 'అడుగు ${_currentStep + 1} / $totalSteps'
              : 'Step ${_currentStep + 1} of $totalSteps',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: isTablet ? 13 : 11, // ↓ was 14/12
          ),
        ),
      ],
    );
  }

  // ── Smart Timer Card ───────────────────────────────────────────────────────

  Widget _buildSmartTimerCard(bool isTelugu, bool isTablet) {
    final isComplete = _secondsRemaining == 0 && !_isTimerRunning;
    final isWarning = _secondsRemaining <= 30 && _secondsRemaining > 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        width: double.infinity,
        // ↓ tighter padding: was EdgeInsets.all(32/22)
        padding: EdgeInsets.fromLTRB(
          isTablet ? 28 : 16,
          isTablet ? 20 : 14,
          isTablet ? 28 : 16,
          isTablet ? 20 : 14,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: _isTimerRunning
              ? LinearGradient(
                  colors: isWarning
                      ? [Colors.red.shade50, Colors.white]
                      : [Colors.orange.shade50, Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
        ),
        child: Column(
          children: [
            // ── Source badge ─────────────────────────────────────────────────
            _buildSourceBadge(isTelugu),
            const SizedBox(height: 12),

            // ── Horizontal: [ − ] [ timer ] [ + ] ────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildTimeAdjustButton(subtract: true),
                const SizedBox(width: 12),
                _buildTimerButton(isComplete, isWarning, isTablet, isTelugu),
                const SizedBox(width: 12),
                _buildTimeAdjustButton(subtract: false),
              ],
            ),

            // ── Passive step banner ──────────────────────────────────────────
            if (_isPassive) ...[
              const SizedBox(height: 10),
              _buildPassiveBanner(isTelugu),
            ],
          ],
        ),
      ),
    );
  }

  // ── Big tappable timer button ─────────────────────────────────────────────
  // Tap = start/pause, long press = reset

  Widget _buildTimerButton(
    bool isComplete,
    bool isWarning,
    bool isTablet,
    bool isTelugu,
  ) {
    final size = isTablet ? 180.0 : 160.0;
    final strokeW = isTablet ? 10.0 : 9.0;

    // Button fill color based on state
    final fillColor = isComplete
        ? Colors.green.shade600
        : isWarning
            ? Colors.red.shade600
            : _isTimerRunning
                ? Colors.orange.shade800
                : Colors.orange.shade700;

    // Ring progress color
    final ringColor = isComplete
        ? Colors.green.shade300
        : isWarning
            ? Colors.red.shade300
            : Colors.orange.shade300;

    return GestureDetector(
      onTap: () {
        if (isComplete) return;
        if (_isTimerRunning) {
          _pauseTimer();
        } else {
          _startTimer();
        }
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _resetTimer();
      },
      child: AnimatedBuilder(
        animation: _ringController,
        builder: (_, __) {
          return AnimatedBuilder(
            animation: _warningController,
            builder: (_, __) {
              final flashOpacity =
                  isWarning ? 0.6 + _warningController.value * 0.4 : 1.0;

              return SizedBox(
                width: size,
                height: size,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Progress arc behind button
                    CircularProgressIndicator(
                      value: _ringController.value,
                      strokeWidth: strokeW,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(
                        ringColor.withValues(alpha: flashOpacity),
                      ),
                    ),

                    // Filled circle button with padding inside arc
                    Padding(
                      padding: EdgeInsets.all(strokeW + 4),
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (_, child) => Transform.scale(
                          scale: _isTimerRunning
                              ? 1.0 + _pulseController.value * 0.04
                              : 1.0,
                          child: child,
                        ),
                        child: Material(
                          shape: const CircleBorder(),
                          color: fillColor,
                          elevation: _isTimerRunning ? 8 : 4,
                          shadowColor: fillColor.withValues(alpha: 0.5),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Play/pause icon — centered, above time
                                if (!isComplete)
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.25),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _isTimerRunning
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                if (!isComplete) const SizedBox(height: 6),

                                // Time display — slightly lower
                                Text(
                                  _formatTime(_secondsRemaining),
                                  style: TextStyle(
                                    fontSize: isTablet ? 36 : 30,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Hint text
                                if (!isComplete)
                                  Text(
                                    _isTimerRunning
                                        ? (isTelugu ? 'ఆపు' : 'Tap to pause')
                                        : (isTelugu
                                            ? 'నొక్కండి'
                                            : 'Tap to start'),
                                    style: TextStyle(
                                      fontSize: 9,
                                      color:
                                          Colors.white.withValues(alpha: 0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                if (isComplete)
                                  Text(
                                    isTelugu ? '✅ పూర్తయింది' : '✅ Done',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color:
                                          Colors.white.withValues(alpha: 0.9),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSourceBadge(bool isTelugu) {
    final color = _timerSource.color;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // ↓ was 12/5
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_timerSource.icon, size: 12, color: color), // ↓ was 13
          const SizedBox(width: 4), // ↓ was 5
          Text(
            _timerSource.label(isTelugu),
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(bool isComplete, bool isTelugu) {
    final (text, bgColor, fgColor) = _isTimerRunning
        ? (
            isTelugu ? '⏱️ పనిచేస్తోంది' : '⏱️ Running', // ↓ shorter text
            Colors.green.shade100,
            Colors.green.shade800,
          )
        : isComplete
            ? (
                isTelugu ? '✅ పూర్తయింది' : '✅ Done',
                Colors.blue.shade100,
                Colors.blue.shade800,
              )
            : (
                isTelugu ? '⏸️ సిద్ధం' : '⏸️ Ready',
                Colors.grey.shade200,
                Colors.grey.shade700,
              );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 5), // ↓ was 16/8
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12, // ↓ was 13
          fontWeight: FontWeight.w600,
          color: fgColor,
        ),
      ),
    );
  }

  // _buildTimerControls kept for passive step controls only
  Widget _buildTimerControls(bool isTelugu) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: _isTimerRunning ? _pauseTimer : _startTimer,
            icon: Icon(
              _isTimerRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
            ),
            label: Text(
              _isTimerRunning
                  ? (isTelugu ? 'పాజ్' : 'Pause')
                  : (isTelugu ? 'ప్రారంభించు' : 'Start'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isTimerRunning ? Colors.orange : Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      );

  Widget _buildTimeAdjustButton({required bool subtract}) {
    final canAct = subtract ? _secondsRemaining > 60 : true;
    final color = canAct ? Colors.orange.shade800 : Colors.grey.shade300;
    return GestureDetector(
      onTap: canAct
          ? () {
              setState(() {
                if (subtract) {
                  _secondsRemaining =
                      (_secondsRemaining - 60).clamp(0, 99 * 60);
                } else {
                  _secondsRemaining += 60;
                }
                if (_totalTimeForStep > 0) {
                  _ringController.value =
                      (_secondsRemaining / _totalTimeForStep).clamp(0.0, 1.0);
                }
              });
            }
          : null,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: canAct ? Colors.orange.shade50 : Colors.grey.shade100,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.5),
        ),
        child: Icon(
          subtract ? Icons.remove_rounded : Icons.add_rounded,
          color: color,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildPassiveBanner(bool isTelugu) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 8), // ↓ was 14/10
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.hourglass_top_rounded,
                color: Colors.blue.shade700, size: 18), // ↓ was 20
            const SizedBox(width: 8), // ↓ was 10
            Expanded(
              child: Text(
                isTelugu
                    ? 'ఇది నిరీక్షణ దశ — మీకు తయారుగా ఉన్నప్పుడు టైమర్ ప్రారంభించండి'
                    : 'Waiting step — start the timer when you\'re ready',
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(Icons.info_outline_rounded,
                  color: Colors.blue.shade600, size: 16), // ↓ was 18
              onPressed: () => _showPassiveStepInfo(isTelugu),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );

  Widget _buildPassiveControls(bool isTelugu) => const SizedBox.shrink();
  // Passive step uses the same timer button + chips layout as active steps

  // ── Instruction card ───────────────────────────────────────────────────────

  Widget _buildInstructionCard(String instruction, bool isTablet) =>
      SlideTransition(
        position: _stepSlideAnim,
        child: Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(isTablet ? 24 : 16), // ↓ was 32/22
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [Colors.white, Colors.orange.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Text(
              instruction,
              style: TextStyle(
                fontSize: isTablet ? 21 : 17,
                height: 1.6,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade900,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );

  // ── Navigation bar ─────────────────────────────────────────────────────────

  Widget _buildNavigationBar(
    AppLocalizations l10n,
    int totalSteps,
    bool isTelugu,
    bool isTablet,
  ) {
    final isLast = _currentStep == totalSteps - 1;
    return BlocBuilder<VoiceBloc, VoiceState>(
      builder: (context, voiceState) {
        final isListening = voiceState is VoiceListening;
        return SafeArea(
          child: Container(
            padding: EdgeInsets.fromLTRB(
              isTablet ? 24 : 12,
              8,
              isTablet ? 24 : 12,
              8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Previous
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _currentStep > 0 ? _goToPreviousStep : null,
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: Text(
                      isTelugu ? 'వెనక్కి' : l10n.previousStep,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.black87,
                      disabledBackgroundColor: Colors.grey.shade100,
                      disabledForegroundColor: Colors.grey.shade400,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 0),
                      minimumSize: const Size(0, 48),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Mic button — centered between Prev and Next
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, child) => Transform.scale(
                    scale:
                        isListening ? 1.0 + _pulseController.value * 0.12 : 1.0,
                    child: child,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      if (isListening) {
                        context.read<VoiceBloc>().add(const StopListening());
                      } else {
                        context.read<VoiceBloc>().add(
                              StartListening(
                                  localeId: isTelugu ? 'te_IN' : 'en_US'),
                            );
                      }
                    },
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color:
                            isListening ? Colors.red : Colors.orange.shade800,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isListening
                                    ? Colors.red
                                    : Colors.orange.shade800)
                                .withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        isListening
                            ? Icons.mic_rounded
                            : Icons.mic_none_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Next
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isLast ? _showCompletionDialog : _goToNextStep,
                    icon: Icon(isLast
                        ? Icons.check_circle_rounded
                        : Icons.arrow_forward_rounded),
                    label: Text(
                      isLast
                          ? (isTelugu ? 'పూర్తయింది! 🎉' : 'Finish! 🎉')
                          : l10n.nextStep,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          isLast ? Colors.green : Colors.orange.shade800,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 0),
                      minimumSize: const Size(0, 48),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Inline download button for cooking mode sheet ─────────────────────────────

class _SheetDownloadButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SheetDownloadButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.orange.shade800),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
}
