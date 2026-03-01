import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import 'home_screen.dart';

// ─── Splash Screen ────────────────────────────────────────────────────────────
// Animated splash with Lottie cooking pot animation.
//
// 🌐 Currently loads animation from network (no local file needed to test).
//
// 👇 TO SWITCH TO LOCAL FILE (production):
//   1. Visit https://lottiefiles.com → search "cooking pot"
//   2. Download JSON → save as assets/lottie/food_animation.json
//   3. In _buildLottieWidget(), comment out Lottie.network() and
//      uncomment Lottie.asset() — one line change.
// ─────────────────────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  // Asset: local file path (used after you download the file)
  static const String _lottiePath = 'assets/lottie/food_animation.json';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Animation Controllers ──────────────────────────────────────────────────
  late AnimationController _bgController;
  late AnimationController _lottieController;
  late AnimationController _titleController;
  late AnimationController _dotsController;

  // ── Animations ────────────────────────────────────────────────────────────
  late Animation<double> _bgScale;
  late Animation<double> _lottieOpacity;
  late Animation<double> _lottieScale;
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleOpacity;
  late Animation<Offset> _taglineSlide;
  late Animation<double> _taglineOpacity;
  late Animation<double> _badgeOpacity;
  late Animation<double> _dotsOpacity;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFBF360C),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _initControllers();
    _initAnimations();
    _startSequence();
  }

  void _initControllers() {
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _lottieController = AnimationController(vsync: this);
    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  void _initAnimations() {
    _bgScale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeOut),
    );

    _lottieOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _bgController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeIn),
      ),
    );
    _lottieScale = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(
        parent: _bgController,
        curve: const Interval(0.2, 0.85, curve: Curves.elasticOut),
      ),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeOutCubic),
    );
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _titleController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _titleController,
        curve: const Interval(0.25, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _titleController,
        curve: const Interval(0.25, 0.85, curve: Curves.easeIn),
      ),
    );

    _badgeOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _titleController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _dotsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _dotsController, curve: Curves.easeIn),
    );
  }

  Future<void> _startSequence() async {
    _bgController.forward();

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    _titleController.forward();

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _dotsController.forward();

    await Future.delayed(const Duration(milliseconds: 1900));
    if (!mounted) return;
    _navigateToHome();
  }

  void _navigateToHome() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _bgController.dispose();
    _lottieController.dispose();
    _titleController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _bgController,
          _titleController,
          _dotsController,
        ]),
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              _buildBackground(),
              _buildDecorativeElements(size),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isShortScreen = constraints.maxHeight < 600;
                    final lottieRatio = isShortScreen ? 0.30 : 0.50;
                    return SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: isShortScreen ? 16 : 40),
                            _buildLottieSection(size, ratio: lottieRatio),
                            SizedBox(height: isShortScreen ? 12 : 28),
                            _buildTitle(),
                            SizedBox(height: isShortScreen ? 10 : 18),
                            _buildTagline(),
                            SizedBox(height: isShortScreen ? 10 : 20),
                            _buildBadge(),
                            SizedBox(height: isShortScreen ? 12 : 40),
                            _buildLoadingDots(),
                            SizedBox(height: isShortScreen ? 16 : 44),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackground() {
    return Transform.scale(
      scale: _bgScale.value,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF6D00),
              Color(0xFFE65100),
              Color(0xFFBF360C),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildDecorativeElements(Size size) {
    final opacity = _bgController.value;
    return Stack(
      children: [
        Positioned(
          top: -size.width * 0.25,
          left: -size.width * 0.15,
          child: Opacity(
            opacity: (opacity * 0.12).clamp(0.0, 1.0),
            child: Container(
              width: size.width * 0.7,
              height: size.width * 0.7,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -size.width * 0.3,
          right: -size.width * 0.15,
          child: Opacity(
            opacity: (opacity * 0.08).clamp(0.0, 1.0),
            child: Container(
              width: size.width * 0.8,
              height: size.width * 0.8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Positioned(
          top: size.height * 0.12,
          right: size.width * 0.08,
          child: Opacity(
            opacity: (opacity * 0.18).clamp(0.0, 1.0),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: size.height * 0.2,
          left: size.width * 0.06,
          child: Opacity(
            opacity: (opacity * 0.14).clamp(0.0, 1.0),
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLottieSection(Size size, {double ratio = 0.55}) {
    final lottieSize = size.width * ratio;

    return FadeTransition(
      opacity: _lottieOpacity,
      child: ScaleTransition(
        scale: _lottieScale,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring
            Container(
              width: lottieSize + 24,
              height: lottieSize + 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            // Inner circle with Lottie
            Container(
              width: lottieSize,
              height: lottieSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 48,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: _buildLottieWidget(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Lottie Widget ───────────────────────────────────────────────────────────
  // 🌐 NETWORK MODE (current — works without any local file)
  // To switch to local asset, comment out Lottie.network() block and
  // uncomment the Lottie.asset() block below it.
  Widget _buildLottieWidget() {
    // 📁 LOCAL ASSET (active — requires food_animation.json in assets/lottie/)
    // If file is missing, falls back to animated chef icon automatically.
    return Lottie.asset(
      SplashScreen._lottiePath,
      controller: _lottieController,
      fit: BoxFit.contain,
      onLoaded: (composition) {
        if (!mounted) return;
        _lottieController.duration = composition.duration;
        _lottieController.forward();
      },
      frameBuilder: (context, child, composition) {
        if (composition == null) return _buildLottieFallback();
        return child;
      },
      errorBuilder: (context, error, stackTrace) {
        // File not found — start lottie controller anyway so timing still works
        Future.microtask(() {
          if (mounted && !_lottieController.isAnimating) {
            _lottieController.duration = const Duration(seconds: 3);
            _lottieController.forward();
          }
        });
        return _buildLottieFallback();
      },
    );

    // 🌐 NETWORK — uncomment to load from URL instead of local file
    // return Lottie.network(
    //   SplashScreen._lottieNetworkUrl,
    //   controller: _lottieController,
    //   fit: BoxFit.contain,
    //   onLoaded: (composition) {
    //     if (!mounted) return;
    //     _lottieController.duration = composition.duration;
    //     _lottieController.forward();
    //   },
    //   errorBuilder: (context, error, stackTrace) => _buildLottieFallback(),
    // );
  }

  Widget _buildLottieFallback() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.restaurant_menu_rounded,
            size: 80,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            'రుచి',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return FadeTransition(
      opacity: _titleOpacity,
      child: SlideTransition(
        position: _titleSlide,
        child: Column(
          children: [
            Text(
              'Ruchi',
              style: GoogleFonts.notoSansTelugu(
                fontSize: 54,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -1.5,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'రుచి',
              style: GoogleFonts.notoSansTelugu(
                fontSize: 26,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.85),
                letterSpacing: 3.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagline() {
    return FadeTransition(
      opacity: _taglineOpacity,
      child: SlideTransition(
        position: _taglineSlide,
        child: Column(
          children: [
            _buildDivider(),
            const SizedBox(height: 14),
            Text(
              'Traditional Telugu Cuisine',
              style: GoogleFonts.notoSansTelugu(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.72),
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'సాంప్రదాయ తెలుగు వంటకాలు',
              style: GoogleFonts.notoSansTelugu(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.92),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _line(),
        const SizedBox(width: 8),
        _dot(),
        const SizedBox(width: 5),
        _dot(size: 4),
        const SizedBox(width: 5),
        _dot(),
        const SizedBox(width: 8),
        _line(),
      ],
    );
  }

  Widget _line() => Container(
        width: 28,
        height: 1,
        color: Colors.white.withValues(alpha: 0.35),
      );

  Widget _dot({double size = 5}) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      );

  Widget _buildBadge() {
    return FadeTransition(
      opacity: _badgeOpacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_rounded,
              size: 13,
              color: Colors.white.withValues(alpha: 0.85),
            ),
            const SizedBox(width: 6),
            Text(
              'Made for Telugu food lovers',
              style: GoogleFonts.notoSansTelugu(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.85),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingDots() {
    return FadeTransition(
      opacity: _dotsOpacity,
      child: const _PulsatingDots(),
    );
  }
}

// ─── Pulsating Dots ───────────────────────────────────────────────────────────

class _PulsatingDots extends StatefulWidget {
  const _PulsatingDots();

  @override
  State<_PulsatingDots> createState() => _PulsatingDotsState();
}

class _PulsatingDotsState extends State<_PulsatingDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnims;
  late List<Animation<double>> _opacityAnims;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(
      3,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 700),
      ),
    );

    _scaleAnims = _controllers.map((c) {
      return Tween<double>(begin: 0.55, end: 1.0).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();

    _opacityAnims = _controllers.map((c) {
      return Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();

    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 220), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _controllers[i],
          builder: (_, __) {
            return Transform.scale(
              scale: _scaleAnims[i].value,
              child: Opacity(
                opacity: _opacityAnims[i].value,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
