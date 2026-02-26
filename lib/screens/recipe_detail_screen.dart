import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import '../blocs/language/language_bloc.dart';
import '../blocs/favorites/favorites_bloc.dart';
import '../l10n/app_localizations.dart';
import '../models/recipe_model.dart';
import 'cooking_mode_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late int _currentServings;
  late double _multiplier;
  final bool _isImageLoading = true;

  @override
  void initState() {
    super.initState();
    _currentServings = widget.recipe.servings;
    _multiplier = 1.0;
  }

  void _updateServings(int newServings) {
    setState(() {
      _multiplier = newServings / widget.recipe.servings;
      _currentServings = newServings;
    });
  }

  String _adjustQuantity(String ingredient) {
    final regex = RegExp(r'^(\d+\.?\d*)\s*(.*)$');
    final match = regex.firstMatch(ingredient);

    if (match != null) {
      final originalQuantity = double.parse(match.group(1)!);
      final unitAndName = match.group(2)!;
      final adjustedQuantity = originalQuantity * _multiplier;

      String formattedQuantity;
      if (adjustedQuantity == adjustedQuantity.roundToDouble()) {
        formattedQuantity = adjustedQuantity.round().toString();
      } else {
        formattedQuantity = adjustedQuantity.toStringAsFixed(1);
      }

      return '$formattedQuantity $unitAndName';
    }

    return ingredient;
  }

  List<String> _getAdjustedIngredients(bool isTelugu) {
    final ingredients =
        isTelugu ? widget.recipe.ingredientsTe : widget.recipe.ingredients;
    return ingredients.map(_adjustQuantity).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTelugu = context.watch<LanguageBloc>().state.isTelugu;
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: isTablet ? 350 : 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                isTelugu ? widget.recipe.titleTe : widget.recipe.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.black45,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
              background: Hero(
                tag: 'recipe-${widget.recipe.id}',
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // IMPROVED: Image with shimmer loading and error handling
                    Image.network(
                      widget.recipe.imageUrl,
                      fit: BoxFit.cover,
                      frameBuilder:
                          (context, child, frame, wasSynchronouslyLoaded) {
                        if (wasSynchronouslyLoaded) return child;
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          child: frame != null
                              ? child
                              : Shimmer.fromColors(
                                  baseColor: Colors.grey.shade300,
                                  highlightColor: Colors.grey.shade100,
                                  child: Container(color: Colors.white),
                                ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.restaurant,
                                size: 80,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                isTelugu ? 'చిత్రం లేదు' : 'No Image Available',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    // Gradient overlay
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black54,
                          ],
                          stops: [0.6, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _shareRecipe(isTelugu),
              ),
              BlocBuilder<FavoritesBloc, FavoritesState>(
                builder: (context, state) {
                  bool isFavorite = false;
                  if (state is FavoritesLoaded) {
                    isFavorite =
                        state.favorites.any((r) => r.id == widget.recipe.id);
                  }

                  return IconButton(
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        key: ValueKey<bool>(isFavorite),
                        color: isFavorite ? Colors.red : Colors.white,
                      ),
                    ),
                    onPressed: () =>
                        _toggleFavorite(context, isFavorite, isTelugu),
                  );
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 24 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tags row
                  _buildTagsRow(isTelugu, isTablet),
                  SizedBox(height: isTablet ? 16 : 12),
                  Text(
                    isTelugu
                        ? widget.recipe.descriptionTe
                        : widget.recipe.description,
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: isTablet ? 24 : 16),
                  _buildServingsAdjuster(isTelugu, isTablet),
                  SizedBox(height: isTablet ? 24 : 16),
                  _buildInfoCards(l10n, isTelugu, isTablet),
                  SizedBox(height: isTablet ? 24 : 16),
                  _buildNutritionInfo(widget.recipe, isTelugu),
                  SizedBox(height: isTablet ? 24 : 16),
                  _buildSectionTitle(l10n.ingredients, isTablet),
                  SizedBox(height: isTablet ? 12 : 8),
                  _buildIngredientsList(isTelugu, isTablet),
                  SizedBox(height: isTablet ? 32 : 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _startCooking(context),
                      icon: const Icon(Icons.play_arrow),
                      label: Text(
                        l10n.startCooking,
                        style: TextStyle(
                          fontSize: isTablet ? 20 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade800,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 20 : 16,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),
                  SizedBox(height: isTablet ? 24 : 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsRow(bool isTelugu, bool isTablet) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildTag(
          widget.recipe.isVegetarian
              ? (isTelugu ? 'శాకాహారం' : 'Vegetarian')
              : (isTelugu ? 'మాంసాహారం' : 'Non-Vegetarian'),
          widget.recipe.isVegetarian ? Colors.green : Colors.red,
        ),
        _buildTag(
          _getRegionName(isTelugu),
          Colors.orange,
        ),
        _buildTag(
          widget.recipe.category,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildTag(String text, Color color) {
    // Determine if color is light or dark to choose appropriate text color
    final hsl = HSLColor.fromColor(color);
    final isLight = hsl.lightness > 0.5;
    final textColor = isLight ? Colors.black87 : Colors.white;

    // Create darker version for border
    final darkerColor =
        hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0)).toColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: darkerColor.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: darkerColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  String _getRegionName(bool isTelugu) {
    final region = widget.recipe.region;
    if (!isTelugu) return region;

    switch (region.toLowerCase()) {
      case 'andhra':
        return 'ఆంధ్ర';
      case 'telangana':
        return 'తెలంగాణ';
      case 'rayalaseema':
        return 'రాయలసీమ';
      default:
        return region;
    }
  }

  void _shareRecipe(bool isTelugu) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isTelugu ? 'త్వరలో వస్తుంది' : 'Coming soon'),
      ),
    );
  }

  void _toggleFavorite(BuildContext context, bool isFavorite, bool isTelugu) {
    context.read<FavoritesBloc>().add(ToggleFavorite(widget.recipe));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFavorite
              ? (isTelugu
                  ? 'ఇష్టమైనవాటి నుండి తీసివేయబడింది'
                  : 'Removed from favorites')
              : (isTelugu ? 'ఇష్టమైనవాటిలో చేర్చబడింది' : 'Added to favorites'),
        ),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: isTelugu ? 'రద్దు' : 'Undo',
          onPressed: () {
            context.read<FavoritesBloc>().add(ToggleFavorite(widget.recipe));
          },
        ),
      ),
    );
  }

  void _startCooking(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CookingModeScreen(recipe: widget.recipe),
      ),
    );
  }

  Widget _buildServingsAdjuster(bool isTelugu, bool isTablet) {
    return Card(
      elevation: 4,
      color: Colors.orange.shade50,
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        child: Column(
          children: [
            Text(
              isTelugu ? 'ఎంత మందికి వండాలి?' : 'How many people to cook for?',
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade800,
              ),
            ),
            SizedBox(height: isTablet ? 16 : 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildServingsButton(
                  Icons.remove,
                  () {
                    if (_currentServings > 1) {
                      _updateServings(_currentServings - 1);
                    }
                  },
                  isTablet,
                ),
                SizedBox(width: isTablet ? 24 : 16),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 24 : 16,
                    vertical: isTablet ? 12 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    border: Border.all(color: Colors.orange.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$_currentServings',
                        style: TextStyle(
                          fontSize: isTablet ? 32 : 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                      Text(
                        isTelugu
                            ? (_currentServings == 1 ? 'వ్యక్తి' : 'మంది')
                            : (_currentServings == 1 ? 'person' : 'people'),
                        style: TextStyle(
                          fontSize: isTablet ? 14 : 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: isTablet ? 24 : 16),
                _buildServingsButton(
                  Icons.add,
                  () {
                    if (_currentServings < 20) {
                      _updateServings(_currentServings + 1);
                    }
                  },
                  isTablet,
                ),
              ],
            ),
            if (_multiplier != 1.0) ...[
              SizedBox(height: isTablet ? 12 : 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isTelugu
                      ? 'పదార్థాలు ${_multiplier.toStringAsFixed(1)}x పెరిగాయి'
                      : 'Ingredients adjusted by ${_multiplier.toStringAsFixed(1)}x',
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServingsButton(
      IconData icon, VoidCallback onPressed, bool isTablet) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: EdgeInsets.all(isTablet ? 16 : 12),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      child: Icon(icon, size: isTablet ? 28 : 24),
    );
  }

  Widget _buildInfoCards(AppLocalizations l10n, bool isTelugu, bool isTablet) {
    final infoItems = [
      (Icons.timer, '${widget.recipe.cookTimeMinutes} min', l10n.cookTime),
      (Icons.people, '$_currentServings', l10n.servings),
      (Icons.trending_up, widget.recipe.difficulty, l10n.difficulty),
    ];

    return Row(
      children: infoItems.map((item) {
        return Expanded(
          child: Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 16 : 12),
              child: Column(
                children: [
                  Icon(
                    item.$1,
                    color: Colors.orange.shade800,
                    size: isTablet ? 28 : 24,
                  ),
                  SizedBox(height: isTablet ? 8 : 4),
                  Text(
                    item.$2,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isTablet ? 18 : 16,
                    ),
                  ),
                  Text(
                    item.$3,
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNutritionInfo(Recipe recipe, bool isTelugu) {
    final nutritionItems = [
      (
        value: '${recipe.calories}',
        unit: 'kcal',
        label: isTelugu ? 'కేలరీలు' : 'Calories',
        color: Colors.orange
      ),
      (
        value: '${recipe.protein}g',
        unit: '',
        label: isTelugu ? 'ప్రోటీన్' : 'Protein',
        color: Colors.red
      ),
      (
        value: '${recipe.carbs}g',
        unit: '',
        label: isTelugu ? 'కార్బ్స్' : 'Carbs',
        color: Colors.green
      ),
      (
        value: '${recipe.fat}g',
        unit: '',
        label: isTelugu ? 'కొవ్వు' : 'Fat',
        color: Colors.blue
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 350;

        return Container(
          padding: EdgeInsets.symmetric(
            vertical: 16,
            horizontal: isSmallScreen ? 8 : 12,
          ),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceEvenly, // Changed from spaceAround
            children: nutritionItems.map((item) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.value,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: item.color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.unit.isNotEmpty)
                        Text(
                          item.unit,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 9 : 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 10 : 11,
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, bool isTablet) {
    return Row(
      children: [
        Container(
          width: 4,
          height: isTablet ? 28 : 24,
          decoration: BoxDecoration(
            color: Colors.orange.shade800,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: isTablet ? 12 : 8),
        Text(
          title,
          style: TextStyle(
            fontSize: isTablet ? 24 : 20,
            fontWeight: FontWeight.bold,
            color: Colors.orange.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientsList(bool isTelugu, bool isTablet) {
    final ingredients = _getAdjustedIngredients(isTelugu);

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 16 : 12),
        child: Column(
          children: ingredients.asMap().entries.map((entry) {
            final isAdjusted = _multiplier != 1.0;
            return Padding(
              padding: EdgeInsets.symmetric(vertical: isTablet ? 8 : 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: isTablet ? 28 : 24,
                    height: isTablet ? 28 : 24,
                    decoration: BoxDecoration(
                      color: isAdjusted
                          ? Colors.orange.shade200
                          : Colors.orange.shade100,
                      shape: BoxShape.circle,
                      border: isAdjusted
                          ? Border.all(color: Colors.orange.shade800, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: isTablet ? 14 : 12,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isTablet ? 16 : 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        fontWeight:
                            isAdjusted ? FontWeight.w600 : FontWeight.normal,
                        color: isAdjusted
                            ? Colors.orange.shade900
                            : Colors.black87,
                      ),
                    ),
                  ),
                  if (isAdjusted)
                    Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: Colors.orange.shade400,
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
