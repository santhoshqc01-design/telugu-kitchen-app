part of 'recipe_bloc.dart';

abstract class RecipeEvent extends Equatable {
  const RecipeEvent();

  @override
  List<Object?> get props => [];
}

class LoadRecipes extends RecipeEvent {
  const LoadRecipes();
}

class SearchRecipes extends RecipeEvent {
  final String query;
  const SearchRecipes(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterByCategory extends RecipeEvent {
  final String category; // 'All' to clear
  const FilterByCategory(this.category);

  @override
  List<Object?> get props => [category];
}

class FilterByRegion extends RecipeEvent {
  final String region; // 'All' to clear
  const FilterByRegion(this.region);

  @override
  List<Object?> get props => [region];
}

class FilterByDifficulty extends RecipeEvent {
  final String difficulty; // 'All' to clear
  const FilterByDifficulty(this.difficulty);

  @override
  List<Object?> get props => [difficulty];
}

class ToggleVegetarian extends RecipeEvent {
  const ToggleVegetarian();
}

class ToggleFavorite extends RecipeEvent {
  final String recipeId;
  const ToggleFavorite(this.recipeId);

  @override
  List<Object?> get props => [recipeId];
}

class LoadFavorites extends RecipeEvent {
  const LoadFavorites();
}

class ToggleFavoritesView extends RecipeEvent {
  const ToggleFavoritesView();
}

class SortRecipes extends RecipeEvent {
  final RecipeSortOrder sortOrder;
  const SortRecipes(this.sortOrder);

  @override
  List<Object?> get props => [sortOrder];
}

class FilterByMaxTime extends RecipeEvent {
  final int? maxMinutes; // null = no limit
  const FilterByMaxTime(this.maxMinutes);

  @override
  List<Object?> get props => [maxMinutes];
}

class ClearFilters extends RecipeEvent {
  const ClearFilters();
}
