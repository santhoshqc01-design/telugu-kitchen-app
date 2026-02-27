part of 'recipe_bloc.dart';

enum RecipeSortOrder { defaultOrder, topRated, quickestFirst, alphabetical }

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

class RecipeError extends RecipeState {
  final String message;
  const RecipeError(this.message);

  @override
  List<Object?> get props => [message];
}

class RecipeLoaded extends RecipeState {
  // ── Displayed list (after filters/search/sort) ─────────────────────────────
  final List<Recipe> recipes;

  // ── Source of truth ────────────────────────────────────────────────────────
  final List<Recipe> allRecipes;

  // ── Active filters ─────────────────────────────────────────────────────────
  final String searchQuery;
  final String selectedCategory; // 'All' means no filter
  final String selectedRegion; // 'All' means no filter
  final String selectedDifficulty; // 'All' means no filter
  final bool vegetarianOnly;
  final bool showFavoritesOnly;
  final int? maxCookTimeMinutes; // null means no limit
  final RecipeSortOrder sortOrder;

  // ── Favorites ──────────────────────────────────────────────────────────────
  final Set<String> favoriteIds;

  const RecipeLoaded({
    required this.recipes,
    required this.allRecipes,
    this.searchQuery = '',
    this.selectedCategory = 'All',
    this.selectedRegion = 'All',
    this.selectedDifficulty = 'All',
    this.vegetarianOnly = false,
    this.showFavoritesOnly = false,
    this.maxCookTimeMinutes,
    this.sortOrder = RecipeSortOrder.defaultOrder,
    this.favoriteIds = const {},
  });

  // ── Computed helpers ───────────────────────────────────────────────────────

  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      selectedCategory != 'All' ||
      selectedRegion != 'All' ||
      selectedDifficulty != 'All' ||
      vegetarianOnly ||
      showFavoritesOnly ||
      maxCookTimeMinutes != null;

  int get activeFilterCount {
    int count = 0;
    if (selectedCategory != 'All') count++;
    if (selectedRegion != 'All') count++;
    if (selectedDifficulty != 'All') count++;
    if (vegetarianOnly) count++;
    if (maxCookTimeMinutes != null) count++;
    return count;
  }

  bool isFavorite(String recipeId) => favoriteIds.contains(recipeId);

  List<Recipe> get favoriteRecipes =>
      allRecipes.where((r) => favoriteIds.contains(r.id)).toList();

  int get favoriteCount => favoriteIds.length;

  RecipeLoaded copyWith({
    List<Recipe>? recipes,
    List<Recipe>? allRecipes,
    String? searchQuery,
    String? selectedCategory,
    String? selectedRegion,
    String? selectedDifficulty,
    bool? vegetarianOnly,
    bool? showFavoritesOnly,
    int? maxCookTimeMinutes,
    bool clearMaxTime = false,
    RecipeSortOrder? sortOrder,
    Set<String>? favoriteIds,
  }) {
    return RecipeLoaded(
      recipes: recipes ?? this.recipes,
      allRecipes: allRecipes ?? this.allRecipes,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedRegion: selectedRegion ?? this.selectedRegion,
      selectedDifficulty: selectedDifficulty ?? this.selectedDifficulty,
      vegetarianOnly: vegetarianOnly ?? this.vegetarianOnly,
      showFavoritesOnly: showFavoritesOnly ?? this.showFavoritesOnly,
      maxCookTimeMinutes:
          clearMaxTime ? null : (maxCookTimeMinutes ?? this.maxCookTimeMinutes),
      sortOrder: sortOrder ?? this.sortOrder,
      favoriteIds: favoriteIds ?? this.favoriteIds,
    );
  }

  @override
  List<Object?> get props => [
        recipes,
        allRecipes,
        searchQuery,
        selectedCategory,
        selectedRegion,
        selectedDifficulty,
        vegetarianOnly,
        showFavoritesOnly,
        maxCookTimeMinutes,
        sortOrder,
        favoriteIds,
      ];
}
