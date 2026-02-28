import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import '../blocs/language/language_bloc.dart';
import '../blocs/recipe/recipe_bloc.dart';
import '../l10n/app_localizations.dart';
import '../models/recipe_model.dart';
import '../service_locator.dart';
import '../widgets/ingredient_tile.dart';
import '../services/ingredient_download_service.dart';
import 'package:share_plus/share_plus.dart';
import 'cooking_mode_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen>
    with SingleTickerProviderStateMixin {
  late int _currentServings;
  late double _multiplier;
  late TabController _tabController;
  // RepaintBoundary key — used for screenshot export of ingredients
  final GlobalKey _ingredientBoundaryKey = GlobalKey();

  static const int _maxServings = 20;

  @override
  void initState() {
    super.initState();
    _currentServings = widget.recipe.servings;
    _multiplier = 1.0;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Servings Logic ─────────────────────────────────────────────────────────

  void _updateServings(int newServings) {
    if (newServings < 1 || newServings > _maxServings) return;
    setState(() {
      _currentServings = newServings;
      _multiplier = newServings / widget.recipe.servings;
    });
  }

  /// Scales a leading number in an ingredient string.
  /// "500g chicken" → "1000g chicken" (at 2x)
  String _adjustQuantity(String ingredient) {
    final regex = RegExp(r'^(\d+\.?\d*)\s*(.*)$');
    final match = regex.firstMatch(ingredient);
    if (match == null) return ingredient;

    final original = double.parse(match.group(1)!);
    final rest = match.group(2)!;
    final adjusted = original * _multiplier;
    final formatted = adjusted == adjusted.roundToDouble()
        ? adjusted.round().toString()
        : adjusted.toStringAsFixed(1);

    return '$formatted $rest'.trim();
  }

  List<String> _adjustedIngredients(bool isTelugu) {
    final src =
        isTelugu ? widget.recipe.ingredientsTe : widget.recipe.ingredients;
    return src.map(_adjustQuantity).toList();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTelugu = context.watch<LanguageBloc>().state.isTelugu;
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(isTelugu, isTablet),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 24 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTagsRow(isTelugu),
                  const SizedBox(height: 12),
                  _buildDescription(isTelugu, isTablet),
                  const SizedBox(height: 16),
                  _buildInfoCards(l10n, isTablet),
                  const SizedBox(height: 16),
                  _buildNutritionBar(isTelugu),
                  const SizedBox(height: 24),
                  _buildServingsAdjuster(isTelugu, isTablet),
                  const SizedBox(height: 24),
                  _buildIngredientsAndInstructions(l10n, isTelugu, isTablet),
                  const SizedBox(height: 24),
                  _buildStartCookingButton(l10n, isTablet),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sliver App Bar ─────────────────────────────────────────────────────────

  Widget _buildSliverAppBar(bool isTelugu, bool isTablet) {
    return SliverAppBar(
      expandedHeight: isTablet ? 350 : 280,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          isTelugu ? widget.recipe.titleTe : widget.recipe.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                  blurRadius: 4, color: Colors.black54, offset: Offset(0, 2)),
            ],
          ),
        ),
        background: Hero(
          tag: 'recipe-${widget.recipe.id}',
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                widget.recipe.imageUrl,
                fit: BoxFit.cover,
                frameBuilder: (_, child, frame, wasSynchronouslyLoaded) {
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
                errorBuilder: (_, __, ___) => Container(
                  color: widget.recipe.regionColor.withValues(alpha: 0.15),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant_menu_rounded,
                          size: 80,
                          color:
                              widget.recipe.regionColor.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Text(
                        isTelugu ? 'చిత్రం లేదు' : 'No Image',
                        style: TextStyle(
                          color: widget.recipe.regionColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Gradient overlay for text legibility
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black54],
                    stops: [0.5, 1.0],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_rounded),
          onPressed: () => _shareRecipe(isTelugu),
          tooltip: isTelugu ? 'షేర్ చేయి' : 'Share',
        ),
        // Favorite button — uses RecipeBloc (consistent with home_screen)
        BlocBuilder<RecipeBloc, RecipeState>(
          builder: (context, state) {
            final isFavorite =
                state is RecipeLoaded && state.isFavorite(widget.recipe.id);
            return IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_outline_rounded,
                  key: ValueKey(isFavorite),
                  color: isFavorite ? Colors.red : Colors.white,
                ),
              ),
              onPressed: () => _toggleFavorite(context, isFavorite, isTelugu),
              tooltip: isTelugu
                  ? (isFavorite ? 'తీసివేయి' : 'ఇష్టమైనది')
                  : (isFavorite ? 'Remove favorite' : 'Add to favorites'),
            );
          },
        ),
      ],
    );
  }

  // ── Tags Row ───────────────────────────────────────────────────────────────

  Widget _buildTagsRow(bool isTelugu) {
    final regionLabel = isTelugu
        ? (RecipeRegions.telugu[widget.recipe.region] ?? widget.recipe.region)
        : widget.recipe.region;

    final categoryLabel = isTelugu
        ? (RecipeCategories.telugu[widget.recipe.category] ??
            widget.recipe.category)
        : widget.recipe.category;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Veg/non-veg
        _tag(
          icon: widget.recipe.isVegetarian
              ? Icons.eco_rounded
              : Icons.set_meal_rounded,
          label: widget.recipe.isVegetarian
              ? (isTelugu ? 'శాకాహారం' : 'Vegetarian')
              : (isTelugu ? 'మాంసాహారం' : 'Non-Veg'),
          color:
              widget.recipe.isVegetarian ? const Color(0xFF2E7D32) : Colors.red,
        ),
        // Region — uses model's regionColor
        _tag(
          label: regionLabel,
          color: widget.recipe.regionColor,
        ),
        // Category — uses model's categoryColor
        _tag(
          icon: widget.recipe.categoryIcon,
          label: categoryLabel,
          color: widget.recipe.categoryColor,
        ),
        // Difficulty — uses model's difficultyColor
        _tag(
          icon: widget.recipe.difficultyIcon,
          label: isTelugu
              ? (RecipeDifficulty.telugu[widget.recipe.difficulty] ??
                  widget.recipe.difficulty)
              : widget.recipe.difficulty,
          color: widget.recipe.difficultyColor,
        ),
      ],
    );
  }

  Widget _tag({
    required String label,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ── Description ────────────────────────────────────────────────────────────

  Widget _buildDescription(bool isTelugu, bool isTablet) {
    return Text(
      isTelugu ? widget.recipe.descriptionTe : widget.recipe.description,
      style: TextStyle(
        fontSize: isTablet ? 18 : 15,
        color: Colors.grey.shade700,
        height: 1.6,
      ),
    );
  }

  // ── Info Cards ─────────────────────────────────────────────────────────────

  Widget _buildInfoCards(AppLocalizations l10n, bool isTablet) {
    final List<(IconData, String, String, Color)> items = [
      (
        Icons.timer_rounded,
        widget.recipe.cookTimeDisplay,
        l10n.cookTime,
        Colors.blue
      ),
      (Icons.people_rounded, '$_currentServings', l10n.servings, Colors.purple),
      (Icons.star_rounded, widget.recipe.ratingDisplay, 'Rating', Colors.amber),
    ];

    return Row(
      children: items.map((item) {
        final icon = item.$1;
        final value = item.$2;
        final label = item.$3;
        final color = item.$4;
        return Expanded(
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 16 : 12),
              child: Column(
                children: [
                  Icon(icon, color: color, size: isTablet ? 28 : 24),
                  SizedBox(height: isTablet ? 8 : 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isTablet ? 18 : 16,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: isTablet ? 13 : 11,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Nutrition Bar ──────────────────────────────────────────────────────────

  Widget _buildNutritionBar(bool isTelugu) {
    final r = widget.recipe;
    // Scale nutrition by current servings multiplier
    final cal = (r.calories * _multiplier).round();
    final protein = (r.protein * _multiplier);
    final carbs = (r.carbs * _multiplier);
    final fat = (r.fat * _multiplier);
    final total = protein + carbs + fat;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isTelugu ? 'పోషకాలు' : 'Nutrition',
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              Text(
                isTelugu ? 'సర్వింగ్ కి $cal కేలరీలు' : '$cal cal per serving',
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stacked bar
          if (total > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Row(
                children: [
                  Flexible(
                    flex: (protein / total * 100).round(),
                    child: Container(height: 10, color: Colors.red.shade400),
                  ),
                  Flexible(
                    flex: (carbs / total * 100).round(),
                    child: Container(height: 10, color: Colors.green.shade400),
                  ),
                  Flexible(
                    flex: (fat / total * 100).round(),
                    child: Container(height: 10, color: Colors.blue.shade400),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _nutritionLegend(isTelugu ? 'ప్రోటీన్' : 'Protein',
                  '${protein.toStringAsFixed(1)}g', Colors.red.shade400),
              _nutritionLegend(isTelugu ? 'కార్బ్స్' : 'Carbs',
                  '${carbs.toStringAsFixed(1)}g', Colors.green.shade400),
              _nutritionLegend(isTelugu ? 'కొవ్వు' : 'Fat',
                  '${fat.toStringAsFixed(1)}g', Colors.blue.shade400),
            ],
          ),
        ],
      ),
    );
  }

  Widget _nutritionLegend(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            Text(label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
          ],
        ),
      ],
    );
  }

  // ── Servings Adjuster ──────────────────────────────────────────────────────

  Widget _buildServingsAdjuster(bool isTelugu, bool isTablet) {
    return Card(
      elevation: 3,
      color: Colors.orange.shade50,
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        child: Column(
          children: [
            Text(
              isTelugu ? 'ఎంత మందికి వండాలి?' : 'How many people?',
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _servingsButton(
                  Icons.remove_rounded,
                  _currentServings > 1
                      ? () => _updateServings(_currentServings - 1)
                      : null,
                ),
                const SizedBox(width: 20),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Container(
                    key: ValueKey(_currentServings),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.orange.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.1),
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
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                _servingsButton(
                  Icons.add_rounded,
                  _currentServings < _maxServings
                      ? () => _updateServings(_currentServings + 1)
                      : null,
                ),
              ],
            ),
            if (_multiplier != 1.0) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isTelugu
                      ? 'పదార్థాలు ${_multiplier.toStringAsFixed(1)}x కు సర్దుబాటు అయ్యాయి'
                      : 'Quantities adjusted ${_multiplier.toStringAsFixed(1)}×',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _servingsButton(IconData icon, VoidCallback? onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(12),
        backgroundColor:
            onPressed != null ? Colors.orange.shade800 : Colors.grey.shade300,
        foregroundColor: Colors.white,
        elevation: onPressed != null ? 2 : 0,
      ),
      child: Icon(icon, size: 24),
    );
  }

  // ── Ingredients & Instructions Tabs ───────────────────────────────────────

  Widget _buildIngredientsAndInstructions(
    AppLocalizations l10n,
    bool isTelugu,
    bool isTablet,
  ) {
    return Column(
      children: [
        // Tab bar
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: Colors.orange.shade800,
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey.shade600,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700),
            tabs: [
              Tab(text: isTelugu ? 'పదార్థాలు' : 'Ingredients'),
              Tab(text: isTelugu ? 'తయారీ విధానం' : 'Instructions'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Tab content — fixed height to avoid unbounded scroll
        SizedBox(
          height: _tabContentHeight(isTelugu),
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildIngredientsList(isTelugu, isTablet),
              _buildInstructionsList(isTelugu, isTablet),
            ],
          ),
        ),
      ],
    );
  }

  // Estimate height so the TabBarView has a bounded constraint
  double _tabContentHeight(bool isTelugu) {
    final ingredientCount = widget.recipe.ingredients.length;
    final instructionCount = widget.recipe.instructions.length;
    final maxCount =
        ingredientCount > instructionCount ? ingredientCount : instructionCount;
    // ~72px per row (48px image + padding), +44px for download bar, min 350, max 700
    final ingredientHeight = widget.recipe.ingredients.length * 72.0 + 44.0;
    final instructionHeight = widget.recipe.instructions.length * 72.0;
    final maxHeight = ingredientHeight > instructionHeight
        ? ingredientHeight
        : instructionHeight;
    return maxHeight.clamp(350.0, 700.0);
  }

  // ── Ingredients List ───────────────────────────────────────────────────────

  Widget _buildIngredientsList(bool isTelugu, bool isTablet) {
    final ingredients = _adjustedIngredients(isTelugu);
    // Use unscaled English list for image lookup — quantities are irrelevant for images
    final englishIngredients = widget.recipe.ingredients;
    final isAdjusted = _multiplier != 1.0;

    return Column(
      children: [
        // ── Download bar ──────────────────────────────────────────────────
        _buildDownloadBar(isTelugu, ingredients),
        const SizedBox(height: 8),

        // ── Ingredient list wrapped in RepaintBoundary for screenshot ─────
        RepaintBoundary(
          key: _ingredientBoundaryKey,
          child: Card(
            elevation: 2,
            color: Colors.white,
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: const EdgeInsets.all(12),
              itemCount: ingredients.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (_, i) => IngredientTile(
                rawIngredient: ingredients[i],
                englishRaw: i < englishIngredients.length
                    ? englishIngredients[i]
                    : null,
                isAdjusted: isAdjusted,
                isTablet: isTablet,
                imageSize: isTablet ? 56 : 48,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadBar(bool isTelugu, List<String> ingredients) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Text download
        _DownloadChip(
          icon: Icons.text_snippet_outlined,
          label: isTelugu ? 'టెక్స్ట్' : 'Text',
          onTap: () async {
            try {
              await IngredientDownloadService.instance.shareAsText(
                recipe: widget.recipe,
                ingredients: ingredients,
                isTelugu: isTelugu,
              );
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      isTelugu ? 'షేర్ చేయడం విఫలమైంది' : 'Share failed: $e'),
                ));
              }
            }
          },
        ),
        const SizedBox(width: 8),
        // Image download
        _DownloadChip(
          icon: Icons.image_outlined,
          label: isTelugu ? 'చిత్రం' : 'Image',
          onTap: () async {
            try {
              await IngredientDownloadService.instance.shareAsImage(
                boundaryKey: _ingredientBoundaryKey,
                recipeTitle:
                    isTelugu ? widget.recipe.titleTe : widget.recipe.title,
                isTelugu: isTelugu,
              );
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(isTelugu
                      ? 'చిత్రం సేవ్ చేయడం విఫలమైంది'
                      : 'Image save failed: $e'),
                ));
              }
            }
          },
        ),
      ],
    );
  }

  // ── Instructions List ──────────────────────────────────────────────────────

  Widget _buildInstructionsList(bool isTelugu, bool isTablet) {
    final instructions =
        isTelugu ? widget.recipe.instructionsTe : widget.recipe.instructions;

    return Card(
      elevation: 2,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.all(12),
        itemCount: instructions.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (context, i) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step circle
                Container(
                  width: isTablet ? 32 : 28,
                  height: isTablet ? 32 : 28,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade800,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                // Connector line (except last item)
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTelugu ? 'దశ ${i + 1}' : 'Step ${i + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        instructions[i],
                        style: TextStyle(
                          fontSize: isTablet ? 17 : 15,
                          height: 1.5,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Start Cooking Button ───────────────────────────────────────────────────

  Widget _buildStartCookingButton(AppLocalizations l10n, bool isTablet) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CookingModeScreen(
              recipe: widget.recipe,
              learningRepo: ServiceLocator.instance.learningRepo,
            ),
          ),
        ),
        icon: const Icon(Icons.play_arrow_rounded),
        label: Text(
          l10n.startCooking,
          style: TextStyle(
            fontSize: isTablet ? 20 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.orange.shade800,
          padding: EdgeInsets.symmetric(vertical: isTablet ? 20 : 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _toggleFavorite(BuildContext context, bool isFavorite, bool isTelugu) {
    context.read<RecipeBloc>().add(ToggleFavorite(widget.recipe.id));
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
          onPressed: () =>
              context.read<RecipeBloc>().add(ToggleFavorite(widget.recipe.id)),
        ),
      ),
    );
  }

  void _shareRecipe(bool isTelugu) {
    final title = isTelugu ? widget.recipe.titleTe : widget.recipe.title;
    final region = widget.recipe.region;
    final time = widget.recipe.cookTimeDisplay;
    final text = isTelugu
        ? '$title — $region | సమయం: $time | రుచి యాప్ 🍛'
        : '$title — $region | Cook time: $time | Ruchi App 🍛';
    Share.share(text, subject: title);
  }
}

// ── Download chip ─────────────────────────────────────────────────────────────

class _DownloadChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DownloadChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: Colors.orange.shade800),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
