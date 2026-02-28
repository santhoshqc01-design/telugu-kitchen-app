import '../repositories/timer_learning_repository.dart';
import 'step_timer_analyzer.dart';

/// Wraps StepTimerAnalyzer with EMA-based personalization.
///
/// Formula:  T_final = T_base × U_f
///   T_base  — from StepTimerAnalyzer (explicit/range/keyword/fallback)
///   U_f     — learned correction factor from TimerLearningRepository
///
/// Three fixes applied vs naive EMA:
///   1. Adaptive alpha    — alpha grows 0.1 → 0.2 → 0.3 with experience
///   2. Factor floor/ceil — U_f clamped to [0.4, 2.5] preventing drift
///   3. Skip detection    — ambiguous early-skips don't update the model
class AdaptiveTimerService {
  final StepTimerAnalyzer _analyzer;
  final TimerLearningRepository _repo;
  final String _category;

  AdaptiveTimerService({
    required StepTimerAnalyzer analyzer,
    required TimerLearningRepository repo,
    required String category,
  })  : _analyzer = analyzer,
        _repo = repo,
        _category = category;

  // ── Prediction ─────────────────────────────────────────────────────────────

  /// Personalized time in seconds: T_final = T_base × U_f
  int predictSeconds(String stepText, {required int stepIndex}) {
    final base = _analyzer.analyze(stepText, stepIndex: stepIndex);
    final source = _analyzer.sourceFor(stepText);
    final factor = _repo.getFactor(
      category: _category,
      source: source.name,
    );
    final adjusted = (base * factor).round();
    return _roundTo5(adjusted).clamp(30, 7200);
  }

  StepTimerSource sourceFor(String stepText) => _analyzer.sourceFor(stepText);
  bool isPassiveStep(String stepText) => _analyzer.isPassiveStep(stepText);
  bool shouldAutoStart(String stepText) => _analyzer.shouldAutoStart(stepText);

  // ── Learning ───────────────────────────────────────────────────────────────

  /// Records actual vs predicted and updates EMA.
  ///
  /// [reason] determines whether this data point is trusted:
  ///   timerComplete  → always recorded
  ///   userAddedTime  → always recorded (user explicitly needed more time)
  ///   userSkippedEarly → silently ignored (ambiguous signal)
  Future<void> recordActual({
    required int predicted,
    required int actual,
    required String stepText,
    required StepEndReason reason,
  }) async {
    final source = _analyzer.sourceFor(stepText);
    await _repo.record(
      predictedSeconds: predicted,
      actualSeconds: actual,
      category: _category,
      source: source.name,
      reason: reason, // FIX 3 — passed through to repository
    );
  }

  // ── Stats ──────────────────────────────────────────────────────────────────

  LearningStats get stats => LearningStats(
        totalSessions: _repo.totalSessions,
        categorySessions: _repo.sessionsFor(_category),
        globalFactor: _repo.getFactor(category: 'global', source: 'explicit'),
        allFactors: _repo.allFactors,
      );

  // ── Helpers ────────────────────────────────────────────────────────────────

  // Round to nearest 5 seconds for a cleaner countdown display
  int _roundTo5(int seconds) => ((seconds / 5).round() * 5);
}

// ─── Stats model ──────────────────────────────────────────────────────────────

class LearningStats {
  final int totalSessions;
  final int categorySessions;
  final double globalFactor;
  final Map<String, double> allFactors;

  const LearningStats({
    required this.totalSessions,
    required this.categorySessions,
    required this.globalFactor,
    required this.allFactors,
  });

  // FIX 1 — expose which alpha stage the model is currently in
  String get alphaStage {
    if (totalSessions < 4) return 'cautious';
    if (totalSessions < 10) return 'standard';
    return 'confident';
  }

  String progressLabel(bool isTelugu) {
    if (totalSessions == 0) {
      return isTelugu
          ? '🌱 ఇంకా నేర్చుకోవడం ప్రారంభించలేదు'
          : '🌱 Not started learning yet';
    }
    if (totalSessions < 4) {
      return isTelugu
          ? '🔄 $totalSessions దశల నుండి నేర్చుకుంటోంది (జాగ్రత్తగా)'
          : '🔄 $totalSessions step${totalSessions > 1 ? "s" : ""} recorded — being cautious';
    }
    if (totalSessions < 10) {
      return isTelugu
          ? '📈 $totalSessions దశలు — మీ వంటగదికి అనుగుణంగా'
          : '📈 $totalSessions steps — adapting to your kitchen';
    }
    return isTelugu
        ? '🎯 $totalSessions దశలు — మీ వంటగదిని నేర్చుకుంది!'
        : '🎯 $totalSessions steps — learned your kitchen!';
  }

  String factorDescription(bool isTelugu) {
    final pct = ((globalFactor - 1.0) * 100).abs().round();
    if (pct < 3) {
      return isTelugu
          ? 'మీ వంటగది సగటు వేగం'
          : 'Your kitchen matches the average';
    }
    if (globalFactor > 1.0) {
      return isTelugu
          ? 'మీ వంటగది $pct% నెమ్మదిగా — సర్దుబాటు చేయబడింది'
          : 'Your kitchen runs $pct% slower — timers adjusted up';
    }
    return isTelugu
        ? 'మీ వంటగది $pct% వేగంగా — సర్దుబాటు చేయబడింది'
        : 'Your kitchen runs $pct% faster — timers adjusted down';
  }
}
