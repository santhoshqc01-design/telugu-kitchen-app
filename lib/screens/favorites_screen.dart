import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import '../blocs/favorites/favorites_bloc.dart';
import '../blocs/language/language_bloc.dart';
import '../l10n/app_localizations.dart';
import '../models/recipe_model.dart';
import 'recipe_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTelugu = context.watch<LanguageBloc>().state.isTelugu;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.favorites),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocBuilder<FavoritesBloc, FavoritesState>(
        builder: (context, state) {
          if (state is FavoritesLoading) {
            return _buildShimmerList();
          }

          if (state is FavoritesLoaded) {
            if (state.favorites.isEmpty) {
              return _buildEmptyState(isTelugu, context);
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<FavoritesBloc>().add(const LoadFavorites());
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.favorites.length,
                itemBuilder: (context, index) {
                  final recipe = state.favorites[index];
                  return _buildFavoriteCard(
                    context,
                    recipe,
                    isTelugu,
                    index,
                  );
                },
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  isTelugu ? 'లోడ్ చేయడంలో లోపం' : 'Error loading favorites',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<FavoritesBloc>().add(const LoadFavorites());
                  },
                  child: Text(isTelugu ? 'మళ్ళీ ప్రయత్నించండి' : 'Retry'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isTelugu, BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated heart icon
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.8, end: 1.2),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Icon(
                  Icons.favorite_border,
                  size: 100,
                  color: Colors.grey.shade300,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            isTelugu ? 'ఇంకా ఇష్టమైనవి లేవు' : 'No favorites yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              isTelugu
                  ? 'గుండె బటన్ నొక్కి మీకు నచ్చిన వంటకాలను ఇక్కడ చేర్చండి'
                  : 'Tap the heart button on recipes you love to add them here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to home tab (index 0)
              // This requires a callback or navigation setup
            },
            icon: const Icon(Icons.explore),
            label: Text(
              isTelugu ? 'వంటకాలను చూడండి' : 'Browse Recipes',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              context.read<FavoritesBloc>().add(const LoadFavorites());
            },
            child: Text(
              isTelugu ? 'మళ్ళీ లోడ్ చేయండి' : 'Refresh',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              title: Container(
                height: 16,
                width: 150,
                color: Colors.white,
              ),
              subtitle: Container(
                height: 12,
                width: 100,
                margin: const EdgeInsets.only(top: 8),
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFavoriteCard(
    BuildContext context,
    Recipe recipe,
    bool isTelugu,
    int index,
  ) {
    return Dismissible(
      key: Key(recipe.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.delete, color: Colors.white, size: 32),
            SizedBox(height: 4),
            Text(
              'Remove',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(isTelugu ? 'తొలగించాలా?' : 'Remove?'),
            content: Text(
              isTelugu
                  ? '${isTelugu ? recipe.titleTe : recipe.title} ని ఇష్టమైనవాటి నుండి తొలగించాలా?'
                  : 'Remove ${isTelugu ? recipe.titleTe : recipe.title} from favorites?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(isTelugu ? 'రద్దు' : 'Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  isTelugu ? 'తొలగించు' : 'Remove',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        context.read<FavoritesBloc>().add(RemoveFavorite(recipe.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isTelugu
                  ? '${recipe.titleTe} తొలగించబడింది'
                  : '${recipe.title} removed',
            ),
            action: SnackBarAction(
              label: isTelugu ? 'రద్దు' : 'Undo',
              onPressed: () {
                context.read<FavoritesBloc>().add(ToggleFavorite(recipe));
              },
            ),
          ),
        );
      },
      child: Hero(
        tag: 'favorite-${recipe.id}',
        child: Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RecipeDetailScreen(recipe: recipe),
              ),
            ),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Image with shimmer loading
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: Image.network(
                        recipe.imageUrl,
                        fit: BoxFit.cover,
                        frameBuilder:
                            (context, child, frame, wasSynchronouslyLoaded) {
                          if (wasSynchronouslyLoaded) return child;
                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: frame != null
                                ? child
                                : Shimmer.fromColors(
                                    baseColor: Colors.grey.shade300,
                                    highlightColor: Colors.grey.shade100,
                                    child: Container(color: Colors.white),
                                  ),
                          );
                        },
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.restaurant,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (recipe.isVegetarian)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Veg',
                                  style: TextStyle(
                                    color: Colors.green.shade800,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Text(
                                isTelugu ? recipe.titleTe : recipe.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.timer,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${recipe.cookTimeMinutes} min',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.trending_up,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              recipe.difficulty,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 14,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  recipe.rating.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Favorite button
                  IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () {
                      _showRemoveDialog(context, recipe, isTelugu);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showRemoveDialog(BuildContext context, Recipe recipe, bool isTelugu) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isTelugu ? 'తొలగించాలా?' : 'Remove from favorites?'),
        content: Text(
          isTelugu
              ? '${recipe.titleTe} ని ఇష్టమైనవాటి నుండి తొలగించాలా?'
              : 'Remove ${recipe.title} from your favorites?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isTelugu ? 'రద్దు' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<FavoritesBloc>().add(RemoveFavorite(recipe.id));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isTelugu
                        ? '${recipe.titleTe} తొలగించబడింది'
                        : '${recipe.title} removed',
                  ),
                  action: SnackBarAction(
                    label: isTelugu ? 'రద్దు' : 'Undo',
                    onPressed: () {
                      context.read<FavoritesBloc>().add(ToggleFavorite(recipe));
                    },
                  ),
                ),
              );
            },
            child: Text(
              isTelugu ? 'తొలగించు' : 'Remove',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
