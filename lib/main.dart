import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'blocs/recipe/recipe_bloc.dart';
import 'blocs/voice/voice_bloc.dart';
import 'blocs/language/language_bloc.dart';
import 'repositories/favorites_repository.dart';
import 'repositories/timer_learning_repository.dart';
import 'service_locator.dart';
import 'screens/splash_screen.dart';
import 'services/tts_service.dart';
import 'services/speech_service.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize SharedPreferences once at startup and inject into the bloc.
  // This avoids async calls inside the bloc itself.
  final favoritesRepo = await FavoritesRepository.create();
  final learningRepo = await TimerLearningRepository.create();

  // Make repos accessible to screens that don't go through BLoC
  ServiceLocator.instance.init(learningRepo: learningRepo);

  runApp(RuchiApp(
    favoritesRepository: favoritesRepo,
    learningRepository: learningRepo,
  ));
}

// ─── Root ─────────────────────────────────────────────────────────────────────

class RuchiApp extends StatelessWidget {
  final FavoritesRepository favoritesRepository;
  final TimerLearningRepository learningRepository;

  const RuchiApp({
    super.key,
    required this.favoritesRepository,
    required this.learningRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => LanguageBloc()..add(const LoadLanguage()),
        ),
        BlocProvider(
          create: (_) => VoiceBloc(
            ttsService: TTSService(),
            speechService: SpeechService(),
          ),
        ),
        BlocProvider(
          create: (_) => RecipeBloc(
            favoritesRepository: favoritesRepository,
          )..add(const LoadRecipes()),
        ),
      ],
      child: const _RuchiMaterialApp(),
    );
  }
}

// ─── Rest of file unchanged from previous session ─────────────────────────────

class _RuchiMaterialApp extends StatelessWidget {
  const _RuchiMaterialApp();

  @override
  Widget build(BuildContext context) {
    final languageState = context.watch<LanguageBloc>().state;

    return MaterialApp(
      title: 'Ruchi • రుచి',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.system,
      locale: languageState.locale,
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('te', 'IN'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return _AppShell(child: child ?? const SizedBox.shrink());
      },
      home: const SplashScreen(),
    );
  }

  ThemeData _buildLightTheme() {
    const seedColor = Color(0xFFE65100);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      primary: seedColor,
      secondary: const Color(0xFFFF8F00),
      tertiary: const Color(0xFF2E7D32),
      error: const Color(0xFFB71C1C),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme:
          GoogleFonts.notoSansTeluguTextTheme(_buildTextTheme(colorScheme)),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: GoogleFonts.notoSansTelugu(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        clipBehavior: Clip.antiAlias,
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primaryContainer,
        labelStyle: GoogleFonts.notoSansTelugu(fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.notoSansTelugu(
              fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: seedColor, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.notoSansTelugu(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary);
          }
          return GoogleFonts.notoSansTelugu(
              fontSize: 12, color: colorScheme.onSurfaceVariant);
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        clipBehavior: Clip.antiAlias,
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: colorScheme.surface,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: seedColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return seedColor;
          return colorScheme.surfaceContainerHighest;
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: seedColor,
        circularTrackColor: seedColor.withValues(alpha: 0.2),
        linearTrackColor: seedColor.withValues(alpha: 0.2),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const seedColor = Color(0xFFFF7043);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      primary: seedColor,
      secondary: const Color(0xFFFFB300),
      tertiary: const Color(0xFF66BB6A),
      error: const Color(0xFFEF9A9A),
    );
    return _buildLightTheme().copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0F0F0F),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: GoogleFonts.notoSansTelugu(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1E1E1E),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2C2C2C)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1A1A1A),
        indicatorColor: seedColor.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.notoSansTelugu(
                fontSize: 12, fontWeight: FontWeight.w600, color: seedColor);
          }
          return GoogleFonts.notoSansTelugu(
              fontSize: 12, color: colorScheme.onSurfaceVariant);
        }),
      ),
    );
  }

  TextTheme _buildTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      displayLarge: GoogleFonts.notoSansTelugu(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurface),
      displayMedium: GoogleFonts.notoSansTelugu(
          fontSize: 45,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurface),
      displaySmall: GoogleFonts.notoSansTelugu(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurface),
      headlineLarge: GoogleFonts.notoSansTelugu(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface),
      headlineMedium: GoogleFonts.notoSansTelugu(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface),
      headlineSmall: GoogleFonts.notoSansTelugu(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface),
      titleLarge: GoogleFonts.notoSansTelugu(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface),
      titleMedium: GoogleFonts.notoSansTelugu(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
          letterSpacing: 0.15),
      titleSmall: GoogleFonts.notoSansTelugu(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
          letterSpacing: 0.1),
      bodyLarge: GoogleFonts.notoSansTelugu(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurface,
          height: 1.6),
      bodyMedium: GoogleFonts.notoSansTelugu(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurface,
          height: 1.5),
      bodySmall: GoogleFonts.notoSansTelugu(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurfaceVariant,
          height: 1.4),
      labelLarge: GoogleFonts.notoSansTelugu(
          fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
      labelMedium: GoogleFonts.notoSansTelugu(
          fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5),
      labelSmall: GoogleFonts.notoSansTelugu(
          fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
    );
  }
}

// ─── App Shell ────────────────────────────────────────────────────────────────

class _AppShell extends StatelessWidget {
  final Widget child;
  const _AppShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _ConnectivityBanner(),
        Expanded(child: child),
      ],
    );
  }
}

// ─── Connectivity Banner ──────────────────────────────────────────────────────

class _ConnectivityBanner extends StatefulWidget {
  const _ConnectivityBanner();

  @override
  State<_ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<_ConnectivityBanner>
    with SingleTickerProviderStateMixin {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  bool _isOnline = true;
  bool _showBanner = false;
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;
  bool _initialCheckDone = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    // Set initial state synchronously so the listener never fires before
    // we know the baseline — avoids false "Back online" on launch.
    _connectivity.checkConnectivity().then((results) {
      if (!mounted) return;
      final online = _isConnected(results);
      setState(() {
        _isOnline = online;
        _initialCheckDone = true;
      });
    });

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      if (!_initialCheckDone) return;
      final nowOnline = _isConnected(results);
      // Only show banner if status genuinely changed
      if (nowOnline != _isOnline) _onConnectivityChanged(nowOnline);
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _animController.dispose();
    super.dispose();
  }

  bool _isConnected(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  void _onConnectivityChanged(bool isOnline) {
    if (!mounted) return;
    setState(() {
      _isOnline = isOnline;
      _showBanner = true;
    });
    _animController.forward(from: 0);
    // Auto-dismiss "back online" after 3s; offline banner stays until reconnected
    if (isOnline) {
      Future.delayed(const Duration(seconds: 3), _dismissBanner);
    }
  }

  void _dismissBanner() {
    if (!mounted) return;
    _animController.reverse().then((_) {
      if (mounted) setState(() => _showBanner = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_showBanner) return const SizedBox.shrink();
    return SlideTransition(
      position: _slideAnim,
      child: Material(
        color: _isOnline ? const Color(0xFF2E7D32) : const Color(0xFFB71C1C),
        elevation: 4,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(
                  _isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _isOnline
                        ? 'Back online • రుచి అప్డేట్ అవుతోంది'
                        : 'No internet • కాష్డ్ రెసిపీలు చూపిస్తున్నాం',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _dismissBanner,
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
