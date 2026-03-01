import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/ingredient_image_service.dart';

/// A single ingredient row with a photo thumbnail, name, and quantity.
///
/// Shows:
///   [photo]  quantity + name
///
/// Photo loading states:
///   loading  → shimmer placeholder
///   loaded   → rounded image
///   error/null → colored letter avatar
class IngredientTile extends StatefulWidget {
  final String rawIngredient;

  /// English version of the ingredient — used for image lookup even when
  /// the UI is showing Telugu text (better Wikipedia/curated map coverage).
  final String? englishRaw;
  final bool isAdjusted; // true when serving multiplier != 1.0
  final bool isTablet;
  final double imageSize;

  const IngredientTile({
    super.key,
    required this.rawIngredient,
    this.englishRaw,
    this.isAdjusted = false,
    this.isTablet = false,
    this.imageSize = 48,
  });

  @override
  State<IngredientTile> createState() => _IngredientTileState();
}

class _IngredientTileState extends State<IngredientTile> {
  late Future<String?> _imageFuture;
  final _svc = IngredientImageService.instance;

  @override
  void initState() {
    super.initState();
    // Use English for image lookup — better coverage in curated map & Wikipedia
    _imageFuture = _svc.imageUrl(widget.englishRaw ?? widget.rawIngredient);
  }

  @override
  Widget build(BuildContext context) {
    final name = _svc.extractName(widget.rawIngredient);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Photo thumbnail ──────────────────────────────────────────────
          _IngredientPhoto(
            future: _imageFuture,
            name: name,
            size: widget.imageSize,
            svc: _svc,
          ),
          const SizedBox(width: 12),

          // ── Text ─────────────────────────────────────────────────────────
          Expanded(
            child: Text(
              widget.rawIngredient,
              style: TextStyle(
                fontSize: widget.isTablet ? 16 : 14,
                fontWeight:
                    widget.isAdjusted ? FontWeight.w600 : FontWeight.normal,
                height: 1.4,
              ),
            ),
          ),

          // Adjusted indicator
          if (widget.isAdjusted)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(Icons.auto_awesome_rounded,
                  size: 13, color: Colors.orange.shade700),
            ),
        ],
      ),
    );
  }
}

// ── Photo widget with shimmer → image → avatar states ─────────────────────────

class _IngredientPhoto extends StatelessWidget {
  final Future<String?> future;
  final String name;
  final double size;
  final IngredientImageService svc;

  const _IngredientPhoto({
    required this.future,
    required this.name,
    required this.size,
    required this.svc,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _Shimmer(size: size);
        }
        final url = snap.data;
        if (url != null) {
          return _NetworkImage(url: url, size: size, name: name, svc: svc);
        }
        return _AvatarFallback(name: name, size: size, svc: svc);
      },
    );
  }
}

// Shimmer placeholder while loading
class _Shimmer extends StatefulWidget {
  final double size;
  const _Shimmer({required this.size});
  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 0.7).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey.withValues(alpha: _anim.value),
          ),
        ),
      );
}

// Network image with error fallback
class _NetworkImage extends StatelessWidget {
  final String url;
  final double size;
  final String name;
  final IngredientImageService svc;

  const _NetworkImage({
    required this.url,
    required this.size,
    required this.name,
    required this.svc,
  });

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CachedNetworkImage(
          imageUrl: url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (context, url, dynamic error) =>
              _AvatarFallback(name: name, size: size, svc: svc),
          placeholder: (context, url) => _Shimmer(size: size),
        ),
      );
}

// Colored circle with emoji / first letter
class _AvatarFallback extends StatelessWidget {
  final String name;
  final double size;
  final IngredientImageService svc;

  const _AvatarFallback({
    required this.name,
    required this.size,
    required this.svc,
  });

  // Map common ingredient names to relevant emojis
  static const _emojiMap = {
    'chicken': '🍗',
    'mutton': '🥩',
    'fish': '🐟',
    'prawn': '🍤',
    'egg': '🥚',
    'rice': '🍚',
    'onion': '🧅',
    'garlic': '🧄',
    'tomato': '🍅',
    'lemon': '🍋',
    'coconut': '🥥',
    'chili': '🌶️',
    'spinach': '🥬',
    'peas': '🫛',
    'eggplant': '🍆',
    'milk': '🥛',
    'oil': '🫙',
    'salt': '🧂',
    'sugar': '🍬',
    'coffee': '☕',
    'bread': '🍞',
    'almond': '🌰',
    'cashew': '🥜',
    'peanut': '🥜',
    'mint': '🌿',
    'coriander': '🌿',
    'ginger': '🫚',
    'turmeric': '🌼',
  };

  String get _emoji {
    final lower = name.toLowerCase();
    for (final entry in _emojiMap.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final color = svc.avatarColor(name);
    final label = _emoji;
    final isEmoji = label.runes.length == 1 && label.codeUnits.first > 127;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: isEmoji ? size * 0.5 : size * 0.4,
            color: isEmoji ? null : color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
