part of 'recipe_bloc.dart';

abstract class RecipeEvent extends Equatable {
  const RecipeEvent();

  @override
  List<Object> get props => [];
}

class LoadRecipes extends RecipeEvent {
  const LoadRecipes();
}

class SearchRecipes extends RecipeEvent {
  final String query;

  const SearchRecipes(this.query);

  @override
  List<Object> get props => [query];
}

class FilterByCategory extends RecipeEvent {
  final String category;

  const FilterByCategory(this.category);

  @override
  List<Object> get props => [category];
}

class FilterByRegion extends RecipeEvent {
  final String region;

  const FilterByRegion(this.region);

  @override
  List<Object> get props => [region];
}

class ToggleFavorite extends RecipeEvent {
  final String recipeId;

  const ToggleFavorite(this.recipeId);

  @override
  List<Object> get props => [recipeId];
}

class LoadFavorites extends RecipeEvent {
  const LoadFavorites();
}

class ClearFilters extends RecipeEvent {
  const ClearFilters();
}
