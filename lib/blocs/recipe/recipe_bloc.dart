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
    on<ToggleFavorite>(_onToggleFavorite);
    on<LoadFavorites>(_onLoadFavorites);
    on<ClearFilters>(_onClearFilters);
  }

  Future<void> _onLoadRecipes(
    LoadRecipes event,
    Emitter<RecipeState> emit,
  ) async {
    emit(const RecipeLoading());
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      emit(RecipeLoaded(
        recipes: _allRecipes,
        allRecipes: _allRecipes,
      ));
    } catch (e) {
      emit(RecipeError(e.toString()));
    }
  }

  List<Recipe> _applyFilters({
    required List<Recipe> source,
    String? query,
    String? category,
    String? region,
    Set<String>? favorites,
    bool favoritesOnly = false,
  }) {
    return source.where((recipe) {
      if (favoritesOnly && !(favorites?.contains(recipe.id) ?? false)) {
        return false;
      }

      if (query != null && query.isNotEmpty) {
        final searchLower = query.toLowerCase();
        final matches = recipe.title.toLowerCase().contains(searchLower) ||
            recipe.titleTe.toLowerCase().contains(searchLower) ||
            recipe.tags.any((tag) => tag.toLowerCase().contains(searchLower));
        if (!matches) return false;
      }

      if (category != null && category != 'All') {
        if (recipe.category != category) return false;
      }

      if (region != null && region != 'All') {
        if (recipe.region != region) return false;
      }

      return true;
    }).toList();
  }

  Future<void> _onSearchRecipes(
    SearchRecipes event,
    Emitter<RecipeState> emit,
  ) async {
    final currentState = state;
    if (currentState is RecipeLoaded) {
      final filtered = _applyFilters(
        source: currentState.allRecipes,
        query: event.query,
        category: currentState.selectedCategory,
        region: currentState.selectedRegion,
        favorites: currentState.favoriteIds,
      );

      emit(currentState.copyWith(
        recipes: filtered,
        searchQuery: event.query,
      ));
    }
  }

  Future<void> _onFilterByCategory(
    FilterByCategory event,
    Emitter<RecipeState> emit,
  ) async {
    final currentState = state;
    if (currentState is RecipeLoaded) {
      final filtered = _applyFilters(
        source: currentState.allRecipes,
        query: currentState.searchQuery,
        category: event.category,
        region: currentState.selectedRegion,
        favorites: currentState.favoriteIds,
      );

      emit(currentState.copyWith(
        recipes: filtered,
        selectedCategory: event.category,
      ));
    }
  }

  Future<void> _onFilterByRegion(
    FilterByRegion event,
    Emitter<RecipeState> emit,
  ) async {
    final currentState = state;
    if (currentState is RecipeLoaded) {
      final filtered = _applyFilters(
        source: currentState.allRecipes,
        query: currentState.searchQuery,
        category: currentState.selectedCategory,
        region: event.region,
        favorites: currentState.favoriteIds,
      );

      emit(currentState.copyWith(
        recipes: filtered,
        selectedRegion: event.region,
      ));
    }
  }

  Future<void> _onToggleFavorite(
    ToggleFavorite event,
    Emitter<RecipeState> emit,
  ) async {
    final currentState = state;
    if (currentState is RecipeLoaded) {
      final updatedFavorites = Set<String>.from(currentState.favoriteIds);

      if (updatedFavorites.contains(event.recipeId)) {
        updatedFavorites.remove(event.recipeId);
      } else {
        updatedFavorites.add(event.recipeId);
      }

      emit(currentState.copyWith(favoriteIds: updatedFavorites));
    }
  }

  Future<void> _onLoadFavorites(
    LoadFavorites event,
    Emitter<RecipeState> emit,
  ) async {
    final currentState = state;
    if (currentState is RecipeLoaded) {
      final filtered = _applyFilters(
        source: currentState.allRecipes,
        query: currentState.searchQuery,
        category: currentState.selectedCategory,
        region: currentState.selectedRegion,
        favorites: currentState.favoriteIds,
        favoritesOnly: true,
      );

      emit(currentState.copyWith(
        recipes: filtered,
        showFavoritesOnly: true,
      ));
    }
  }

  Future<void> _onClearFilters(
    ClearFilters event,
    Emitter<RecipeState> emit,
  ) async {
    final currentState = state;
    if (currentState is RecipeLoaded) {
      emit(RecipeLoaded(
        recipes: currentState.allRecipes,
        allRecipes: currentState.allRecipes,
        favoriteIds: currentState.favoriteIds,
      ));
    }
  }
}
