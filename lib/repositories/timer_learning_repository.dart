import 'package:shared_preferences/shared_preferences.dart';

/// Persists EMA correction factors and session metadata.
///
/// Storage layout (SharedPreferences keys):
///   "ema:global"           → double   global correction factor (starts 1.0)
///   "ema:Lunch"            → double   per-category factor
///   "ema:Lunch:keyword"    → double   per-category + per-source factor
///   "ema_sessions"         → int      total steps recorded (all categories)
///   "ema_sessions:Lunch"   → int      steps recorded for this category
///
/// Three improvements over naive EMA:
///   1. Adaptive alpha    — cautious early (0.1), confident later (0.3)
///   2. Factor floor/ceil — U_f clamped to [0.4, 2.5] after every update
///   3. Skip detection    — callers pass StepEndReason; skips are ignored
class TimerLearningRepository {
  static const _prefix = 'ema:';
  static const _sessionKey = 'ema_sessions';

  // ── Adaptive alpha thresholds ──────────────────────────────────────────────
  // Sessions recorded globally (not per-category) drive alpha progression.
  // This avoids needing many sessions per category before alpha increases.
  static const _alphaEarly = 0.10; // sessions 0–3   : cautious
  static const _alphaMid = 0.20; // sessions 4–9   : standard
  static const _alphaLate = 0.30; // sessions 10+   : confident

  // ── Factor bounds ──────────────────────────────────────────────────────────
  // Prevents accumulated drift from making predictions absurd.
  // 0.4 = "your kitchen is 2.5× faster" — physically implausible for most cases
  // 2.5 = "your kitchen is 2.5× slower" — same
  static const _factorMin = 0.4;
  static const _factorMax = 2.5;

  // ── Ratio bounds ───────────────────────────────────────────────────────────
  // Per-observation clamp — a single outlier can't move the needle too far.
  static const _ratioMin = 0.3;
  static const _ratioMax = 3.0;

  final SharedPreferences _prefs;
  TimerLearningRepository(this._prefs);

  static Future<TimerLearningRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return TimerLearningRepository(prefs);
  }

  // ── Read ───────────────────────────────────────────────────────────────────

  /// Correction factor for [category] + [source].
  /// Falls back: specific → category → global → 1.0.
  double getFactor({required String category, required String source}) {
    return _prefs.getDouble('$_prefix$category:$source') ??
        _prefs.getDouble('$_prefix$category') ??
        _prefs.getDouble('${_prefix}global') ??
        1.0;
  }

  int get totalSessions => _prefs.getInt(_sessionKey) ?? 0;
  int sessionsFor(String cat) => _prefs.getInt('$_sessionKey:$cat') ?? 0;

  Map<String, double> get allFactors {
    final result = <String, double>{};
    for (final key in _prefs.getKeys()) {
      if (!key.startsWith(_prefix)) continue;
      final v = _prefs.getDouble(key);
      if (v != null) result[key.substring(_prefix.length)] = v;
    }
    return result;
  }

  // ── Write ──────────────────────────────────────────────────────────────────

  /// Records one step's outcome and updates EMA factors.
  ///
  /// FIX 3 — Skip detection:
  ///   Only [StepEndReason.timerComplete] and [StepEndReason.userAddedTime]
  ///   are trusted as real signal. [StepEndReason.userSkippedEarly] is
  ///   ignored — we can't tell if the food was ready or the user was impatient.
  Future<void> record({
    required int predictedSeconds,
    required int actualSeconds,
    required String category,
    required String source,
    required StepEndReason reason,
  }) async {
    // FIX 3 — ignore ambiguous skips
    if (reason == StepEndReason.userSkippedEarly) return;

    // Ignore trivially short steps (noise / accidental taps)
    if (actualSeconds < 30 || predictedSeconds < 30) return;

    // FIX 1 — adaptive alpha based on total recorded sessions
    final alpha = _adaptiveAlpha(totalSessions);

    // Correction ratio — clamped per-observation (FIX 2 clamps the factor itself)
    final ratio =
        (actualSeconds / predictedSeconds).clamp(_ratioMin, _ratioMax);

    // Update all three levels simultaneously
    await _updateFactor('global', ratio, alpha);
    await _updateFactor(category, ratio, alpha);
    await _updateFactor('$category:$source', ratio, alpha);

    // Increment counters
    await _prefs.setInt(_sessionKey, totalSessions + 1);
    await _prefs.setInt('$_sessionKey:$category', sessionsFor(category) + 1);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// FIX 1 — alpha grows with experience.
  double _adaptiveAlpha(int sessions) {
    if (sessions < 4) return _alphaEarly;
    if (sessions < 10) return _alphaMid;
    return _alphaLate;
  }

  Future<void> _updateFactor(String key, double ratio, double alpha) async {
    final old = _prefs.getDouble('$_prefix$key') ?? 1.0;
    // EMA update
    final raw = alpha * ratio + (1 - alpha) * old;
    // FIX 2 — clamp accumulated factor, not just the ratio
    final clamped = raw.clamp(_factorMin, _factorMax);
    await _prefs.setDouble('$_prefix$key', clamped);
  }

  // ── Reset ──────────────────────────────────────────────────────────────────

  Future<void> resetAll() async {
    final keys = _prefs
        .getKeys()
        .where((k) => k.startsWith(_prefix) || k.startsWith(_sessionKey))
        .toList();
    for (final k in keys) {
      await _prefs.remove(k);
    }
  }

  Future<void> resetCategory(String category) async {
    final keys = _prefs
        .getKeys()
        .where((k) =>
            k == '$_prefix$category' ||
            k.startsWith('$_prefix$category:') ||
            k == '$_sessionKey:$category')
        .toList();
    for (final k in keys) {
      await _prefs.remove(k);
    }
  }
}

// ─── Step End Reason ──────────────────────────────────────────────────────────
//
// FIX 3 — distinguishes WHY a step ended so the model can decide whether
// to trust the actual time as real signal.

enum StepEndReason {
  /// Timer counted to zero naturally — strong signal, always record.
  timerComplete,

  /// User tapped "+time" at least once before step ended — they needed more
  /// time, so actual > predicted. Strong signal, always record.
  userAddedTime,

  /// User tapped Next with >20% time still remaining — ambiguous.
  /// Could mean the food was genuinely ready early, OR the user got
  /// impatient and moved on regardless. Do NOT update the model.
  userSkippedEarly,
}
