import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/recipe_model.dart';

part 'recipe_event.dart';
part 'recipe_state.dart';

class RecipeBloc extends Bloc<RecipeEvent, RecipeState> {
  final List<Recipe> _allRecipes;

  RecipeBloc({List<Recipe>? recipes})
      : _allRecipes = recipes ?? sampleRecipes,
        super(const RecipeInitial()) {
    on<LoadRecipes>(_onLoadRecipes);
    on<SearchRecipes>(_onSearchRecipes);
    on<FilterByCategory>(_onFilterByCategory);
    on<FilterByRegion>(_onFilterByRegion);
    on<FilterByDifficulty>(_onFilterByDifficulty);
    on<ToggleVegetarian>(_onToggleVegetarian);
    on<ToggleFavorite>(_onToggleFavorite);
    on<LoadFavorites>(_onLoadFavorites);
    on<ToggleFavoritesView>(_onToggleFavoritesView);
    on<SortRecipes>(_onSortRecipes);
    on<FilterByMaxTime>(_onFilterByMaxTime);
    on<ClearFilters>(_onClearFilters);
  }

  // ── Load ───────────────────────────────────────────────────────────────────

  Future<void> _onLoadRecipes(
    LoadRecipes event,
    Emitter<RecipeState> emit,
  ) async {
    emit(const RecipeLoading());
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      emit(RecipeLoaded(
        recipes: _allRecipes,
        allRecipes: _allRecipes,
      ));
    } catch (e) {
      emit(RecipeError(e.toString()));
    }
  }

  // ── Core Filter Engine ────────────────────────────────────────────────────
  // Single source of truth for all filtering + sorting logic.

  List<Recipe> _applyFilters({
    required List<Recipe> source,
    required String query,
    required String category,
    required String region,
    required String difficulty,
    required bool vegetarianOnly,
    required bool favoritesOnly,
    required Set<String> favoriteIds,
    required int? maxCookTime,
    required RecipeSortOrder sortOrder,
  }) {
    // 1. Start with source
    List<Recipe> result = source;

    // 2. Favorites-only view
    if (favoritesOnly) {
      result = result.where((r) => favoriteIds.contains(r.id)).toList();
    }

    // 3. Search — uses the extension from recipe_model.dart (Telugu + English)
    if (query.trim().isNotEmpty) {
      result = result.search(query);
    }

    // 4. Category filter
    if (category != 'All') {
      result = result.byCategory(category);
    }

    // 5. Region filter
    if (region != 'All') {
      result = result.byRegion(region);
    }

    // 6. Difficulty filter
    if (difficulty != 'All') {
      result = result.byDifficulty(difficulty);
    }

    // 7. Vegetarian toggle
    if (vegetarianOnly) {
      result = result.vegetarianOnly;
    }

    // 8. Max cook time
    if (maxCookTime != null) {
      result = result.maxCookTime(maxCookTime);
    }

    // 9. Sort
    switch (sortOrder) {
      case RecipeSortOrder.topRated:
        result = result.topRated;
        break;
      case RecipeSortOrder.quickestFirst:
        result = result.quickestFirst;
        break;
      case RecipeSortOrder.alphabetical:
        result = [...result]..sort((a, b) => a.title.compareTo(b.title));
        break;
      case RecipeSortOrder.defaultOrder:
        break; // Keep original order
    }

    return result;
  }

  // ── Helper: rebuild filtered list from current state ──────────────────────

  List<Recipe> _rebuildFromState(
    RecipeLoaded state, {
    String? query,
    String? category,
    String? region,
    String? difficulty,
    bool? vegetarianOnly,
    bool? favoritesOnly,
    Set<String>? favoriteIds,
    int? maxCookTime,
    bool clearMaxTime = false,
    RecipeSortOrder? sortOrder,
  }) {
    return _applyFilters(
      source: state.allRecipes,
      query: query ?? state.searchQuery,
      category: category ?? state.selectedCategory,
      region: region ?? state.selectedRegion,
      difficulty: difficulty ?? state.selectedDifficulty,
      vegetarianOnly: vegetarianOnly ?? state.vegetarianOnly,
      favoritesOnly: favoritesOnly ?? state.showFavoritesOnly,
      favoriteIds: favoriteIds ?? state.favoriteIds,
      maxCookTime:
          clearMaxTime ? null : (maxCookTime ?? state.maxCookTimeMinutes),
      sortOrder: sortOrder ?? state.sortOrder,
    );
  }

  // ── Event Handlers ─────────────────────────────────────────────────────────

  Future<void> _onSearchRecipes(
    SearchRecipes event,
    Emitter<RecipeState> emit,
  ) async {
    final s = state;
    if (s is! RecipeLoaded) return;

    final filtered = _rebuildFromState(s, query: event.query);
    emit(s.copyWith(recipes: filtered, searchQuery: event.query));
  }

  Future<void> _onFilterByCategory(
    FilterByCategory event,
    Emitter<RecipeState> emit,
  ) async {
    final s = state;
    if (s is! RecipeLoaded) return;

    final filtered = _rebuildFromState(s, category: event.category);
    emit(s.copyWith(recipes: filtered, selectedCategory: event.category));
  }

  Future<void> _onFilterByRegion(
    FilterByRegion event,
    Emitter<RecipeState> emit,
  ) async {
    final s = state;
    if (s is! RecipeLoaded) return;

    final filtered = _rebuildFromState(s, region: event.region);
    emit(s.copyWith(recipes: filtered, selectedRegion: event.region));
  }

  Future<void> _onFilterByDifficulty(
    FilterByDifficulty event,
    Emitter<RecipeState> emit,
  ) async {
    final s = state;
    if (s is! RecipeLoaded) return;

    final filtered = _rebuildFromState(s, difficulty: event.difficulty);
    emit(s.copyWith(recipes: filtered, selectedDifficulty: event.difficulty));
  }

  Future<void> _onToggleVegetarian(
    ToggleVegetarian event,
    Emitter<RecipeState> emit,
  ) async {
    final s = state;
    if (s is! RecipeLoaded) return;

    final newVeg = !s.vegetarianOnly;
    final filtered = _rebuildFromState(s, vegetarianOnly: newVeg);
    emit(s.copyWith(recipes: filtered, vegetarianOnly: newVeg));
  }

  Future<void> _onToggleFavorite(
    ToggleFavorite event,
    Emitter<RecipeState> emit,
  ) async {
    final s = state;
    if (s is! RecipeLoaded) return;

    final updatedFavorites = Set<String>.from(s.favoriteIds);
    if (updatedFavorites.contains(event.recipeId)) {
      updatedFavorites.remove(event.recipeId);
    } else {
      updatedFavorites.add(event.recipeId);
    }

    // If in favorites-only view, rebuild so removed item disappears
    final filtered = _rebuildFromState(s, favoriteIds: updatedFavorites);
    emit(s.copyWith(recipes: filtered, favoriteIds: updatedFavorites));
  }

  Future<void> _onLoadFavorites(
    LoadFavorites event,
    Emitter<RecipeState> emit,
  ) async {
    // No-op on initial load — favorites start empty (add persistence later)
  }

  Future<void> _onToggleFavoritesView(
    ToggleFavoritesView event,
    Emitter<RecipeState> emit,
  ) async {
    final s = state;
    if (s is! RecipeLoaded) return;

    final newFavOnly = !s.showFavoritesOnly;
    final filtered = _rebuildFromState(s, favoritesOnly: newFavOnly);
    emit(s.copyWith(recipes: filtered, showFavoritesOnly: newFavOnly));
  }

  Future<void> _onSortRecipes(
    SortRecipes event,
    Emitter<RecipeState> emit,
  ) async {
    final s = state;
    if (s is! RecipeLoaded) return;

    final filtered = _rebuildFromState(s, sortOrder: event.sortOrder);
    emit(s.copyWith(recipes: filtered, sortOrder: event.sortOrder));
  }

  Future<void> _onFilterByMaxTime(
    FilterByMaxTime event,
    Emitter<RecipeState> emit,
  ) async {
    final s = state;
    if (s is! RecipeLoaded) return;

    final filtered = _rebuildFromState(
      s,
      maxCookTime: event.maxMinutes,
      clearMaxTime: event.maxMinutes == null,
    );
    emit(s.copyWith(
      recipes: filtered,
      maxCookTimeMinutes: event.maxMinutes,
      clearMaxTime: event.maxMinutes == null,
    ));
  }

  Future<void> _onClearFilters(
    ClearFilters event,
    Emitter<RecipeState> emit,
  ) async {
    final s = state;
    if (s is! RecipeLoaded) return;

    // Reset all filters but keep favorites
    emit(RecipeLoaded(
      recipes: _allRecipes,
      allRecipes: _allRecipes,
      favoriteIds: s.favoriteIds,
    ));
  }
}
