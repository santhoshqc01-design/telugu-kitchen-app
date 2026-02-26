part of 'recipe_bloc.dart';

abstract class RecipeState extends Equatable {
  const RecipeState();

  @override
  List<Object?> get props => [];
}

class RecipeInitial extends RecipeState {
  const RecipeInitial();
}

class RecipeLoading extends RecipeState {
  const RecipeLoading();
}

class RecipeLoaded extends RecipeState {
  final List<Recipe> recipes;
  final List<Recipe> allRecipes;
  final Set<String> favoriteIds;
  final String? searchQuery;
  final String? selectedCategory; // Changed from categoryFilter
  final String? selectedRegion; // Changed from regionFilter
  final bool showFavoritesOnly;

  const RecipeLoaded({
    required this.recipes,
    required this.allRecipes,
    this.favoriteIds = const {},
    this.searchQuery,
    this.selectedCategory,
    this.selectedRegion,
    this.showFavoritesOnly = false,
  });

  // Getter aliases for BLoC compatibility
  String? get categoryFilter => selectedCategory;
  String? get regionFilter => selectedRegion;
  Set<String> get favorites => favoriteIds;

  bool isFavorite(String recipeId) => favoriteIds.contains(recipeId);

  List<Recipe> get favoriteRecipes =>
      allRecipes.where((r) => favoriteIds.contains(r.id)).toList();

  RecipeLoaded copyWith({
    List<Recipe>? recipes,
    List<Recipe>? allRecipes,
    Set<String>? favoriteIds,
    String? searchQuery,
    String? selectedCategory,
    String? selectedRegion,
    bool? showFavoritesOnly,
  }) {
    return RecipeLoaded(
      recipes: recipes ?? this.recipes,
      allRecipes: allRecipes ?? this.allRecipes,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedRegion: selectedRegion ?? this.selectedRegion,
      showFavoritesOnly: showFavoritesOnly ?? this.showFavoritesOnly,
    );
  }

  @override
  List<Object?> get props => [
        recipes,
        allRecipes,
        favoriteIds,
        searchQuery,
        selectedCategory,
        selectedRegion,
        showFavoritesOnly,
      ];
}

class RecipeError extends RecipeState {
  final String message;
  const RecipeError(this.message);

  @override
  List<Object> get props => [message];
}
