import 'package:flutter/material.dart';

/// Smart step-timer analyzer for Ruchi cooking mode.
///
/// Priority order for determining a step's time:
///   1. Range in step text          ("simmer 10-15 min" → midpoint 12 min)
///   2. Explicit time mention       ("cook for 10 minutes")
///   3. Action-keyword inference    ("sauté onions" → 3 min, "garnish" → 1 min)
///   4. Proportional fallback       (step's share of total recipe time)
///
/// All durations are in seconds. Call [analyze] for duration,
/// [sourceFor] for confidence level, [isPassiveStep] to skip auto-start.
class StepTimerAnalyzer {
  final int totalCookMinutes;
  final int totalSteps;

  const StepTimerAnalyzer({
    required this.totalCookMinutes,
    required this.totalSteps,
  });

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Best estimated duration in seconds for [stepText].
  int analyze(String stepText, {required int stepIndex}) {
    final range = _parseRange(stepText);
    if (range != null) return range;

    final explicit = _parseExplicit(stepText);
    if (explicit != null) return explicit;

    final keyword = _inferFromKeywords(stepText);
    if (keyword != null) return keyword;

    return _proportionalFallback();
  }

  /// How the time was determined — used for the source badge in the UI.
  StepTimerSource sourceFor(String stepText) {
    if (_parseRange(stepText) != null) return StepTimerSource.range;
    if (_parseExplicit(stepText) != null) return StepTimerSource.explicit;
    if (_inferFromKeywords(stepText) != null) return StepTimerSource.keyword;
    return StepTimerSource.estimated;
  }

  /// True when the step is a passive wait the user doesn't need to stand over.
  /// (marinate, soak, refrigerate, rest) — UI shows a "skip?" prompt instead
  /// of auto-starting the timer.
  bool isPassiveStep(String stepText) {
    final lower = stepText.toLowerCase();
    return _matchesAny(lower, _passiveKeywords);
  }

  /// True when the step has a concrete timed action the timer should auto-start
  /// for — e.g. "fry for 3 minutes", "simmer 15 minutes".
  bool shouldAutoStart(String stepText) {
    // Only auto-start when we have real confidence (explicit or range)
    final src = sourceFor(stepText);
    if (src != StepTimerSource.explicit && src != StepTimerSource.range) {
      return false;
    }
    // Never auto-start a passive step
    return !isPassiveStep(stepText);
  }

  // ── Range parsing ──────────────────────────────────────────────────────────
  // Checked first — "simmer 10-15 min" should use midpoint 12, not literal 10

  int? _parseRange(String text) {
    final lower = text.toLowerCase();

    // English: minutes
    var m = RegExp(r'(\d+)[-–](\d+)\s*(?:minute|min)s?').firstMatch(lower);
    if (m != null) return _midpoint(m, 60);

    // English: hours
    m = RegExp(r'(\d+)[-–](\d+)\s*(?:hour|hr)s?').firstMatch(lower);
    if (m != null) return _midpoint(m, 3600);

    // Telugu: నిమిషాలు
    m = RegExp(r'(\d+)[-–](\d+)\s*నిమిష(?:ాలు)?').firstMatch(text);
    if (m != null) return _midpoint(m, 60);

    // Telugu: గంటలు
    m = RegExp(r'(\d+)[-–](\d+)\s*గంటలు').firstMatch(text);
    if (m != null) return _midpoint(m, 3600);

    return null;
  }

  int? _midpoint(RegExpMatch m, int multiplier) {
    final a = int.tryParse(m.group(1)!);
    final b = int.tryParse(m.group(2)!);
    if (a == null || b == null || b <= a) return null;
    return ((a + b) ~/ 2) * multiplier;
  }

  // ── Explicit time parsing ──────────────────────────────────────────────────

  int? _parseExplicit(String text) {
    final lower = text.toLowerCase();

    // English — hours before minutes so "1 hour 30 min" totals correctly
    var m = RegExp(r'(\d+)\s*(?:hour|hr)s?').firstMatch(lower);
    if (m != null) {
      final h = int.tryParse(m.group(1)!);
      // Also look for trailing minutes e.g. "1 hour 30 minutes"
      final minM = RegExp(r'(\d+)\s*(?:minute|min)s?')
          .allMatches(lower)
          .where((mm) => mm.start > m!.start)
          .firstOrNull;
      final extraMins = minM != null ? (int.tryParse(minM.group(1)!) ?? 0) : 0;
      if (h != null && h > 0 && h <= 24) return h * 3600 + extraMins * 60;
    }

    m = RegExp(r'(\d+)\s*(?:minute|min)s?').firstMatch(lower);
    if (m != null) {
      final n = int.tryParse(m.group(1)!);
      if (n != null && n > 0 && n <= 180) return n * 60;
    }

    m = RegExp(r'(\d+)\s*(?:second|sec)s?').firstMatch(lower);
    if (m != null) {
      final n = int.tryParse(m.group(1)!);
      if (n != null && n > 0 && n <= 3600) return n;
    }

    // Telugu: గంటలు (hours)
    m = RegExp(r'(\d+)\s*గంటలు').firstMatch(text);
    if (m != null) {
      final n = int.tryParse(m.group(1)!);
      if (n != null && n > 0 && n <= 24) return n * 3600;
    }

    // Telugu: నిమిషాలు (minutes)
    m = RegExp(r'(\d+)\s*నిమిష(?:ాలు)?').firstMatch(text);
    if (m != null) {
      final n = int.tryParse(m.group(1)!);
      if (n != null && n > 0 && n <= 180) return n * 60;
    }

    // Telugu: సెకన్లు (seconds)
    m = RegExp(r'(\d+)\s*సెకన్లు').firstMatch(text);
    if (m != null) {
      final n = int.tryParse(m.group(1)!);
      if (n != null && n > 0 && n <= 3600) return n;
    }

    return null;
  }

  // ── Keyword inference ──────────────────────────────────────────────────────
  // Ordered from most to least specific — first match wins.

  int? _inferFromKeywords(String text) {
    final lower = text.toLowerCase();

    // Passive — user doesn't stand at stove (handled separately via isPassiveStep)
    if (_matchesAny(lower, _passiveKeywords)) return 1800; // 30 min default

    // Long active cooking
    if (_matchesAny(lower, [
      'simmer',
      'boil',
      'bake',
      'steam',
      'pressure cook',
      'slow cook',
      'braise',
      'poach',
      'deep fry',
      'deep-fry',
      'ఉడికించండి',
      'మరిగించండి',
      'కుక్కర్',
    ])) {
      return 600; // 10 min
    }

    // Medium active cooking
    if (_matchesAny(lower, [
      'cook until',
      'until golden',
      'until soft',
      'until tender',
      'until fragrant',
      'until translucent',
      'until brown',
      'until done',
      'knead',
      'grind',
      'blend',
      'whisk',
      'beat',
      'వరకు ఉడికించండి',
      'బంగారు',
      'మెత్తబడే',
      'పిసకండి',
      'రుబ్బండి',
    ])) {
      return 300; // 5 min
    }

    // Quick active cooking
    if (_matchesAny(lower, [
      'sauté',
      'saute',
      'fry',
      'temper',
      'splutter',
      'crackle',
      'pop',
      'toast',
      'roast',
      'bloom',
      'stir-fry',
      'stir fry',
      'వేయించండి',
      'పోపు',
      'కాల్చండి',
    ])) {
      return 180; // 3 min
    }

    // Prep / assembly — minimal active time
    if (_matchesAny(lower, [
      'garnish',
      'serve',
      'transfer',
      'remove',
      'place',
      'set aside',
      'strain',
      'drain',
      'wash',
      'rinse',
      'peel',
      'chop',
      'slice',
      'dice',
      'add',
      'mix',
      'stir',
      'combine',
      'sprinkle',
      'squeeze',
      'pour',
      'అలంకరించి',
      'సర్వ్',
      'తీసి',
      'కడిగి',
      'తరగండి',
      'కలపండి',
      'వేయండి',
    ])) {
      return 60; // 1 min — keeps user engaged without being intrusive
    }

    return null;
  }

  // ── Fallback ───────────────────────────────────────────────────────────────

  int _proportionalFallback() {
    if (totalSteps <= 0) return 300;
    return ((totalCookMinutes * 60) / totalSteps).round().clamp(60, 1800);
  }

  // ── Data ───────────────────────────────────────────────────────────────────

  static const _passiveKeywords = [
    'marinate',
    'marinade',
    'soak',
    'rest',
    'refrigerate',
    'chill',
    'let it',
    'allow to',
    'leave for',
    'stand for',
    'set aside for',
    'cool down',
    'cool completely',
    'మ్యారినేట్',
    'నానబెట్టండి',
    'చల్లబడనివ్వండి',
  ];

  bool _matchesAny(String text, List<String> keywords) =>
      keywords.any((kw) => text.contains(kw));
}

// ─── Timer Source ─────────────────────────────────────────────────────────────

enum StepTimerSource {
  /// "simmer 10-15 minutes" — used midpoint
  range,

  /// "cook for 10 minutes" — exact
  explicit,

  /// "sauté onions" — inferred from action verb
  keyword,

  /// recipe total ÷ step count
  estimated,
}

extension StepTimerSourceLabel on StepTimerSource {
  String label(bool isTelugu) => switch (this) {
        StepTimerSource.range =>
          isTelugu ? '⏱ పరిధి నుండి సగటు' : '⏱ Midpoint of range',
        StepTimerSource.explicit =>
          isTelugu ? '⏱ దశలో సమయం కనుగొనబడింది' : '⏱ Detected from step',
        StepTimerSource.keyword =>
          isTelugu ? '⏱ చర్య ఆధారంగా అంచనా' : '⏱ Estimated from action',
        StepTimerSource.estimated =>
          isTelugu ? '⏱ మొత్తం సమయం నుండి అంచనా' : '⏱ Estimated from total',
      };

  Color get color => switch (this) {
        StepTimerSource.range => const Color(0xFF1565C0), // blue  — confident
        StepTimerSource.explicit =>
          const Color(0xFF2E7D32), // green — confident
        StepTimerSource.keyword => const Color(0xFFE65100), // orange — inferred
        StepTimerSource.estimated =>
          const Color(0xFF757575), // grey   — fallback
      };

  IconData get icon => switch (this) {
        StepTimerSource.range => Icons.swap_horiz_rounded,
        StepTimerSource.explicit => Icons.check_circle_outline_rounded,
        StepTimerSource.keyword => Icons.auto_awesome_rounded,
        StepTimerSource.estimated => Icons.timer_outlined,
      };
}
