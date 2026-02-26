import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appName': 'Ruchi Cooking',
      'searchHint': 'Search recipes...',
      'categories': 'Categories',
      'favorites': 'Favorites',
      'settings': 'Settings',
      'language': 'Language',
      'voiceCommands': 'Voice Commands',
      'ingredients': 'Ingredients',
      'instructions': 'Instructions',
      'cookTime': 'Cook Time',
      'servings': 'Servings',
      'difficulty': 'Difficulty',
      'startCooking': 'Start Cooking',
      'nextStep': 'Next Step',
      'previousStep': 'Previous Step',
      'repeat': 'Repeat',
      'listening': 'Listening...',
      'speakNow': 'Speak now in Telugu or English',
      'error': 'Error',
      'noRecipes': 'No recipes found',
      'addToFavorites': 'Add to favorites',
      'removeFromFavorites': 'Remove from favorites',
      'shareRecipe': 'Share recipe',
      'calories': 'Calories',
      'protein': 'Protein',
      'carbs': 'Carbs',
      'fat': 'Fat',
      'vegetarian': 'Vegetarian',
      'nonVegetarian': 'Non-Vegetarian',
      'breakfast': 'Breakfast',
      'lunch': 'Lunch',
      'dinner': 'Dinner',
      'snacks': 'Snacks',
      'desserts': 'Desserts',
      'beverages': 'Beverages',
      'andhra': 'Andhra',
      'telangana': 'Telangana',
      'rayalaseema': 'Rayalaseema',
    },
    'te': {
      'appName': 'రుచి వంటకాలు',
      'searchHint': 'వంటకాలను శోధించండి...',
      'categories': 'వర్గాలు',
      'favorites': 'ఇష్టమైనవి',
      'settings': 'సెట్టింగ్స్',
      'language': 'భాష',
      'voiceCommands': 'వాయిస్ కమాండ్స్',
      'ingredients': 'పదార్థాలు',
      'instructions': 'తయారీ విధానం',
      'cookTime': 'వండే సమయం',
      'servings': 'సర్వింగ్స్',
      'difficulty': 'కష్టతరం',
      'startCooking': 'వండటం ప్రారంభించండి',
      'nextStep': 'తదుపరి అడుగు',
      'previousStep': 'మునుపటి అడుగు',
      'repeat': 'మళ్ళీ చెప్పు',
      'listening': 'వింటున్నాను...',
      'speakNow': 'తెలుగు లేదా ఆంగ్లంలో మాట్లాడండి',
      'error': 'లోపం',
      'noRecipes': 'వంటకాలు కనుగొనబడలేదు',
      'addToFavorites': 'ఇష్టమైనవాటిలో చేర్చు',
      'removeFromFavorites': 'ఇష్టమైనవాటి నుండి తీసివేయి',
      'shareRecipe': 'వంటకాన్ని షేర్ చేయండి',
      'calories': 'క్యాలరీలు',
      'protein': 'ప్రోటీన్',
      'carbs': 'కార్బోహైడ్రేట్లు',
      'fat': 'కొవ్వు',
      'vegetarian': 'శాకాహారం',
      'nonVegetarian': 'మాంసాహారం',
      'breakfast': 'ఉదయం భోజనం',
      'lunch': 'మధ్యాహ్న భోజనం',
      'dinner': 'రాత్రి భోజనం',
      'snacks': 'స్నాక్స్',
      'desserts': 'మిఠాయిలు',
      'beverages': 'పానీయాలు',
      'andhra': 'ఆంధ్ర',
      'telangana': 'తెలంగాణ',
      'rayalaseema': 'రాయలసీమ',
    },
  };

  String getString(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']![key]!;
  }

  String get appName => getString('appName');
  String get searchHint => getString('searchHint');
  String get categories => getString('categories');
  String get favorites => getString('favorites');
  String get settings => getString('settings');
  String get language => getString('language');
  String get voiceCommands => getString('voiceCommands');
  String get ingredients => getString('ingredients');
  String get instructions => getString('instructions');
  String get cookTime => getString('cookTime');
  String get servings => getString('servings');
  String get difficulty => getString('difficulty');
  String get startCooking => getString('startCooking');
  String get nextStep => getString('nextStep');
  String get previousStep => getString('previousStep');
  String get repeat => getString('repeat');
  String get listening => getString('listening');
  String get speakNow => getString('speakNow');
  String get error => getString('error');
  String get noRecipes => getString('noRecipes');
  String get addToFavorites => getString('addToFavorites');
  String get removeFromFavorites => getString('removeFromFavorites');
  String get shareRecipe => getString('shareRecipe');
  String get calories => getString('calories');
  String get protein => getString('protein');
  String get carbs => getString('carbs');
  String get fat => getString('fat');
  String get vegetarian => getString('vegetarian');
  String get nonVegetarian => getString('nonVegetarian');
  String get breakfast => getString('breakfast');
  String get lunch => getString('lunch');
  String get dinner => getString('dinner');
  String get snacks => getString('snacks');
  String get desserts => getString('desserts');
  String get beverages => getString('beverages');
  String get andhra => getString('andhra');
  String get telangana => getString('telangana');
  String get rayalaseema => getString('rayalaseema');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'te'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
