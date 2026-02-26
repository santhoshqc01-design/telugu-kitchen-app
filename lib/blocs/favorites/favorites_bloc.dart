import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/recipe_model.dart';

part 'favorites_event.dart';
part 'favorites_state.dart';

class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  static const String _favoritesKey = 'favorite_recipes';

  FavoritesBloc() : super(const FavoritesInitial()) {
    // <-- const added
    on<LoadFavorites>(_onLoadFavorites);
    on<ToggleFavorite>(_onToggleFavorite);
    on<RemoveFavorite>(_onRemoveFavorite);
  }

  Future<void> _onLoadFavorites(
    LoadFavorites event,
    Emitter<FavoritesState> emit,
  ) async {
    emit(const FavoritesLoading()); // <-- const added
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getStringList(_favoritesKey) ?? [];

      final favorites = favoritesJson
          .map((json) => Recipe.fromJson(jsonDecode(json)))
          .toList();

      emit(FavoritesLoaded(favorites));
    } catch (e) {
      emit(const FavoritesError('Failed to load favorites')); // <-- const added
    }
  }

  Future<void> _onToggleFavorite(
    ToggleFavorite event,
    Emitter<FavoritesState> emit,
  ) async {
    final currentState = state;
    if (currentState is FavoritesLoaded) {
      final favorites = List<Recipe>.from(currentState.favorites);
      final isFavorite = favorites.any((r) => r.id == event.recipe.id);

      if (isFavorite) {
        favorites.removeWhere((r) => r.id == event.recipe.id);
      } else {
        favorites.add(event.recipe);
      }

      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson =
          favorites.map((recipe) => jsonEncode(recipe.toJson())).toList();
      await prefs.setStringList(_favoritesKey, favoritesJson);

      emit(FavoritesLoaded(favorites));
    }
  }

  Future<void> _onRemoveFavorite(
    RemoveFavorite event,
    Emitter<FavoritesState> emit,
  ) async {
    final currentState = state;
    if (currentState is FavoritesLoaded) {
      final favorites = List<Recipe>.from(currentState.favorites)
        ..removeWhere((r) => r.id == event.recipeId);

      final prefs = await SharedPreferences.getInstance();
      final favoritesJson =
          favorites.map((recipe) => jsonEncode(recipe.toJson())).toList();
      await prefs.setStringList(_favoritesKey, favoritesJson);

      emit(FavoritesLoaded(favorites));
    }
  }

  bool isFavorite(String recipeId) {
    final currentState = state;
    if (currentState is FavoritesLoaded) {
      return currentState.favorites.any((r) => r.id == recipeId);
    }
    return false;
  }
}
