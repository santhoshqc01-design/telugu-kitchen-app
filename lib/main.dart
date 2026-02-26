import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import 'blocs/recipe/recipe_bloc.dart' as recipe_bloc;
import 'blocs/voice/voice_bloc.dart';
import 'blocs/language/language_bloc.dart';
import 'blocs/favorites/favorites_bloc.dart' as favorites_bloc;
import 'screens/home_screen.dart';
import 'services/tts_service.dart';
import 'services/speech_service.dart';
import 'l10n/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const TeluguCookingApp());
}

class TeluguCookingApp extends StatelessWidget {
  const TeluguCookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (context) => LanguageBloc()..add(const LoadLanguage())),
        BlocProvider(
            create: (context) => VoiceBloc(
                  ttsService: TTSService(),
                  speechService: SpeechService(),
                )),
        BlocProvider(
            create: (context) =>
                recipe_bloc.RecipeBloc()..add(const recipe_bloc.LoadRecipes())),
        BlocProvider(
            create: (context) => favorites_bloc.FavoritesBloc()
              ..add(const favorites_bloc.LoadFavorites())),
      ],
      child: BlocBuilder<LanguageBloc, LanguageState>(
        builder: (context, languageState) {
          return MaterialApp(
            title: 'Ruchi',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFFE65100),
                brightness: Brightness.light,
              ),
              textTheme: GoogleFonts.notoSansTeluguTextTheme(
                Theme.of(context).textTheme,
              ),
              cardTheme: const CardThemeData(
                elevation: 4,
              ),
            ),
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
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
