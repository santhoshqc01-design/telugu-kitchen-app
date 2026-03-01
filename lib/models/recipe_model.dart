import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

// ─── Recipe Model ─────────────────────────────────────────────────────────────

class Recipe extends Equatable {
  final String id;
  final String title;
  final String titleTe;
  final String description;
  final String descriptionTe;
  final String imageUrl;
  final List<String> ingredients;
  final List<String> ingredientsTe;
  final List<String> instructions;
  final List<String> instructionsTe;
  final int cookTimeMinutes;
  final int servings;
  final String category;
  final String region;
  final bool isVegetarian;
  final double rating;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final String difficulty;
  final List<String> tags;

  const Recipe({
    required this.id,
    required this.title,
    required this.titleTe,
    required this.description,
    required this.descriptionTe,
    required this.imageUrl,
    required this.ingredients,
    required this.ingredientsTe,
    required this.instructions,
    required this.instructionsTe,
    required this.cookTimeMinutes,
    required this.servings,
    required this.category,
    required this.region,
    required this.isVegetarian,
    required this.rating,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.difficulty,
    required this.tags,
  });

  // ── Computed Properties ────────────────────────────────────────────────────

  /// Sanitized image URL with whitespace trimmed (fixes mobile loading issues)
  String get sanitizedImageUrl => imageUrl.trim();

  /// Display-ready cook time e.g. "45 min" or "1 hr 30 min"
  String get cookTimeDisplay {
    if (cookTimeMinutes < 60) return '$cookTimeMinutes min';
    final hours = cookTimeMinutes ~/ 60;
    final mins = cookTimeMinutes % 60;
    return mins == 0 ? '$hours hr' : '$hours hr $mins min';
  }

  /// Short cook time label for cards
  String get cookTimeShort => '$cookTimeMinutes min';

  /// Nutrition summary string
  String get nutritionSummary =>
      '$calories cal · ${protein.toStringAsFixed(0)}g protein · '
      '${carbs.toStringAsFixed(0)}g carbs · ${fat.toStringAsFixed(0)}g fat';

  /// True if the recipe is quick (under 30 mins)
  bool get isQuick => cookTimeMinutes <= 30;

  /// Rating display string e.g. "4.8"
  String get ratingDisplay => rating.toStringAsFixed(1);

  /// Telugu/English bilingual title for display
  String get bilingualTitle => '$title • $titleTe';

  // ── Color Helpers ──────────────────────────────────────────────────────────

  Color get regionColor {
    switch (region) {
      case 'Andhra':
        return const Color(0xFFE65100); // Deep orange
      case 'Telangana':
        return const Color(0xFF6A1B9A); // Purple
      case 'Rayalaseema':
        return const Color(0xFF2E7D32); // Green
      default:
        return const Color(0xFF1565C0); // Blue
    }
  }

  Color get difficultyColor {
    switch (difficulty) {
      case 'Easy':
        return const Color(0xFF2E7D32); // Green
      case 'Medium':
        return const Color(0xFFE65100); // Orange
      case 'Hard':
        return const Color(0xFFB71C1C); // Red
      default:
        return const Color(0xFF757575); // Grey
    }
  }

  Color get categoryColor {
    switch (category) {
      case 'Breakfast':
        return const Color(0xFFF57F17);
      case 'Lunch':
        return const Color(0xFF1B5E20);
      case 'Dinner':
        return const Color(0xFF1A237E);
      case 'Snacks':
        return const Color(0xFF880E4F);
      case 'Desserts':
        return const Color(0xFF4A148C);
      case 'Beverages':
        return const Color(0xFF006064);
      default:
        return const Color(0xFF37474F);
    }
  }

  // ── Icon Helpers ───────────────────────────────────────────────────────────

  IconData get categoryIcon {
    switch (category) {
      case 'Breakfast':
        return Icons.free_breakfast_rounded;
      case 'Lunch':
        return Icons.lunch_dining_rounded;
      case 'Dinner':
        return Icons.dinner_dining_rounded;
      case 'Snacks':
        return Icons.fastfood_rounded;
      case 'Desserts':
        return Icons.cake_rounded;
      case 'Beverages':
        return Icons.local_cafe_rounded;
      default:
        return Icons.restaurant_rounded;
    }
  }

  IconData get difficultyIcon {
    switch (difficulty) {
      case 'Easy':
        return Icons.sentiment_satisfied_rounded;
      case 'Medium':
        return Icons.sentiment_neutral_rounded;
      case 'Hard':
        return Icons.sentiment_very_dissatisfied_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  // ── Serialization ──────────────────────────────────────────────────────────

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String,
      title: json['title'] as String,
      titleTe: json['titleTe'] as String,
      description: json['description'] as String,
      descriptionTe: json['descriptionTe'] as String,
      // Trim imageUrl to fix mobile loading issues with trailing spaces
      imageUrl: (json['imageUrl'] as String).trim(),
      ingredients: List<String>.from(json['ingredients'] as List),
      ingredientsTe: List<String>.from(json['ingredientsTe'] as List),
      instructions: List<String>.from(json['instructions'] as List),
      instructionsTe: List<String>.from(json['instructionsTe'] as List),
      cookTimeMinutes: json['cookTimeMinutes'] as int,
      servings: json['servings'] as int,
      category: json['category'] as String,
      region: json['region'] as String,
      isVegetarian: json['isVegetarian'] as bool,
      rating: (json['rating'] as num).toDouble(),
      calories: json['calories'] as int,
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      difficulty: json['difficulty'] as String,
      tags: List<String>.from(json['tags'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'titleTe': titleTe,
      'description': description,
      'descriptionTe': descriptionTe,
      'imageUrl': imageUrl,
      'ingredients': ingredients,
      'ingredientsTe': ingredientsTe,
      'instructions': instructions,
      'instructionsTe': instructionsTe,
      'cookTimeMinutes': cookTimeMinutes,
      'servings': servings,
      'category': category,
      'region': region,
      'isVegetarian': isVegetarian,
      'rating': rating,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'difficulty': difficulty,
      'tags': tags,
    };
  }

  // ── CopyWith ───────────────────────────────────────────────────────────────
  // Useful for updating a recipe (e.g. toggling favorite, updating rating)

  Recipe copyWith({
    String? id,
    String? title,
    String? titleTe,
    String? description,
    String? descriptionTe,
    String? imageUrl,
    List<String>? ingredients,
    List<String>? ingredientsTe,
    List<String>? instructions,
    List<String>? instructionsTe,
    int? cookTimeMinutes,
    int? servings,
    String? category,
    String? region,
    bool? isVegetarian,
    double? rating,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
    String? difficulty,
    List<String>? tags,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      titleTe: titleTe ?? this.titleTe,
      description: description ?? this.description,
      descriptionTe: descriptionTe ?? this.descriptionTe,
      imageUrl: imageUrl ?? this.imageUrl,
      ingredients: ingredients ?? this.ingredients,
      ingredientsTe: ingredientsTe ?? this.ingredientsTe,
      instructions: instructions ?? this.instructions,
      instructionsTe: instructionsTe ?? this.instructionsTe,
      cookTimeMinutes: cookTimeMinutes ?? this.cookTimeMinutes,
      servings: servings ?? this.servings,
      category: category ?? this.category,
      region: region ?? this.region,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      rating: rating ?? this.rating,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      difficulty: difficulty ?? this.difficulty,
      tags: tags ?? this.tags,
    );
  }

  @override
  List<Object> get props => [
        id,
        title,
        titleTe,
        description,
        descriptionTe,
        imageUrl,
        ingredients,
        ingredientsTe,
        instructions,
        instructionsTe,
        cookTimeMinutes,
        servings,
        category,
        region,
        isVegetarian,
        rating,
        calories,
        protein,
        carbs,
        fat,
        difficulty,
        tags,
      ];

  @override
  String toString() => 'Recipe(id: $id, title: $title, region: $region)';
}

// ─── Constants ────────────────────────────────────────────────────────────────

class RecipeCategories {
  static const String breakfast = 'Breakfast';
  static const String lunch = 'Lunch';
  static const String dinner = 'Dinner';
  static const String snacks = 'Snacks';
  static const String desserts = 'Desserts';
  static const String beverages = 'Beverages';

  static const List<String> all = [
    breakfast,
    lunch,
    dinner,
    snacks,
    desserts,
    beverages,
  ];

  static const Map<String, String> telugu = {
    breakfast: 'ప్రాతః భోజనం',
    lunch: 'మధ్యాహ్న భోజనం',
    dinner: 'రాత్రి భోజనం',
    snacks: 'స్నాక్స్',
    desserts: 'మిఠాయిలు',
    beverages: 'పానీయాలు',
  };
}

class RecipeRegions {
  static const String andhra = 'Andhra';
  static const String telangana = 'Telangana';
  static const String rayalaseema = 'Rayalaseema';

  static const List<String> all = [andhra, telangana, rayalaseema];

  static const Map<String, String> telugu = {
    andhra: 'ఆంధ్ర',
    telangana: 'తెలంగాణ',
    rayalaseema: 'రాయలసీమ',
  };
}

class RecipeDifficulty {
  static const String easy = 'Easy';
  static const String medium = 'Medium';
  static const String hard = 'Hard';

  static const List<String> all = [easy, medium, hard];

  static const Map<String, String> telugu = {
    easy: 'సులభం',
    medium: 'మధ్యస్థం',
    hard: 'కష్టం',
  };
}

// ─── Filter & Search Helpers ──────────────────────────────────────────────────

extension RecipeListExtensions on List<Recipe> {
  /// Filter by category
  List<Recipe> byCategory(String category) =>
      where((r) => r.category == category).toList();

  /// Filter by region
  List<Recipe> byRegion(String region) =>
      where((r) => r.region == region).toList();

  /// Filter vegetarian only
  List<Recipe> get vegetarianOnly => where((r) => r.isVegetarian).toList();

  /// Filter non-vegetarian only
  List<Recipe> get nonVegOnly => where((r) => !r.isVegetarian).toList();

  /// Filter quick recipes (≤30 mins)
  List<Recipe> get quickOnly => where((r) => r.isQuick).toList();

  /// Filter by max cook time
  List<Recipe> maxCookTime(int minutes) =>
      where((r) => r.cookTimeMinutes <= minutes).toList();

  /// Filter by difficulty
  List<Recipe> byDifficulty(String difficulty) =>
      where((r) => r.difficulty == difficulty).toList();

  /// Sort by rating descending
  List<Recipe> get topRated =>
      [...this]..sort((a, b) => b.rating.compareTo(a.rating));

  /// Sort by cook time ascending
  List<Recipe> get quickestFirst =>
      [...this]..sort((a, b) => a.cookTimeMinutes.compareTo(b.cookTimeMinutes));

  /// Search by title, tags, or ingredients (Telugu + English)
  List<Recipe> search(String query) {
    if (query.trim().isEmpty) return this;
    final q = query.toLowerCase().trim();
    return where((r) {
      return r.title.toLowerCase().contains(q) ||
          r.titleTe.contains(q) ||
          r.description.toLowerCase().contains(q) ||
          r.descriptionTe.contains(q) ||
          r.tags.any((t) => t.toLowerCase().contains(q)) ||
          r.ingredients.any((i) => i.toLowerCase().contains(q)) ||
          r.ingredientsTe.any((i) => i.contains(q)) ||
          r.region.toLowerCase().contains(q) ||
          r.category.toLowerCase().contains(q);
    }).toList();
  }
}

// ─── Sample Data (25 authentic Telugu recipes) ───────────────────────────────

final List<Recipe> sampleRecipes = [
  // ==================== ANDHRA REGION ====================

  const Recipe(
    id: '1',
    title: 'Andhra Chicken Curry',
    titleTe: 'ఆంధ్ర చికెన్ కూర',
    description:
        'Spicy and flavorful chicken curry from Andhra region with rich masala',
    descriptionTe: 'గొడవల మసాలాతో రుచికరమైన ఆంధ్ర చికెన్ కూర',
    imageUrl:
        'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=800 ',
    ingredients: [
      '500g chicken',
      '2 onions, finely chopped',
      '2 tomatoes, chopped',
      '1 tbsp ginger-garlic paste',
      '2 green chilies',
      '1 tsp turmeric powder',
      '2 tsp red chili powder',
      '2 tsp coriander powder',
      '1 tsp garam masala',
      '3 tbsp oil',
      'Salt to taste',
      'Fresh coriander leaves',
    ],
    ingredientsTe: [
      '500 గ్రా చికెన్',
      '2 ఉల్లిపాయలు, సన్నగా తరిగినవి',
      '2 టమాటోలు, తరిగినవి',
      '1 టేబుల్ స్పూన్ అల్లం-వెల్లుల్లి ముద్ద',
      '2 పచ్చి మిరపకాయలు',
      '1 టీ స్పూన్ పసుపు',
      '2 టీ స్పూన్లు కారం',
      '2 టీ స్పూన్లు ధనియాల పొడి',
      '1 టీ స్పూన్ గరం మసాలా',
      '3 టేబుల్ స్పూన్లు నూనె',
      'రుచికి సరిపడా ఉప్పు',
      'కొత్తిమీర',
    ],
    instructions: [
      'Wash chicken pieces and marinate with turmeric, salt, and chili powder for 30 minutes',
      'Heat oil in a pan and sauté onions until golden brown',
      'Add ginger-garlic paste and green chilies, sauté for 2 minutes',
      'Add tomatoes and cook until soft',
      'Add marinated chicken and cook for 10 minutes',
      'Add coriander powder and garam masala, cook until chicken is tender',
      'Garnish with fresh coriander leaves and serve hot',
    ],
    instructionsTe: [
      'చికెన్ ముక్కలు కడిగి, పసుపు, ఉప్పు, కారంతో 30 నిమిషాలు మ్యారినేట్ చేయండి',
      'పాన్‌లో నూనె వేడి చేసి, ఉల్లిపాయలు బంగారు రంగు వచ్చేవరకు వేయించండి',
      'అల్లం-వెల్లుల్లి ముద్ద, పచ్చి మిరపకాయలు వేసి 2 నిమిషాలు వేయించండి',
      'టమాటోలు వేసి మెత్తబడేవరకు ఉడికించండి',
      'మ్యారినేట్ చేసిన చికెన్ వేసి 10 నిమిషాలు ఉడికించండి',
      'ధనియాల పొడి, గరం మసాలా వేసి చికెన్ మెత్తబడేవరకు ఉడికించండి',
      'కొత్తిమీరతో అలంకరించి వేడివేడిగా సర్వ్ చేయండి',
    ],
    cookTimeMinutes: 45,
    servings: 4,
    category: 'Lunch',
    region: 'Andhra',
    isVegetarian: false,
    rating: 4.8,
    calories: 320,
    protein: 28,
    carbs: 12,
    fat: 18,
    difficulty: 'Medium',
    tags: ['chicken', 'spicy', 'andhra', 'curry'],
  ),

  const Recipe(
    id: '2',
    title: 'Gongura Pachadi',
    titleTe: 'గోంగూర పచ్చడి',
    description: 'Tangy sorrel leaves chutney, a signature Andhra dish',
    descriptionTe: 'ఆంధ్రకు ప్రత్యేకమైన పుల్లటి గోంగూర ఆకుల పచ్చడి',
    imageUrl:
        'https://images.unsplash.com/photo-1606491956689-05f4575a45d8?w=800 ',
    ingredients: [
      '2 cups gongura (sorrel) leaves',
      '4 dry red chilies',
      '1 tsp mustard seeds',
      '1 tsp cumin seeds',
      '3 garlic cloves',
      '2 tbsp oil',
      'Salt to taste',
      'Pinch of asafoetida',
    ],
    ingredientsTe: [
      '2 కప్పులు గోంగూర ఆకులు',
      '4 ఎండు మిరపకాయలు',
      '1 టీ స్పూన్ ఆవాలు',
      '1 టీ స్పూన్ జీలకర్ర',
      '3 వెల్లుల్లి రెబ్బలు',
      '2 టేబుల్ స్పూన్లు నూనె',
      'రుచికి సరిపడా ఉప్పు',
      'చిటికెడు ఇంగువ',
    ],
    instructions: [
      'Wash and dry gongura leaves thoroughly',
      'Heat oil, fry red chilies, mustard, cumin, and garlic',
      'Add gongura leaves and sauté until wilted',
      'Cool and grind to coarse paste with salt',
      'Temper with mustard seeds and asafoetida',
      'Serve with hot rice and ghee',
    ],
    instructionsTe: [
      'గోంగూర ఆకులు కడిగి బాగా ఆరవేయండి',
      'నూనె వేడి చేసి, ఎండు మిరపకాయలు, ఆవాలు, జీలకర్ర, వెల్లుల్లి వేయించండి',
      'గోంగూర ఆకులు వేసి వాడేవరకు వేయించండి',
      'చల్లార్చి, ఉప్పుతో కచ్చాగా గ్రైండ్ చేయండి',
      'ఆవాలు, ఇంగువతో తాలింపు వేయండి',
      'వేడి అన్నంలో నెయ్యితో సర్వ్ చేయండి',
    ],
    cookTimeMinutes: 20,
    servings: 4,
    category: 'Lunch',
    region: 'Andhra',
    isVegetarian: true,
    rating: 4.9,
    calories: 85,
    protein: 3,
    carbs: 8,
    fat: 5,
    difficulty: 'Easy',
    tags: ['gongura', 'pachadi', 'andhra', 'chutney'],
  ),

  const Recipe(
    id: '3',
    title: 'Pesarattu',
    titleTe: 'పెసరట్టు',
    description: 'Green gram dosa, a healthy breakfast from Andhra',
    descriptionTe: 'ఆరోగ్యకరమైన ఆంధ్ర ప్రాతః భోజనం పెసరట్టు',
    imageUrl:
        'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=800 ',
    ingredients: [
      '1 cup green gram (moong dal)',
      '1/4 cup rice',
      '2 green chilies',
      '1 inch ginger',
      '1 tsp cumin seeds',
      'Salt to taste',
      'Oil for cooking',
      'Chopped onions for topping',
    ],
    ingredientsTe: [
      '1 కప్పు పెసరపప్పు',
      '1/4 కప్పు బియ్యం',
      '2 పచ్చి మిరపకాయలు',
      '1 అంగుళం అల్లం',
      '1 టీ స్పూన్ జీలకర్ర',
      'రుచికి సరిపడా ఉప్పు',
      'వేయించడానికి నూనె',
      'టాపింగ్ కోసం తరిగిన ఉల్లిపాయలు',
    ],
    instructions: [
      'Soak moong dal and rice for 4-6 hours',
      'Grind with green chilies, ginger, cumin, and salt to smooth batter',
      'Heat dosa pan and pour batter, spread thin',
      'Top with chopped onions and oil',
      'Cook until crispy and golden',
      'Serve with ginger chutney',
    ],
    instructionsTe: [
      'పెసరపప్పు, బియ్యం 4-6 గంటలు నానబెట్టండి',
      'పచ్చి మిరపకాయలు, అల్లం, జీలకర్ర, ఉప్పుతో మెత్తగా గ్రైండ్ చేయండి',
      'దోశ పాన్ వేడి చేసి, పిండి పోసి పల్చగా పరచండి',
      'తరిగిన ఉల్లిపాయలు, నూనె పైన వేయండి',
      'కరకరలాడేవరకు, బంగారు రంగు వచ్చేవరకు ఉడికించండి',
      'అల్లం పచ్చడితో సర్వ్ చేయండి',
    ],
    cookTimeMinutes: 30,
    servings: 4,
    category: 'Breakfast',
    region: 'Andhra',
    isVegetarian: true,
    rating: 4.7,
    calories: 180,
    protein: 10,
    carbs: 32,
    fat: 2,
    difficulty: 'Medium',
    tags: ['pesarattu', 'dosa', 'breakfast', 'healthy'],
  ),

  const Recipe(
    id: '4',
    title: 'Royyala Iguru',
    titleTe: 'రొయ్యల ఇగురు',
    description: 'Prawn fry with rich spice coating, coastal Andhra specialty',
    descriptionTe: 'మసాలాలతో కోస్టల్ ఆంధ్ర ప్రత్యేక రొయ్యల ఇగురు',
    imageUrl:
        'https://images.unsplash.com/photo-1563379926898-05f4575a45d8?w=800 ',
    ingredients: [
      '500g prawns, cleaned',
      '1 onion, finely chopped',
      '2 tbsp ginger-garlic paste',
      '2 tsp red chili powder',
      '1 tsp turmeric',
      '1 tsp coriander powder',
      '1 tsp cumin powder',
      '1 tsp garam masala',
      '3 tbsp oil',
      'Curry leaves',
      'Salt to taste',
    ],
    ingredientsTe: [
      '500 గ్రా శుద్ధం చేసిన రొయ్యలు',
      '1 ఉల్లిపాయ, సన్నగా తరిగినది',
      '2 టేబుల్ స్పూన్లు అల్లం-వెల్లుల్లి ముద్ద',
      '2 టీ స్పూన్లు కారం',
      '1 టీ స్పూన్ పసుపు',
      '1 టీ స్పూన్ ధనియాల పొడి',
      '1 టీ స్పూన్ జీలకర్ర పొడి',
      '1 టీ స్పూన్ గరం మసాలా',
      '3 టేబుల్ స్పూన్లు నూనె',
      'కరివేపాకు',
      'రుచికి సరిపడా ఉప్పు',
    ],
    instructions: [
      'Clean and devein prawns, marinate with turmeric and salt',
      'Heat oil and sauté onions until golden',
      'Add ginger-garlic paste and curry leaves, fry for 2 minutes',
      'Add all spice powders and fry until oil separates',
      'Add prawns and cook on high heat for 5-7 minutes',
      'Fry until prawns are cooked and coated with masala',
      'Serve hot with rice or as starter',
    ],
    instructionsTe: [
      'రొయ్యలు శుద్ధం చేసి, పసుపు, ఉప్పుతో మ్యారినేట్ చేయండి',
      'నూనె వేడి చేసి, ఉల్లిపాయలు బంగారు రంగు వచ్చేవరకు వేయించండి',
      'అల్లం-వెల్లుల్లి ముద్ద, కరివేపాకు వేసి 2 నిమిషాలు వేయించండి',
      'అన్ని మసాలా పొడులు వేసి నూనె వేరుకావాలి',
      'రొయ్యలు వేసి ఎక్కువ మంటపై 5-7 నిమిషాలు ఉడికించండి',
      'రొయ్యలు ఉడికి మసాలా పట్టేవరకు వేయించండి',
      'అన్నంలో లేదా స్టార్టర్‌గా వేడివేడిగా సర్వ్ చేయండి',
    ],
    cookTimeMinutes: 25,
    servings: 3,
    category: 'Lunch',
    region: 'Andhra',
    isVegetarian: false,
    rating: 4.8,
    calories: 220,
    protein: 25,
    carbs: 8,
    fat: 10,
    difficulty: 'Medium',
    tags: ['prawns', 'seafood', 'andhra', 'spicy'],
  ),

  const Recipe(
    id: '5',
    title: 'Gutti Vankaya Kura',
    titleTe: 'గుత్తి వంకాయ కూర',
    description: 'Stuffed baby eggplants in rich peanut sesame gravy',
    descriptionTe: 'వేరుశనగ, నువ్వులతో గుత్తి వంకాయల కూర',
    imageUrl:
        'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=800 ',
    ingredients: [
      '8-10 baby eggplants',
      '1/4 cup peanuts',
      '2 tbsp sesame seeds',
      '2 tbsp dry coconut',
      '2 dry red chilies',
      '1 tsp cumin seeds',
      '1 tsp mustard seeds',
      '1 tsp turmeric',
      '2 tsp red chili powder',
      'Tamarind pulp (lemon sized)',
      '3 tbsp oil',
      'Salt to taste',
    ],
    ingredientsTe: [
      '8-10 చిన్న వంకాయలు',
      '1/4 కప్పు వేరుశనగ',
      '2 టేబుల్ స్పూన్లు నువ్వులు',
      '2 టేబుల్ స్పూన్లు ఎండు కొబ్బరి',
      '2 ఎండు మిరపకాయలు',
      '1 టీ స్పూన్ జీలకర్ర',
      '1 టీ స్పూన్ ఆవాలు',
      '1 టీ స్పూన్ పసుపు',
      '2 టీ స్పూన్లు కారం',
      'నిమ్మకాయ సైజు చింతపండు పులుసు',
      '3 టేబుల్ స్పూన్లు నూనె',
      'రుచికి సరిపడా ఉప్పు',
    ],
    instructions: [
      'Roast peanuts, sesame, coconut, and red chilies, then grind to powder',
      'Make cross-cuts in eggplants keeping stems intact',
      'Stuff eggplants with ground powder mixed with salt and chili powder',
      'Heat oil, temper with mustard and cumin',
      'Arrange stuffed eggplants in pan, add turmeric and tamarind water',
      'Cover and cook on low for 15-20 minutes until tender',
      'Serve hot with rice',
    ],
    instructionsTe: [
      'వేరుశనగ, నువ్వులు, కొబ్బరి, మిరపకాయలు వేయించి పొడి చేయండి',
      'వంకాయలను కాడితో సహా క్రాస్‌కట్ చేయండి',
      'పొడి, ఉప్పు, కారం కలిపి వంకాయలను స్టఫ్ చేయండి',
      'నూనె వేడి చేసి, ఆవాలు, జీలకర్రతో తాలింపు',
      'స్టఫ్ చేసిన వంకాయలు పాన్‌లో పేర్చి, పసుపు, చింతపండు నీళ్లు పోయండి',
      'మూత పెట్టి 15-20 నిమిషాలు మెత్తబడేవరకు ఉడికించండి',
      'వేడివేడిగా అన్నంలో సర్వ్ చేయండి',
    ],
    cookTimeMinutes: 35,
    servings: 4,
    category: 'Lunch',
    region: 'Andhra',
    isVegetarian: true,
    rating: 4.9,
    calories: 195,
    protein: 6,
    carbs: 14,
    fat: 14,
    difficulty: 'Hard',
    tags: ['eggplant', 'vankaya', 'andhra', 'special'],
  ),

  // ==================== TELANGANA REGION ====================

  const Recipe(
    id: '6',
    title: 'Hyderabadi Chicken Biryani',
    titleTe: 'హైదరాబాదీ చికెన్ బిర్యానీ',
    description:
        'World-famous aromatic rice dish with layered chicken and spices',
    descriptionTe: 'ప్రపంచ ప్రసిద్ధ సువాసన బిర్యానీ',
    imageUrl:
        'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=800 ',
    ingredients: [
      '500g basmati rice',
      '500g chicken',
      '2 cups fried onions',
      '1 cup yogurt',
      '2 tbsp ginger-garlic paste',
      '4 green chilies, slit',
      '1/2 cup mint leaves',
      '1/2 cup coriander leaves',
      '2 tbsp biryani masala',
      '1 tsp saffron in warm milk',
      '4 tbsp ghee',
      'Salt to taste',
      'Whole spices (cardamom, cloves, cinnamon, bay leaf)',
    ],
    ingredientsTe: [
      '500 గ్రా బాస్మతి బియ్యం',
      '500 గ్రా చికెన్',
      '2 కప్పులు వేయించిన ఉల్లిపాయలు',
      '1 కప్పు పెరుగు',
      '2 టేబుల్ స్పూన్లు అల్లం-వెల్లుల్లి ముద్ద',
      '4 పచ్చి మిరపకాయలు, సన్నగా కోసినవి',
      '1/2 కప్పు పుదీనా ఆకులు',
      '1/2 కప్పు కొత్తిమీర',
      '2 టేబుల్ స్పూన్లు బిర్యానీ మసాలా',
      '1 టీ స్పూన్ కుంకుమపువ్వు వేడి పాలలో',
      '4 టేబుల్ స్పూన్లు నెయ్యి',
      'రుచికి సరిపడా ఉప్పు',
      'అఖండ మసాలాలు',
    ],
    instructions: [
      'Marinate chicken with yogurt, ginger-garlic, biryani masala for 2 hours',
      'Parboil rice with whole spices and salt',
      'Layer marinated chicken at bottom of heavy pot',
      'Add half fried onions, mint, coriander on chicken',
      'Layer parboiled rice on top',
      'Top with remaining onions, saffron milk, and ghee',
      'Seal pot with dough and cook on dum for 45 minutes',
      'Serve hot with raita',
    ],
    instructionsTe: [
      'పెరుగు, అల్లం-వెల్లుల్లి, బిర్యానీ మసాలాతో చికెన్ 2 గంటలు మ్యారినేట్ చేయండి',
      'అఖండ మసాలాలు, ఉప్పుతో బియ్యం సగం ఉడికించండి',
      'బరువైన పాత్రలో మ్యారినేట్ చికెన్ పేర్చండి',
      'అర ఉల్లిపాయలు, పుదీనా, కొత్తిమీర పైన వేయండి',
      'సగం ఉడికిన బియ్యం పేర్చండి',
      'మిగతా ఉల్లిపాయలు, కుంకుమపువ్వు పాలు, నెయ్యి పైన వేయండి',
      'పిండితో మూత పెట్టి 45 నిమిషాలు దమ్ చేయండి',
      'రైతాతో వేడివేడిగా సర్వ్ చేయండి',
    ],
    cookTimeMinutes: 90,
    servings: 6,
    category: 'Lunch',
    region: 'Telangana',
    isVegetarian: false,
    rating: 5.0,
    calories: 485,
    protein: 28,
    carbs: 58,
    fat: 16,
    difficulty: 'Hard',
    tags: ['biryani', 'hyderabadi', 'special', 'rice'],
  ),

  const Recipe(
    id: '7',
    title: 'Hyderabadi Haleem',
    titleTe: 'హైదరాబాదీ హలీం',
    description: 'Slow-cooked wheat and meat porridge, Ramadan specialty',
    descriptionTe: 'గోధుమ, మాంసంతో నెమ్మదిగా ఉడికించిన హలీం',
    imageUrl:
        'https://images.unsplash.com/photo-1631292784640-2b24a095d7f5?w=800 ',
    ingredients: [
      '500g mutton with bones',
      '1 cup broken wheat (dalia)',
      '1/2 cup lentils (masoor dal)',
      '2 onions, fried crispy',
      '2 tbsp ginger-garlic paste',
      '4 green chilies',
      '1/2 cup mint leaves',
      '2 tbsp ghee',
      '1 tbsp haleem masala',
      'Lemon wedges',
      'Salt to taste',
    ],
    ingredientsTe: [
      '500 గ్రా ఎముకలతో మటన్',
      '1 కప్పు గోధుమ రవ్వ',
      '1/2 కప్పు మసూర్ పప్పు',
      '2 ఉల్లిపాయలు, కరకరలాడేవరకు వేయించినవి',
      '2 టేబుల్ స్పూన్లు అల్లం-వెల్లుల్లి ముద్ద',
      '4 పచ్చి మిరపకాయలు',
      '1/2 కప్పు పుదీనా ఆకులు',
      '2 టేబుల్ స్పూన్లు నెయ్యి',
      '1 టేబుల్ స్పూన్ హలీం మసాలా',
      'నిమ్మకాయ ముక్కలు',
      'రుచికి సరిపడా ఉప్పు',
    ],
    instructions: [
      'Soak wheat and lentils overnight',
      'Pressure cook mutton with ginger-garlic until tender',
      'Cook soaked wheat and lentils until mushy',
      'Blend cooked wheat and mutton together to paste',
      'Heat ghee, add green chilies and haleem masala',
      'Mix everything together and cook for 30 more minutes',
      'Serve topped with fried onions, mint, lemon, and ghee',
    ],
    instructionsTe: [
      'గోధుమ రవ్వ, పప్పు రాత్రంతా నానబెట్టండి',
      'అల్లం-వెల్లుల్లితో మటన్ ప్రెజర్ కుక్ చేసి మెత్తబడేలా చేయండి',
      'నానబెట్టిన గోధుమ, పప్పు మెత్తబడేవరకు ఉడికించండి',
      'ఉడికిన గోధుమ, మటన్ కలిపి ముద్దగా గ్రైండ్ చేయండి',
      'నెయ్యి వేడి చేసి, పచ్చి మిరపకాయలు, హలీం మసాలా వేయండి',
      'అన్నీ కలిపి మరో 30 నిమిషాలు ఉడికించండి',
      'వేయించిన ఉల్లిపాయలు, పుదీనా, నిమ్మకాయ, నెయ్యితో సర్వ్ చేయండి',
    ],
    cookTimeMinutes: 180,
    servings: 6,
    category: 'Lunch',
    region: 'Telangana',
    isVegetarian: false,
    rating: 4.9,
    calories: 420,
    protein: 24,
    carbs: 48,
    fat: 16,
    difficulty: 'Hard',
    tags: ['haleem', 'hyderabadi', 'ramadan', 'special'],
  ),

  const Recipe(
    id: '8',
    title: 'Double Ka Meetha',
    titleTe: 'డబుల్ కా మీఠా',
    description: 'Hyderabadi bread pudding with rich nuts and saffron',
    descriptionTe: 'జీడిపప్పు, కుంకుమపువ్వుతో హైదరాబాదీ బ్రెడ్ పుడ్డింగ్',
    imageUrl:
        'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=800 ',
    ingredients: [
      '6 bread slices',
      '1 liter full cream milk',
      '1 cup sugar',
      '1/2 cup ghee',
      '1/4 cup almonds, sliced',
      '1/4 cashews',
      '2 tbsp raisins',
      '1 tsp cardamom powder',
      'Few saffron strands',
      '2 tbsp rose water',
    ],
    ingredientsTe: [
      '6 బ్రెడ్ ముక్కలు',
      '1 లీటర్ ఫుల్ క్రీమ్ పాలు',
      '1 కప్పు చక్కెర',
      '1/2 కప్పు నెయ్యి',
      '1/4 కప్పు జీడిపప్పు, సన్నగా తరిగినవి',
      '1/4 కప్పు కిస్మిస్',
      '2 టేబుల్ స్పూన్లు యాలకుల పొడి',
      'కొన్ని కుంకుమపువ్వు రేణువులు',
      '2 టేబుల్ స్పూన్లు గులాబీ నీరు',
    ],
    instructions: [
      'Cut bread into triangles and fry in ghee until golden',
      'Boil milk and reduce to half, add saffron and cardamom',
      'Add sugar and stir until dissolved',
      'Add fried bread pieces to milk and simmer',
      'Cook until bread absorbs milk and becomes soft',
      'Garnish with fried nuts, raisins, and rose water',
      'Serve warm or chilled',
    ],
    instructionsTe: [
      'బ్రెడ్‌ను త్రిభుజాలుగా కోసి నెయ్యిలో బంగారు రంగు వచ్చేవరకు వేయించండి',
      'పాలు మరిగించి సగానికి తగ్గించి, కుంకుమపువ్వు, యాలకుల పొడి వేయండి',
      'చక్కెర వేసి కరిగేవరకు కలపండి',
      'వేయించిన బ్రెడ్ పాలలో వేసి మెత్తగా ఉడికించండి',
      'బ్రెడ్ పాలు పీల్చుకుని మెత్తబడేవరకు ఉడికించండి',
      'వేయించిన జీడిపప్పు, కిస్మిస్, గులాబీ నీరు పైన వేయండి',
      'వెచ్చగా లేదా చల్లగా సర్వ్ చేయండి',
    ],
    cookTimeMinutes: 45,
    servings: 6,
    category: 'Desserts',
    region: 'Telangana',
    isVegetarian: true,
    rating: 4.8,
    calories: 380,
    protein: 8,
    carbs: 52,
    fat: 16,
    difficulty: 'Medium',
    tags: ['dessert', 'hyderabadi', 'sweet', 'bread'],
  ),

  const Recipe(
    id: '9',
    title: 'Sarva Pindi',
    titleTe: 'సర్వ పిండి',
    description: 'Telangana rice flour pancake with peanuts and spices',
    descriptionTe: 'వేరుశనగ, మసాలాలతో తెలంగాణ రైస్ ఫ్లోర్ పాన్‌కేక్',
    imageUrl:
        'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=800 ',
    ingredients: [
      '2 cups rice flour',
      '1/4 cup peanuts',
      '2 tbsp sesame seeds',
      '1 onion, finely chopped',
      '4 green chilies, chopped',
      '1 tsp ginger, grated',
      '1 tsp cumin seeds',
      '1 tsp chili powder',
      '3 tbsp oil',
      'Salt to taste',
      'Warm water as needed',
    ],
    ingredientsTe: [
      '2 కప్పులు బియ్యం పిండి',
      '1/4 కప్పు వేరుశనగ',
      '2 టేబుల్ స్పూన్లు నువ్వులు',
      '1 ఉల్లిపాయ, సన్నగా తరిగినది',
      '4 పచ్చి మిరపకాయలు, తరిగినవి',
      '1 టీ స్పూన్ అల్లం, తురిమినది',
      '1 టీ స్పూన్ జీలకర్ర',
      '1 టీ స్పూన్ కారం',
      '3 టేబుల్ స్పూన్లు నూనె',
      'రుచికి సరిపడా ఉప్పు',
      'అవసరమైంత వేడి నీరు',
    ],
    instructions: [
      'Mix rice flour with peanuts, sesame, onions, chilies, ginger, cumin',
      'Add chili powder, salt, and warm water to make thick dough',
      'Take a portion and flatten on greased pan directly',
      'Make holes and add oil in them',
      'Cover and cook on medium heat until crispy',
      'Flip and cook other side',
      'Serve hot with chutney',
    ],
    instructionsTe: [
      'బియ్యం పిండిలో వేరుశనగ, నువ్వులు, ఉల్లిపాయలు, మిరపకాయలు, అల్లం, జీలకర్ర కలపండి',
      'కారం, ఉప్పు, వేడి నీళ్లు పోసి గట్టి పిండి చేయండి',
      'ముద్ద తీసుకుని నూనె పూసిన పాన్‌పైనే పల్చగా పరచండి',
      'గుంతలు చేసి నూనె పోయండి',
      'మూత పెట్టి మధ్యస్థ మంటపై కరకరలాడేవరకు ఉడికించండి',
      'తిప్పి రెండవ వైపు ఉడికించండి',
      'పచ్చడితో వేడివేడిగా సర్వ్ చేయండి',
    ],
    cookTimeMinutes: 30,
    servings: 4,
    category: 'Breakfast',
    region: 'Telangana',
    isVegetarian: true,
    rating: 4.6,
    calories: 245,
    protein: 6,
    carbs: 38,
    fat: 8,
    difficulty: 'Medium',
    tags: ['sarva pindi', 'telangana', 'breakfast', 'rice'],
  ),

  const Recipe(
    id: '10',
    title: 'Telangana Kodi Kura',
    titleTe: 'తెలంగాణ కోడి కూర',
    description: 'Country chicken curry with traditional Telangana spices',
    descriptionTe: 'సాంప్రదాయ తెలంగాణ మసాలాలతో నాటు కోడి కూర',
    imageUrl:
        'https://images.unsplash.com/photo-1606491956689-05f4575a45d8?w=800 ',
    ingredients: [
      '1 kg country chicken',
      '3 onions, finely chopped',
      '2 tomatoes, pureed',
      '2 tbsp ginger-garlic paste',
      '1/2 cup coconut, dry roasted and ground',
      '2 tsp red chili powder',
      '1 tsp turmeric',
      '1 tbsp coriander powder',
      '1 tsp garam masala',
      '10 curry leaves',
      '4 tbsp oil',
      'Salt to taste',
    ],
    ingredientsTe: [
      '1 కిలో నాటు కోడి',
      '3 ఉల్లిపాయలు, సన్నగా తరిగినవి',
      '2 టమాటోలు, ప్యూరీ చేసినవి',
      '2 టేబుల్ స్పూన్లు అల్లం-వెల్లుల్లి ముద్ద',
      '1/2 కప్పు కొబ్బరి, ఎండు వేయించి పొడి చేసినది',
      '2 టీ స్పూన్లు కారం',
      '1 టీ స్పూన్ పసుపు',
      '1 టేబుల్ స్పూన్ ధనియాల పొడి',
      '1 టీ స్పూన్ గరం మసాలా',
      '10 కరివేపాకు రెబ్బలు',
      '4 టేబుల్ స్పూన్లు నూనె',
      'రుచికి సరిపడా ఉప్పు',
    ],
    instructions: [
      'Clean and cut country chicken into pieces',
      'Marinate with turmeric, salt, and chili powder for 1 hour',
      'Heat oil and sauté onions until deep brown',
      'Add ginger-garlic paste and curry leaves, fry for 3 minutes',
      'Add tomato puree and cook until oil separates',
      'Add marinated chicken and cook for 15 minutes',
      'Add coconut paste and cook until chicken is tender',
      'Finish with garam masala and serve',
    ],
    instructionsTe: [
      'నాటు కోడిని శుద్ధం చేసి ముక్కలు చేయండి',
      'పసుపు, ఉప్పు, కారంతో 1 గంట మ్యారినేట్ చేయండి',
      'నూనె వేడి చేసి, ఉల్లిపాయలు ముదురు బంగారు రంగు వచ్చేవరకు వేయించండి',
      'అల్లం-వెల్లుల్లి ముద్ద, కరివేపాకు వేసి 3 నిమిషాలు వేయించండి',
      'టమాటో ప్యూరీ వేసి నూనె వేరుకావాలి',
      'మ్యారినేట్ చికెన్ వేసి 15 నిమిషాలు ఉడికించండి',
      'కొబ్బరి ముద్ద వేసి చికెన్ మెత్తబడేవరకు ఉడికించండి',
      'గరం మసాలా వేసి సర్వ్ చేయండి',
    ],
    cookTimeMinutes: 60,
    servings: 5,
    category: 'Lunch',
    region: 'Telangana',
    isVegetarian: false,
    rating: 4.7,
    calories: 340,
    protein: 32,
    carbs: 12,
    fat: 18,
    difficulty: 'Medium',
    tags: ['chicken', 'country chicken', 'telangana', 'spicy'],
  ),

  // ==================== RAYALASEEMA REGION ====================

  const Recipe(
    id: '11',
    title: 'Rayalaseema Chicken Fry',
    titleTe: 'రాయలసీమ కోడి వేపుడు',
    description: 'Extra spicy dry chicken fry with special Rayalaseema masala',
    descriptionTe: 'ప్రత్యేక రాయలసీమ మసాలాతో ఎక్స్ట్రా స్పైసీ డ్రై చికెన్',
    imageUrl:
        'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=800 ',
    ingredients: [
      '500g chicken',
      '3 tbsp Rayalaseema chili powder',
      '1 tbsp ginger-garlic paste',
      '1 tsp turmeric',
      '1 tsp cumin powder',
      '1 tsp coriander powder',
      '1/2 tsp black pepper',
      '1/2 tsp garam masala',
      '4 tbsp oil',
      'Curry leaves',
      'Lemon juice',
      'Salt to taste',
    ],
    ingredientsTe: [
      '500 గ్రా చికెన్',
      '3 టేబుల్ స్పూన్లు రాయలసీమ కారం',
      '1 టేబుల్ స్పూన్ అల్లం-వెల్లుల్లి ముద్ద',
      '1 టీ స్పూన్ పసుపు',
      '1 టీ స్పూన్ జీలకర్ర పొడి',
      '1 టీ స్పూన్ ధనియాల పొడి',
      '1/2 టీ స్పూన్ మిరియాల పొడి',
      '1/2 టీ స్పూన్ గరం మసాలా',
      '4 టేబుల్ స్పూన్లు నూనె',
      'కరివేపాకు',
      'నిమ్మరసం',
      'రుచికి సరిపడా ఉప్పు',
    ],
    instructions: [
      'Marinate chicken with all spices and ginger-garlic for 2 hours',
      'Heat oil in a wide pan',
      'Add marinated chicken and spread evenly',
      'Cook on high heat for 5 minutes without stirring',
      'Stir and cook until chicken is dry and crispy',
      'Add curry leaves and toss',
      'Finish with lemon juice and serve hot',
    ],
    instructionsTe: [
      'అన్ని మసాలాలు, అల్లం-వెల్లుల్లితో చికెన్ 2 గంటలు మ్యారినేట్ చేయండి',
      'వెడల్పాటి పాన్‌లో నూనె వేడి చేయండి',
      'మ్యారినేట్ చికెన్ వేసి సమానంగా పరచండి',
      'ఎక్కువ మంటపై 5 నిమిషాలు కలపకుండా ఉడికించండి',
      'కలిపి చికెన్ ఎండి కరకరలాడేవరకు వేయించండి',
      'కరివేపాకు వేసి కలపండి',
      'నిమ్మరసంతో ముగించి వేడివేడిగా సర్వ్ చేయండి',
    ],
    cookTimeMinutes: 35,
    servings: 3,
    category: 'Lunch',
    region: 'Rayalaseema',
    isVegetarian: false,
    rating: 4.9,
    calories: 295,
    protein: 28,
    carbs: 6,
    fat: 18,
    difficulty: 'Medium',
    tags: ['chicken', 'rayalaseema', 'spicy', 'fry'],
  ),

  const Recipe(
    id: '12',
    title: 'Ragi Sangati',
    titleTe: 'రాగి సంగటి',
    description:
        'Finger millet balls, staple food of Rayalaseema with spicy curry',
    descriptionTe: 'రాయలసీమ ప్రధాన ఆహారం రాగి సంగటి',
    imageUrl:
        'https://images.unsplash.com/photo-1606491956689-05f4575a45d8?w=800 ',
    ingredients: [
      '2 cups ragi flour',
      '1 cup rice',
      '4 cups water',
      '1 tsp salt',
      '1 tbsp ghee',
      'Spicy chicken or mutton curry for serving',
    ],
    ingredientsTe: [
      '2 కప్పులు రాగి పిండి',
      '1 కప్పు బియ్యం',
      '4 కప్పులు నీరు',
      '1 టీ స్పూన్ ఉప్పు',
      '1 టేబుల్ స్పూన్ నెయ్యి',
      'సర్వ్ చేయడానికి కారమైన చికెన్ లేదా మటన్ కూర',
    ],
    instructions: [
      'Cook rice with water and salt until mushy',
      'Add ragi flour to cooked rice while stirring continuously',
      'Cook on low heat for 10-15 minutes, stirring constantly',
      'Add ghee and mix well',
      'Wet hands and shape into round balls while hot',
      'Serve with spicy curry',
    ],
    instructionsTe: [
      'బియ్యం నీళ్లు, ఉప్పుతో మెత్తగా ఉడికించండి',
      'ఉడికిన బియ్యంలో రాగి పిండి వేసి నిరంతరం కలుపుతూ ఉండండి',
      'తక్కువ మంటపై 10-15 నిమిషాలు నిరంతరం కలుపుతూ ఉడికించండి',
      'నెయ్యి వేసి బాగా కలపండి',
      'చేతులు తడిపి వేడిగా ఉండగానే గుండ్రంగా ఉండేలా చేయండి',
      'కారమైన కూరతో సర్వ్ చేయండి',
    ],
    cookTimeMinutes: 40,
    servings: 4,
    category: 'Lunch',
    region: 'Rayalaseema',
    isVegetarian: true,
    rating: 4.5,
    calories: 220,
    protein: 6,
    carbs: 42,
    fat: 4,
    difficulty: 'Medium',
    tags: ['ragi', 'sangati', 'rayalaseema', 'healthy'],
  ),

  const Recipe(
    id: '13',
    title: 'Natu Kodi Pulusu',
    titleTe: 'నాటు కోడి పులుసు',
    description: 'Tangy country chicken curry with tamarind, Rayalaseema style',
    descriptionTe: 'చింతపండుతో పుల్లటి నాటు కోడి పులుసు',
    imageUrl:
        'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=800 ',
    ingredients: [
      '1 kg country chicken',
      '3 onions, sliced',
      '2 tomatoes, chopped',
      'Lemon sized tamarind',
      '2 tbsp ginger-garlic paste',
      '3 tbsp chili powder',
      '1 tsp turmeric',
      '1 tbsp coriander powder',
      '1 tsp fenugreek seeds',
      '1 tsp mustard seeds',
      'Curry leaves',
      '4 tbsp oil',
      'Salt to taste',
    ],
    ingredientsTe: [
      '1 కిలో నాటు కోడి',
      '3 ఉల్లిపాయలు, తరిగినవి',
      '2 టమాటోలు, తరిగినవి',
      'నిమ్మకాయ సైజు చింతపండు',
      '2 టేబుల్ స్పూన్లు అల్లం-వెల్లుల్లి ముద్ద',
      '3 టేబుల్ స్పూన్లు కారం',
      '1 టీ స్పూన్ పసుపు',
      '1 టేబుల్ స్పూన్ ధనియాల పొడి',
      '1 టీ స్పూన్ మెంతులు',
      '1 టీ స్పూన్ ఆవాలు',
      'కరివేపాకు',
      '4 టేబుల్ స్పూన్లు నూనె',
      'రుచికి సరిపడా ఉప్పు',
    ],
    instructions: [
      'Soak tamarind in warm water and extract pulp',
      'Marinate chicken with turmeric, salt, and chili powder',
      'Heat oil, temper with mustard, fenugreek, and curry leaves',
      'Sauté onions until golden, add ginger-garlic paste',
      'Add tomatoes and cook until soft',
      'Add marinated chicken and cook for 15 minutes',
      'Add tamarind pulp and simmer until chicken is tender',
      'Serve hot with ragi sangati',
    ],
    instructionsTe: [
      'చింతపండును వేడి నీళ్లలో నానబెట్టి పులుసు తీయండి',
      'కోడిని పసుపు, ఉప్పు, కారంతో మ్యారినేట్ చేయండి',
      'నూనె వేడి చేసి, ఆవాలు, మెంతులు, కరివేపాకుతో తాలింపు',
      'ఉల్లిపాయలు బంగారు రంగు వచ్చేవరకు వేయించి, అల్లం-వెల్లుల్లి ముద్ద వేయండి',
      'టమాటోలు వేసి మెత్తబడేవరకు ఉడికించండి',
      'మ్యారినేట్ చికెన్ వేసి 15 నిమిషాలు ఉడికించండి',
      'చింతపండు పులుసు వేసి కోడి మెత్తబడేవరకు ఉడికించండి',
      'రాగి సంగటితో వేడివేడిగా సర్వ్ చేయండి',
    ],
    cookTimeMinutes: 55,
    servings: 5,
    category: 'Lunch',
    region: 'Rayalaseema',
    isVegetarian: false,
    rating: 4.8,
    calories: 310,
    protein: 30,
    carbs: 15,
    fat: 14,
    difficulty: 'Medium',
    tags: ['chicken', 'pulusu', 'tamarind', 'rayalaseema'],
  ),

  const Recipe(
    id: '14',
    title: 'Soft Idli',
    titleTe: 'మెత్తని ఇడ్లీ',
    description: 'Steamed rice cakes, South Indian breakfast staple',
    descriptionTe: 'ఆవిరి మీద ఉడికించిన ఇడ్లీలు',
    imageUrl:
        'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=800 ',
    ingredients: [
      '2 cups idli rice',
      '1 cup urad dal',
      '1/2 tsp fenugreek seeds',
      'Salt to taste',
      'Oil for greasing',
    ],
    ingredientsTe: [
      '2 కప్పులు ఇడ్లీ బియ్యం',
      '1 కప్పు మినపపప్పు',
      '1/2 టీ స్పూన్ మెంతులు',
      'రుచికి సరిపడా ఉప్పు',
      'పూసడానికి నూనె',
    ],
    instructions: [
      'Soak rice and dal separately for 6 hours',
      'Grind dal to smooth fluffy batter',
      'Grind rice to slightly coarse batter',
      'Mix both batters, add salt and ferment overnight',
      'Grease idli molds and pour batter',
      'Steam for 10-12 minutes until cooked',
      'Serve hot with sambar and chutney',
    ],
    instructionsTe: [
      'బియ్యం, పప్పు వేర్వేరుగా 6 గంటలు నానబెట్టండి',
      'పప్పును మెత్తగా పొంగే పిండిలా గ్రైండ్ చేయండి',
      'బియ్యాన్ని కచ్చాగా గ్రైండ్ చేయండి',
      'రెండు పిండులు కలిపి, ఉప్పు వేసి రాత్రంతా పులియబెట్టండి',
      'ఇడ్లీ పళ్ళెలకు నూనె పూసి పిండి పోయండి',
      '10-12 నిమిషాలు ఆవిరి మీద ఉడికించండి',
      'సాంబార్, పచ్చడితో వేడివేడిగా సర్వ్ చేయండి',
    ],
    cookTimeMinutes: 30,
    servings: 4,
    category: 'Breakfast',
    region: 'Andhra',
    isVegetarian: true,
    rating: 4.7,
    calories: 120,
    protein: 4,
    carbs: 24,
    fat: 0.5,
    difficulty: 'Medium',
    tags: ['idli', 'breakfast', 'steamed', 'healthy'],
  ),

  const Recipe(
    id: '15',
    title: 'Crispy Dosa',
    titleTe: 'కరకరలాడే దోశ',
    description: 'Thin crispy rice crepes, perfect breakfast item',
    descriptionTe: 'పల్చటి కరకరలాడే దోశలు',
    imageUrl:
        'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=800 ',
    ingredients: [
      '2 cups dosa rice',
      '1/2 cup urad dal',
      '1/4 cup poha (flattened rice)',
      '1/2 tsp fenugreek seeds',
      'Salt to taste',
      'Oil for cooking',
    ],
    ingredientsTe: [
      '2 కప్పులు దోశ బియ్యం',
      '1/2 కప్పు మినపపప్పు',
      '1/4 కప్పు అటుకులు',
      '1/2 టీ స్పూన్ మెంతులు',
      'రుచికి సరిపడా ఉప్పు',
      'వేయించడానికి నూనె',
    ],
    instructions: [
      'Soak rice, dal, and poha for 6 hours',
      'Grind to smooth batter and ferment overnight',
      'Heat dosa pan and sprinkle water to check temperature',
      'Pour ladleful of batter and spread in circular motion',
      'Drizzle oil around edges',
      'Cook until golden and crispy',
      'Fold and serve hot with chutney',
    ],
    instructionsTe: [
      'బియ్యం, పప్పు, అటుకులు 6 గంటలు నానబెట్టండి',
      'మెత్తగా గ్రైండ్ చేసి రాత్రంతా పులియబెట్టండి',
      'దోశ పాన్ వేడి చేసి ఉష్ణోగ్రత కోసం నీళ్లు చల్లండి',
      'పిండి పోసి వృత్తాకారంగా పల్చగా పరచండి',
      'అంచుల చుట్టూ నూనె పోయండి',
      'బంగారు రంగు, కరకరలాడేవరకు ఉడికించండి',
      'మడిచి పచ్చడితో వేడివేడిగా సర్వ్ చేయండి',
    ],
    cookTimeMinutes: 25,
    servings: 4,
    category: 'Breakfast',
    region: 'Andhra',
    isVegetarian: true,
    rating: 4.8,
    calories: 140,
    protein: 3,
    carbs: 28,
    fat: 1,
    difficulty: 'Medium',
    tags: ['dosa', 'breakfast', 'crispy', 'rice'],
  ),

  const Recipe(
    id: '16',
    title: 'Rava Upma',
    titleTe: 'రవ్వ ఉప్మా',
    description: 'Savory semolina porridge with vegetables',
    descriptionTe: 'కూరగాయలతో రుచికరమైన రవ్వ ఉప్మా',
    imageUrl:
        'https://images.unsplash.com/photo-1606491956689-05f4575a45d8?w=800 ',
    ingredients: [
      '1 cup semolina (rava)',
      '2 cups water',
      '1 onion, chopped',
      '1 tomato, chopped',
      '1/2 cup mixed vegetables',
      '2 green chilies',
      '1 tsp ginger, chopped',
      '1 tsp mustard seeds',
      '1 tsp urad dal',
      '1 tsp chana dal',
      '8 curry leaves',
      '2 tbsp oil',
      'Salt to taste',
    ],
    ingredientsTe: [
      '1 కప్పు రవ్వ',
      '2 కప్పులు నీరు',
      '1 ఉల్లిపాయ, తరిగినది',
      '1 టమాటో, తరిగినది',
      '1/2 కప్పు మిశ్రమ కూరగాయలు',
      '2 పచ్చి మిరపకాయలు',
      '1 టీ స్పూన్ అల్లం, తరిగినది',
      '1 టీ స్పూన్ ఆవాలు',
      '1 టీ స్పూన్ మినపపప్పు',
      '1 టీ స్పూన్ శనగపప్పు',
      '8 కరివేపాకు రెబ్బలు',
      '2 టేబుల్ స్పూన్లు నూనె',
      'రుచికి సరిపడా ఉప్పు',
    ],
    instructions: [
      'Dry roast semolina until fragrant, set aside',
      'Heat oil, temper with mustard, dals, and curry leaves',
      'Sauté onions, green chilies, ginger until fragrant',
      'Add tomatoes and vegetables, cook for 3 minutes',
      'Add water and salt, bring to boil',
      'Slowly add roasted semolina while stirring',
      'Cook on low for 5 minutes until thickened',
      'Serve hot',
    ],
    instructionsTe: [
      'రవ్వ వాసన వచ్చేవరకు ఎండు వేయించి పక్కన పెట్టండి',
      'నూనె వేడి చేసి, ఆవాలు, పప్పులు, కరివేపాకుతో తాలింపు',
      'ఉల్లిపాయలు, పచ్చి మిరపకాయలు, అల్లం వేయించండి',
      'టమాటో, కూరగాయలు వేసి 3 నిమిషాలు ఉడికించండి',
      'నీళ్లు, ఉప్పు వేసి మరిగించండి',
      'వేడి నీళ్లలో ఎండు వేయించిన రవ్వ నెమ్మదిగా కలుపుతూ పోయండి',
      '5 నిమిషాలు తక్కువ మంటపై గట్టిపడేవరకు ఉడికించండి',
      'వేడివేడిగా సర్వ్ చేయండి',
    ],
    cookTimeMinutes: 20,
    servings: 3,
    category: 'Breakfast',
    region: 'Andhra',
    isVegetarian: true,
    rating: 4.5,
    calories: 180,
    protein: 5,
    carbs: 32,
    fat: 4,
    difficulty: 'Easy',
    tags: ['upma', 'breakfast', 'semolina', 'quick'],
  ),

  const Recipe(
    id: '17',
    title: 'Mirchi Bajji',
    titleTe: 'మిర్చి బజ్జీ',
    description: 'Stuffed green chili fritters, famous Andhra snack',
    descriptionTe: 'ప్రసిద్ధ ఆంధ్ర స్నాక్ మిర్చి బజ్జీ',
    imageUrl:
        'https://images.unsplash.com/photo-1606491956689-05f4575a45d8?w=800 ',
    ingredients: [
      '10-12 thick green chilies (bajji mirchi)',
      '1 cup gram flour (besan)',
      '2 tbsp rice flour',
      '1 tsp cumin seeds',
      '1 tsp carom seeds (ajwain)',
      '1/2 tsp turmeric',
      '1 tsp chili powder',
      'Pinch of baking soda',
      'Salt to taste',
      'Oil for deep frying',
      'Stuffing: 2 tbsp tamarind paste mixed with 1 tsp cumin powder',
    ],
    ingredientsTe: [
      '10-12 మందంగా ఉన్న పచ్చి మిరపకాయలు',
      '1 కప్పు శనగపిండి',
      '2 టేబుల్ స్పూన్లు బియ్యం పిండి',
      '1 టీ స్పూన్ జీలకర్ర',
      '1 టీ స్పూన్ వాము',
      '1/2 టీ స్పూన్ పసుపు',
      '1 టీ స్పూన్ కారం',
      'చిటికెడు సోడా',
      'రుచికి సరిపడా ఉప్పు',
      'లోతుగా వేయించడానికి నూనె',
      'స్టఫింగ్: 2 టేబుల్ స్పూన్లు చింతపండు ముద్ద, 1 టీ స్పూన్ జీలకర్ర పొడి',
    ],
    instructions: [
      'Wash and dry chilies, make a slit keeping stem intact',
      'Remove seeds carefully and stuff with tamarind mixture',
      'Mix gram flour, rice flour, spices, and water to thick batter',
      'Heat oil to medium-high temperature',
      'Dip stuffed chilies in batter and coat evenly',
      'Deep fry until golden and crispy',
      'Serve hot with onion slices and green chili chutney',
    ],
    instructionsTe: [
      'మిరపకాయలు కడిగి ఆరవేయండి, కాడితో సహా సన్నగా కోయండి',
      'గింజలు జాగ్రత్తగా తీసి చింతపండు మిశ్రమంతో స్టఫ్ చేయండి',
      'శనగపిండి, బియ్యం పిండి, మసాలాలు, నీళ్లతో గట్టి పిండి చేయండి',
      'నూనె మధ్యస్థ-ఎక్కువ ఉష్ణోగ్రతకు వేడి చేయండి',
      'స్టఫ్ చేసిన మిరపకాయలను పిండిలో ముంచి సమానంగా పూయండి',
      'బంగారు రంగు, కరకరలాడేవరకు లోతుగా వేయించండి',
      'ఉల్లిపాయ ముక్కలు, పచ్చి మిరపకాయ పచ్చడితో వేడివేడిగా సర్వ్ చేయండి',
    ],
    cookTimeMinutes: 30,
    servings: 4,
    category: 'Snacks',
    region: 'Andhra',
    isVegetarian: true,
    rating: 4.8,
    calories: 220,
    protein: 6,
    carbs: 28,
    fat: 10,
    difficulty: 'Medium',
    tags: ['bajji', 'snack', 'spicy', 'street food'],
  ),

  const Recipe(
    id: '18',
    title: 'Punugulu',
    titleTe: 'పునుగులు',
    description: 'Crispy rice and urad dal fritters, popular evening snack',
    descriptionTe: 'బియ్యం, మినపప్పతో కరకరలాడే పునుగులు',
    imageUrl:
        'https://images.unsplash.com/photo-1606491956689-05f4575a45d8?w=800 ',
    ingredients: [
      '2 cups idli batter (slightly sour)',
      '1 onion, finely chopped',
      '2 green chilies, chopped',
      '1 tsp ginger, grated',
      '2 tbsp coriander leaves, chopped',
      '1 tsp cumin seeds',
      'Salt to taste',
      'Oil for deep frying',
    ],
    ingredientsTe: [
      '2 కప్పులు ఇడ్లీ పిండి (కొద్దిగా పుల్లగా)',
      '1 ఉల్లిపాయ, సన్నగా తరిగినది',
      '2 పచ్చి మిరపకాయలు, తరిగినవి',
      '1 టీ స్పూన్ అల్లం, తురిమినది',
      '2 టేబుల్ స్పూన్లు కొత్తిమీర, తరిగినది',
      '1 టీ స్పూన్ జీలకర్ర',
      'రుచికి సరిపడా ఉప్పు',
      'లోతుగా వేయించడానికి నూనె',
    ],
    instructions: [
      'Take slightly sour idli batter in a bowl',
      'Add onions, chilies, ginger, coriander, cumin, and salt',
      'Mix well to combine all ingredients',
      'Heat oil to medium-high temperature',
      'Wet hands, take small portions and drop in hot oil',
      'Fry until golden brown and crispy',
      'Drain on paper towels and serve hot with coconut chutney',
    ],
    instructionsTe: [
      'బౌల్‌లో కొద్దిగా పుల్లగా ఉన్న ఇడ్లీ పిండి తీసుకోండి',
      'ఉల్లిపాయలు, మిరపకాయలు, అల్లం, కొత్తిమీర, జీలకర్ర, ఉప్పు కలపండి',
      'అన్నీ బాగా కలిపేవరకు కలపండి',
      'నూనె మధ్యస్థ-ఎక్కువ ఉష్ణోగ్రతకు వేడి చేయండి',
      'చేతులు తడిపి, చిన్న ముద్దలు తీసి వేడి నూనెలో వదలండి',
      'బంగారు రంగు, కరకరలాడేవరకు వేయించండి',
      'పేపర్ టవల్సపై ఆరవేసి, కొబ్బరి పచ్చడితో వేడివేడిగా సర్వ్ చేయండి',
    ],
    cookTimeMinutes: 25,
    servings: 4,
    category: 'Snacks',
    region: 'Andhra',
    isVegetarian: true,
    rating: 4.6,
    calories: 180,
    protein: 5,
    carbs: 24,
    fat: 8,
    difficulty: 'Easy',
    tags: ['punugulu', 'snack', 'fritters', 'evening'],
  ),

  const Recipe(
    id: '19',
    title: 'Ariselu',
    titleTe: 'అరిసెలు',
    description:
        'Traditional sweet made with rice flour and jaggery for festivals',
    descriptionTe: 'పండుగలకు ప్రత్యేకమైన బియ్యం పిండి, బెల్లంతో చేసిన మిఠాయి',
    imageUrl:
        'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=800 ',
    ingredients: [
      '2 cups rice flour',
      '1 cup jaggery',
      '1/2 cup water',
      '2 tbsp sesame seeds',
      '1/2 tsp cardamom powder',
      'Oil for deep frying',
      'Ghee for greasing',
    ],
    ingredientsTe: [
      '2 కప్పులు బియ్యం పిండి',
      '1 కప్పు బెల్లం',
      '1/2 కప్పు నీరు',
      '2 టేబుల్ స్పూన్లు నువ్వులు',
      '1/2 టీ స్పూన్ యాలకుల పొడి',
      'లోతుగా వేయించడానికి నూనె',
      'పూసడానికి నెయ్యి',
    ],
    instructions: [
      'Soak rice for 6 hours, drain and dry grind to fine powder',
      'Melt jaggery with water, strain to remove impurities',
      'Make thick syrup (soft ball consistency)',
      'Add sesame seeds and cardamom to syrup',
      'Gradually add rice flour to make soft dough',
      'Grease hands, make small discs',
      'Deep fry on low heat until golden',
      'Drain and cool before storing',
    ],
    instructionsTe: [
      'బియ్యం 6 గంటలు నానబెట్టి, నీరు పోసి ఎండు గ్రైండ్ చేయండి',
      'బెల్లాన్ని నీళ్లతో కరిగించి, మలినాలు తీయండి',
      'గట్టి పాకం (సాఫ్ట్ బాల్) చేయండి',
      'నువ్వులు, యాలకుల పొడి పాకంలో కలపండి',
      'నెమ్మదిగా బియ్యం పిండి కలిపి మెత్తని పిండి చేయండి',
      'చేతులకు నెయ్యి పూసి, చిన్న గుండ్రని డిస్కులు చేయండి',
      'తక్కువ మంటపై బంగారు రంగు వచ్చేవరకు లోతుగా వేయించండి',
      'ఆరవేసి నిల్వ చేయండి',
    ],
    cookTimeMinutes: 60,
    servings: 15,
    category: 'Desserts',
    region: 'Andhra',
    isVegetarian: true,
    rating: 4.9,
    calories: 120,
    protein: 1,
    carbs: 22,
    fat: 4,
    difficulty: 'Hard',
    tags: ['ariselu', 'sweet', 'festival', 'traditional'],
  ),

  const Recipe(
    id: '20',
    title: 'Pootharekulu',
    titleTe: 'పూతరేకులు',
    description:
        'Paper-thin sweet rolls with sugar and dry fruits from Atreyapuram',
    descriptionTe: 'అత్రేయపురం ప్రత్యేక పూతరేకులు',
    imageUrl:
        'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=800 ',
    ingredients: [
      'Rice batter (for thin sheets)',
      '1 cup powdered sugar',
      '1/2 cup ghee',
      '1/4 cup cashews, chopped',
      '1/4 cup almonds, chopped',
      '1/2 tsp cardamom powder',
      'Parchment paper for rolling',
    ],
    ingredientsTe: [
      'రైస్ బ్యాటర్ (పల్చటి షీట్ల కోసం)',
      '1 కప్పు పొడి చక్కెర',
      '1/2 కప్పు నెయ్యి',
      '1/4 కప్పు జీడిపప్పు, తరిగినది',
      '1/4 కప్పు బాదం, తరిగినది',
      '1/2 టీ స్పూన్ యాలకుల పొడి',
      'రోల్ చేయడానికి పార్చ్మెంట్ పేపర్',
    ],
    instructions: [
      'Make very thin rice sheets using traditional method or buy ready-made',
      'Mix powdered sugar with cardamom and chopped nuts',
      'Place one rice sheet on parchment paper',
      'Brush with melted ghee generously',
      'Sprinkle sugar-nut mixture evenly',
      'Roll tightly into cylinder',
      'Repeat layers for thicker rolls',
      'Wrap and store airtight',
    ],
    instructionsTe: [
      'సాంప్రదాయ పద్ధతిలో లేదా సిద్ధంగా కొన్న పల్చటి బియ్యం షీట్లు తీసుకోండి',
      'పొడి చక్కెరను యాలకులు, తరిగిన జీడిపప్పుతో కలపండి',
      'ఒక బియ్యం షీట్ పార్చ్మెంట్ పేపర్‌పై పెట్టండి',
      'కరిగిన నెయ్యి బాగా పూయండి',
      'చక్కెర-జీడిపప్పు మిశ్రమం సమానంగా చల్లండి',
      'గట్టిగా సిలిండర్‌లా రోల్ చేయండి',
      'మందంగా కావాలంటే మరిన్ని షీట్లు పేర్చండి',
      'చుట్టి గాలి రాకుండా నిల్వ చేయండి',
    ],
    cookTimeMinutes: 45,
    servings: 10,
    category: 'Desserts',
    region: 'Andhra',
    isVegetarian: true,
    rating: 4.8,
    calories: 150,
    protein: 2,
    carbs: 20,
    fat: 8,
    difficulty: 'Hard',
    tags: ['pootharekulu', 'sweet', 'atreyapuram', 'special'],
  ),

  const Recipe(
    id: '21',
    title: 'Masala Chaas',
    titleTe: 'మసాలా చాస్',
    description: 'Spiced buttermilk, perfect summer cooler',
    descriptionTe: 'వేసవికాలానికి బాగా సరిపోయే మసాలా మజ్జిగ',
    imageUrl:
        'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=800 ',
    ingredients: [
      '2 cups yogurt (slightly sour)',
      '3 cups cold water',
      '1 tsp cumin powder (roasted)',
      '1/2 tsp black salt',
      '1/4 tsp black pepper',
      '1 tsp ginger, grated',
      '2 green chilies, chopped',
      'Few curry leaves, chopped',
      'Fresh coriander',
      'Ice cubes',
    ],
    ingredientsTe: [
      '2 కప్పులు పెరుగు (కొద్దిగా పుల్లగా)',
      '3 కప్పులు చల్లని నీరు',
      '1 టీ స్పూన్ జీలకర్ర పొడి (వేయించినది)',
      '1/2 టీ స్పూన్ నల్ల ఉప్పు',
      '1/4 టీ స్పూన్ మిరియాల పొడి',
      '1 టీ స్పూన్ అల్లం, తురిమినది',
      '2 పచ్చి మిరపకాయలు, తరిగినవి',
      'కొన్ని కరివేపాకు రెబ్బలు, తరిగినవి',
      'కొత్తిమీర',
      'ఐస్ క్యూబ్స్',
    ],
    instructions: [
      'Whisk yogurt until smooth',
      'Add water and whisk to make thin buttermilk',
      'Add all spices, ginger, chilies, and curry leaves',
      'Mix well and chill for 30 minutes',
      'Serve in tall glasses with ice',
      'Garnish with fresh coriander',
    ],
    instructionsTe: [
      'పెరుగును మెత్తగా విప్పండి',
      'నీళ్లు పోసి పల్చటి మజ్జిగ చేయండి',
      'అన్ని మసాలాలు, అల్లం, మిరపకాయలు, కరివేపాకు కలపండి',
      'బాగా కలిపి 30 నిమిషాలు చల్లబరచండి',
      'ఎత్తైన గ్లాసులలో ఐస్‌తో సర్వ్ చేయండి',
      'కొత్తిమీరతో అలంకరించండి',
    ],
    cookTimeMinutes: 10,
    servings: 4,
    category: 'Beverages',
    region: 'Andhra',
    isVegetarian: true,
    rating: 4.6,
    calories: 60,
    protein: 3,
    carbs: 5,
    fat: 2,
    difficulty: 'Easy',
    tags: ['chaas', 'buttermilk', 'summer', 'drink'],
  ),

  const Recipe(
    id: '22',
    title: 'South Indian Filter Coffee',
    titleTe: 'సౌత్ ఇండియన్ ఫిల్టర్ కాఫీ',
    description: 'Strong aromatic coffee with frothy milk',
    descriptionTe: 'పొంగే పాలతో గట్టి సువాసన కాఫీ',
    imageUrl:
        'https://images.unsplash.com/photo-1497935586351-b67a49e012bf?w=800 ',
    ingredients: [
      '3 tbsp coffee powder (filter coffee grind)',
      '1 cup water',
      '2 cups milk',
      '2-3 tsp sugar (per cup)',
      'Traditional filter coffee maker',
    ],
    ingredientsTe: [
      '3 టేబుల్ స్పూన్లు కాఫీ పొడి (ఫిల్టర్ గ్రైండ్)',
      '1 కప్పు నీరు',
      '2 కప్పులు పాలు',
      '2-3 టీ స్పూన్లు చక్కెర (కప్పుకు)',
      'సాంప్రదాయ ఫిల్టర్ కాఫీ మేకర్',
    ],
    instructions: [
      'Add coffee powder to upper chamber of filter',
      'Press gently with perforated disc',
      'Pour hot water and cover',
      'Let decoction drip for 15-20 minutes',
      'Boil milk and froth by pouring between cups',
      'Mix 1/4 cup decoction with 3/4 cup hot milk',
      'Add sugar and serve in traditional dabarah',
    ],
    instructionsTe: [
      'ఫిల్టర్ పై భాగంలో కాఫీ పొడి వేయండి',
      'చిల్లుల ప్లేటుతో మెల్లగా నొక్కండి',
      'వేడి నీళ్లు పోసి మూత పెట్టండి',
      '15-20 నిమిషాలు డికాక్షన్ బట్టెలేయండి',
      'పాలు మరిగించి గ్లాసుల మధ్య పోసి పొంగించండి',
      '1/4 కప్పు డికాక్షన్, 3/4 కప్పు వేడి పాలు కలపండి',
      'చక్కెర కలిపి సాంప్రదాయ దబారాలో సర్వ్ చేయండి',
    ],
    cookTimeMinutes: 25,
    servings: 4,
    category: 'Beverages',
    region: 'Andhra',
    isVegetarian: true,
    rating: 4.9,
    calories: 80,
    protein: 3,
    carbs: 10,
    fat: 3,
    difficulty: 'Medium',
    tags: ['coffee', 'filter coffee', 'breakfast', 'beverage'],
  ),

  const Recipe(
    id: '23',
    title: 'Chapala Pulusu',
    titleTe: 'చాపల పులుసు',
    description: 'Tangy fish curry with tamarind, Andhra coastal specialty',
    descriptionTe: 'చింతపండుతో పుల్లటి చేపల పులుసు',
    imageUrl:
        'https://images.unsplash.com/photo-1626202158822-1c83f5f76417?w=800 ',
    ingredients: [
      '500g fish (carp or catfish)',
      'Lemon sized tamarind',
      '2 onions, sliced',
      '2 tomatoes, chopped',
      '2 tbsp ginger-garlic paste',
      '2 tsp red chili powder',
      '1 tsp turmeric',
      '1 tbsp coriander powder',
      '1 tsp fenugreek seeds',
      '10 curry leaves',
      '4 tbsp oil',
      'Salt to taste',
    ],
    ingredientsTe: [
      '500 గ్రా చేప (కోళ్లు లేదా కెట్‌ఫిష్)',
      'నిమ్మకాయ సైజు చింతపండు',
      '2 ఉల్లిపాయలు, తరిగినవి',
      '2 టమాటోలు, తరిగినవి',
      '2 టేబుల్ స్పూన్లు అల్లం-వెల్లుల్లి ముద్ద',
      '2 టీ స్పూన్లు కారం',
      '1 టీ స్పూన్ పసుపు',
      '1 టేబుల్ స్పూన్ ధనియాల పొడి',
      '1 టీ స్పూన్ మెంతులు',
      '10 కరివేపాకు రెబ్బలు',
      '4 టేబుల్ స్పూన్లు నూనె',
      'రుచికి సరిపడా ఉప్పు',
    ],
    instructions: [
      'Clean fish and marinate with turmeric, salt for 30 minutes',
      'Soak tamarind in warm water, extract pulp',
      'Heat oil, fry fish lightly and remove',
      'In same oil, sauté onions until golden',
      'Add ginger-garlic, tomatoes, and cook',
      'Add spices and tamarind pulp, bring to boil',
      'Add fried fish and simmer for 10 minutes',
      'Garnish with curry leaves and serve',
    ],
    instructionsTe: [
      'చేప శుద్ధం చేసి, పసుపు, ఉప్పుతో 30 నిమిషాలు మ్యారినేట్ చేయండి',
      'చింతపండును వేడి నీళ్లలో నానబెట్టి పులుసు తీయండి',
      'నూనె వేడి చేసి, చేపలు తేలికగా వేయించి పక్కన పెట్టండి',
      'అదే నూనెలో ఉల్లిపాయలు బంగారు రంగు వచ్చేవరకు వేయించండి',
      'అల్లం-వెల్లుల్లి, టమాటోలు వేసి ఉడికించండి',
      'మసాలాలు, చింతపండు పులుసు వేసి మరిగించండి',
      'వేయించిన చేపలు వేసి 10 నిమిషాలు మరిగించండి',
      'కరివేపాకుతో అలంకరించి సర్వ్ చేయండి',
    ],
    cookTimeMinutes: 40,
    servings: 4,
    category: 'Dinner',
    region: 'Andhra',
    isVegetarian: false,
    rating: 4.8,
    calories: 260,
    protein: 26,
    carbs: 12,
    fat: 12,
    difficulty: 'Medium',
    tags: ['fish', 'pulusu', 'coastal', 'dinner'],
  ),

  const Recipe(
    id: '24',
    title: 'Palakura Pappu',
    titleTe: 'పాలకూర పప్పు',
    description: 'Nutritious spinach and lentil curry, comfort food',
    descriptionTe: 'పోషకాలతో కూడిన పాలకూర పప్పు',
    imageUrl:
        'https://images.unsplash.com/photo-1606491956689-05f4575a45d8?w=800 ',
    ingredients: [
      '1 cup toor dal',
      '2 cups spinach, chopped',
      '1 onion, chopped',
      '2 tomatoes, chopped',
      '2 green chilies',
      '1 tsp ginger-garlic paste',
      '1 tsp turmeric',
      '1 tsp red chili powder',
      '1 tsp mustard seeds',
      '1 tsp cumin seeds',
      '2 dry red chilies',
      '2 tbsp oil',
      'Salt to taste',
    ],
    ingredientsTe: [
      '1 కప్పు కందిపప్పు',
      '2 కప్పులు పాలకూర, తరిగినది',
      '1 ఉల్లిపాయ, తరిగినది',
      '2 టమాటోలు, తరిగినవి',
      '2 పచ్చి మిరపకాయలు',
      '1 టీ స్పూన్ అల్లం-వెల్లుల్లి ముద్ద',
      '1 టీ స్పూన్ పసుపు',
      '1 టీ స్పూన్ కారం',
      '1 టీ స్పూన్ ఆవాలు',
      '1 టీ స్పూన్ జీలకర్ర',
      '2 ఎండు మిరపకాయలు',
      '2 టేబుల్ స్పూన్లు నూనె',
      'రుచికి సరిపడా ఉప్పు',
    ],
    instructions: [
      'Pressure cook dal with turmeric until mushy',
      'Mash cooked dal and set aside',
      'Heat oil, temper with mustard, cumin, red chilies',
      'Sauté onions, green chilies, ginger-garlic',
      'Add tomatoes and cook until soft',
      'Add spinach and cook until wilted',
      'Add mashed dal, chili powder, salt, and water',
      'Simmer for 10 minutes and serve hot with rice',
    ],
    instructionsTe: [
      'పసుపుతో కందిపప్పు ప్రెజర్ కుక్ చేసి మెత్తబడేలా చేయండి',
      'ఉడికిన పప్పును మెత్తగా చేసి పక్కన పెట్టండి',
      'నూనె వేడి చేసి, ఆవాలు, జీలకర్ర, ఎండు మిరపకాయలతో తాలింపు',
      'ఉల్లిపాయలు, పచ్చి మిరపకాయలు, అల్లం-వెల్లుల్లి వేయించండి',
      'టమాటోలు వేసి మెత్తబడేవరకు ఉడికించండి',
      'పాలకూర వేసి వాడేవరకు ఉడికించండి',
      'మెత్తగా చేసిన పప్పు, కారం, ఉప్పు, నీళ్లు కలపండి',
      '10 నిమిషాలు మరిగించి వేడివేడిగా అన్నంలో సర్వ్ చేయండి',
    ],
    cookTimeMinutes: 35,
    servings: 4,
    category: 'Dinner',
    region: 'Andhra',
    isVegetarian: true,
    rating: 4.7,
    calories: 180,
    protein: 10,
    carbs: 28,
    fat: 4,
    difficulty: 'Easy',
    tags: ['dal', 'spinach', 'healthy', 'comfort food'],
  ),

  const Recipe(
    id: '25',
    title: 'Mutton Keema',
    titleTe: 'మటన్ కీమా',
    description: 'Minced mutton curry with peas, perfect with roti or rice',
    descriptionTe: 'బటానీలతో మటన్ కీమా కూర',
    imageUrl:
        'https://images.unsplash.com/photo-1606491956689-05f4575a45d8?w=800 ',
    ingredients: [
      '500g minced mutton',
      '1 cup green peas',
      '2 onions, finely chopped',
      '2 tomatoes, pureed',
      '2 tbsp ginger-garlic paste',
      '2 tsp red chili powder',
      '1 tsp turmeric',
      '1 tbsp coriander powder',
      '1 tsp garam masala',
      '1 tsp cumin seeds',
      '4 tbsp oil',
      'Fresh coriander',
      'Salt to taste',
    ],
    ingredientsTe: [
      '500 గ్రా మటన్ కీమా',
      '1 కప్పు బటానీలు',
      '2 ఉల్లిపాయలు, సన్నగా తరిగినవి',
      '2 టమాటోలు, ప్యూరీ చేసినవి',
      '2 టేబుల్ స్పూన్లు అల్లం-వెల్లుల్లి ముద్ద',
      '2 టీ స్పూన్లు కారం',
      '1 టీ స్పూన్ పసుపు',
      '1 టేబుల్ స్పూన్ ధనియాల పొడి',
      '1 టీ స్పూన్ గరం మసాలా',
      '1 టీ స్పూన్ జీలకర్ర',
      '4 టేబుల్ స్పూన్లు నూనె',
      'కొత్తిమీర',
      'రుచికి సరిపడా ఉప్పు',
    ],
    instructions: [
      'Marinate keema with turmeric, salt, and chili powder for 30 minutes',
      'Heat oil, sauté cumin and onions until golden',
      'Add ginger-garlic paste and fry for 2 minutes',
      'Add tomato puree and cook until oil separates',
      'Add marinated keema and cook for 15 minutes',
      'Add coriander powder, garam masala, and peas',
      'Cook until keema is done and peas are tender',
      'Garnish with coriander and serve',
    ],
    instructionsTe: [
      'కీమాను పసుపు, ఉప్పు, కారంతో 30 నిమిషాలు మ్యారినేట్ చేయండి',
      'నూనె వేడి చేసి, జీలకర్ర, ఉల్లిపాయలు బంగారు రంగు వచ్చేవరకు వేయించండి',
      'అల్లం-వెల్లుల్లి ముద్ద వేసి 2 నిమిషాలు వేయించండి',
      'టమాటో ప్యూరీ వేసి నూనె వేరుకావాలి',
      'మ్యారినేట్ కీమా వేసి 15 నిమిషాలు ఉడికించండి',
      'ధనియాల పొడి, గరం మసాలా, బటానీలు కలపండి',
      'కీమా ఉడికి, బటానీలు మెత్తబడేవరకు ఉడికించండి',
      'కొత్తిమీరతో అలంకరించి సర్వ్ చేయండి',
    ],
    cookTimeMinutes: 45,
    servings: 4,
    category: 'Dinner',
    region: 'Telangana',
    isVegetarian: false,
    rating: 4.8,
    calories: 320,
    protein: 26,
    carbs: 14,
    fat: 18,
    difficulty: 'Medium',
    tags: ['mutton', 'keema', 'minced', 'dinner'],
  ),
];
