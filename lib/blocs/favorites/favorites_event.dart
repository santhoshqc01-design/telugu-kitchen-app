part of 'favorites_bloc.dart';

abstract class FavoritesEvent extends Equatable {
  const FavoritesEvent();

  @override
  List<Object> get props => [];
}

class LoadFavorites extends FavoritesEvent {
  const LoadFavorites(); // <-- ADDED const
}

class ToggleFavorite extends FavoritesEvent {
  final Recipe recipe;

  const ToggleFavorite(this.recipe);

  @override
  List<Object> get props => [recipe];
}

class RemoveFavorite extends FavoritesEvent {
  final String recipeId;

  const RemoveFavorite(this.recipeId);

  @override
  List<Object> get props => [recipeId];
}
