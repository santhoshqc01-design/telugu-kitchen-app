import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
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
  final GlobalKey _ingredientBoundaryKey = GlobalKey();
  static const int _maxServings = 20;

  // Fixed brand orange — consistent across ALL recipes, no dynamic palette
  static const Color _accent = Color(0xFFE65100); // orange.shade800

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

  void _updateServings(int newServings) {
    if (newServings < 1 || newServings > _maxServings) return;
    setState(() {
      _currentServings = newServings;
      _multiplier = newServings / widget.recipe.servings;
    });
  }

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTelugu = context.watch<LanguageBloc>().state.isTelugu;
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Colors.white, // FIX 5: pure white background
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
                  _buildInfoCards(l10n, isTelugu, isTablet),
                  const SizedBox(height: 16),
                  _buildNutritionBar(isTelugu),
                  const SizedBox(height: 20),
                  _buildServingsAdjuster(isTelugu, isTablet),
                  const SizedBox(height: 24),
                  _buildIngredientsAndInstructions(l10n, isTelugu, isTablet),
                  const SizedBox(height: 24),
                  _buildStartCookingButton(l10n, isTablet),
                  // FIX: safe area padding so content never bleeds into system nav
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sliver App Bar ─────────────────────────────────────────────────────────
  // FIX 1: 4-stop gradient, white title, stronger shadows

  Widget _buildSliverAppBar(bool isTelugu, bool isTablet) {
    return SliverAppBar(
      expandedHeight: isTablet ? 350 : 280,
      pinned: true,
      backgroundColor: _accent,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          isTelugu ? widget.recipe.titleTe : widget.recipe.title,
          style: TextStyle(
            fontSize: isTablet ? 24 : 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            // shadows: [
            //   Shadow(
            //       blurRadius: 6, color: Colors.black87, offset: Offset(0, 2)),
            //   Shadow(
            //       blurRadius: 18, color: Colors.black54, offset: Offset(0, 0)),
            // ],
          ),
        ),
        background: Hero(
          tag: 'recipe-${widget.recipe.id}',
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: widget.recipe.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(color: Colors.white),
                ),
                errorWidget: (context, url, error) => Container(
                  color: widget.recipe.regionColor.withValues(alpha: 0.15),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant_menu_rounded,
                          size: 80,
                          color:
                              widget.recipe.regionColor.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Text(isTelugu ? 'చిత్రం లేదు' : 'No Image',
                          style: TextStyle(
                              color: widget.recipe.regionColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              // FIX 1: Stronger 4-stop gradient
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Color(0x99000000),
                      Color(0xDD000000),
                    ],
                    stops: [0.0, 0.45, 0.75, 1.0],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_rounded, color: Colors.white),
          onPressed: () => _shareRecipe(isTelugu),
          tooltip: isTelugu ? 'షేర్ చేయి' : 'Share',
        ),
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
        _tag(label: regionLabel, color: widget.recipe.regionColor),
        _tag(
            icon: widget.recipe.categoryIcon,
            label: categoryLabel,
            color: widget.recipe.categoryColor),
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

  Widget _tag({required String label, required Color color, IconData? icon}) {
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
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 12)),
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
          height: 1.6),
    );
  }

  // ── Info Cards ─────────────────────────────────────────────────────────────
  // FIX 2: Accent-colored circular icon, white card, accent shadow

  Widget _buildInfoCards(AppLocalizations l10n, bool isTelugu, bool isTablet) {
    final List<(IconData, String, String)> items = [
      (Icons.timer_rounded, widget.recipe.cookTimeDisplay, l10n.cookTime),
      (Icons.people_rounded, '$_currentServings', l10n.servings),
      (
        Icons.star_rounded,
        widget.recipe.ratingDisplay,
        isTelugu ? 'రేటింగ్' : 'Rating'
      ),
    ];

    return Row(
      children: items.map((item) {
        final (icon, value, label) = item;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: EdgeInsets.symmetric(
                vertical: isTablet ? 16 : 14, horizontal: isTablet ? 12 : 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _accent.withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(
                    color: _accent.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: _accent, size: isTablet ? 22 : 20),
                ),
                SizedBox(height: isTablet ? 8 : 6),
                Text(value,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: isTablet ? 18 : 16,
                        color: Colors.grey.shade900)),
                Text(label,
                    style: TextStyle(
                        fontSize: isTablet ? 12 : 11,
                        color: Colors.grey.shade500),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Nutrition Bar ──────────────────────────────────────────────────────────
  // FIX 5: White card, accent calorie pill

  Widget _buildNutritionBar(bool isTelugu) {
    final r = widget.recipe;
    final cal = (r.calories * _multiplier).round();
    final protein = r.protein * _multiplier;
    final carbs = r.carbs * _multiplier;
    final fat = r.fat * _multiplier;
    final total = protein + carbs + fat;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isTelugu ? 'పోషకాలు' : 'Nutrition',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isTelugu ? 'సర్వింగ్ కి $cal కేలరీలు' : '$cal cal / serving',
                  style: const TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (total > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Flexible(
                      flex: (protein / total * 100).round(),
                      child: Container(height: 12, color: Colors.red.shade400)),
                  Flexible(
                      flex: (carbs / total * 100).round(),
                      child:
                          Container(height: 12, color: Colors.green.shade400)),
                  Flexible(
                      flex: (fat / total * 100).round(),
                      child:
                          Container(height: 12, color: Colors.blue.shade400)),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
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
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
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
  // FIX 3: White card with accent border, orange filled circle buttons

  Widget _buildServingsAdjuster(bool isTelugu, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
              color: _accent.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle),
                child:
                    const Icon(Icons.people_rounded, color: _accent, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                isTelugu ? 'ఎంత మందికి వండాలి?' : 'How many people?',
                style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _servingsButton(
                  Icons.remove_rounded,
                  _currentServings > 1
                      ? () => _updateServings(_currentServings - 1)
                      : null),
              const SizedBox(width: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Container(
                  key: ValueKey(_currentServings),
                  width: 80,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: _accent.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Text('$_currentServings',
                          style: TextStyle(
                              fontSize: isTablet ? 30 : 28,
                              fontWeight: FontWeight.w900,
                              color: _accent),
                          textAlign: TextAlign.center),
                      Text(
                        isTelugu
                            ? (_currentServings == 1 ? 'వ్యక్తి' : 'మంది')
                            : (_currentServings == 1 ? 'person' : 'people'),
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              _servingsButton(
                  Icons.add_rounded,
                  _currentServings < _maxServings
                      ? () => _updateServings(_currentServings + 1)
                      : null),
            ],
          ),
          if (_multiplier != 1.0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(
                isTelugu
                    ? 'పదార్థాలు ${_multiplier.toStringAsFixed(1)}x కు సర్దుబాటు అయ్యాయి'
                    : 'Quantities adjusted ${_multiplier.toStringAsFixed(1)}×',
                style: const TextStyle(
                    fontSize: 12, color: _accent, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // FIX 3: Material circle buttons with orange fill and elevation
  Widget _servingsButton(IconData icon, VoidCallback? onPressed) {
    return Material(
      color: onPressed != null ? _accent : Colors.grey.shade200,
      shape: const CircleBorder(),
      elevation: onPressed != null ? 3 : 0,
      shadowColor: _accent.withValues(alpha: 0.4),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Icon(icon,
              size: 22,
              color: onPressed != null ? Colors.white : Colors.grey.shade400),
        ),
      ),
    );
  }

  // ── Ingredients & Instructions Tabs ───────────────────────────────────────
  // FIX 4: Orange filled active pill, FIX 5: Orange section header bar

  Widget _buildIngredientsAndInstructions(
      AppLocalizations l10n, bool isTelugu, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // FIX 5: Section header with orange left bar
        Row(
          children: [
            Container(
              width: 4,
              height: 22,
              decoration: BoxDecoration(
                  color: _accent, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 8),
            Text(
              isTelugu ? 'రెసిపీ వివరాలు' : 'Recipe Details',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade800),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // FIX 4: Tab toggle with orange active pill + shadow
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              _tabToggle(0, isTelugu ? 'పదార్థాలు' : 'Ingredients'),
              _tabToggle(1, isTelugu ? 'తయారీ విధానం' : 'Instructions'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        IndexedStack(
          index: _tabController.index,
          children: [
            _buildIngredientsList(isTelugu, isTablet),
            _buildInstructionsList(isTelugu, isTablet),
          ],
        ),
      ],
    );
  }

  Widget _tabToggle(int index, String label) {
    final isSelected = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabController.index = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isSelected ? _accent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: _accent.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: isSelected ? Colors.white : Colors.grey.shade500,
            ),
          ),
        ),
      ),
    );
  }

  // ── Ingredients List ───────────────────────────────────────────────────────

  Widget _buildIngredientsList(bool isTelugu, bool isTablet) {
    final ingredients = _adjustedIngredients(isTelugu);
    final englishIngredients = widget.recipe.ingredients;
    final isAdjusted = _multiplier != 1.0;

    return Column(
      children: [
        _buildDownloadBar(isTelugu, ingredients),
        const SizedBox(height: 8),
        RepaintBoundary(
          key: _ingredientBoundaryKey,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: AnimationLimiter(
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.all(12),
                itemCount: ingredients.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (_, i) => AnimationConfiguration.staggeredList(
                  position: i,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: IngredientTile(
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
        _DownloadChip(
          icon: Icons.text_snippet_outlined,
          label: isTelugu ? 'టెక్స్ట్' : 'Text',
          onTap: () async {
            try {
              await IngredientDownloadService.instance.shareAsText(
                  recipe: widget.recipe,
                  ingredients: ingredients,
                  isTelugu: isTelugu);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(isTelugu
                        ? 'షేర్ చేయడం విఫలమైంది'
                        : 'Share failed: $e')));
              }
            }
          },
        ),
        const SizedBox(width: 8),
        _DownloadChip(
          icon: Icons.image_outlined,
          label: isTelugu ? 'చిత్రం' : 'Image',
          onTap: () async {
            try {
              await IngredientDownloadService.instance.shareAsImage(
                  boundaryKey: _ingredientBoundaryKey,
                  recipeTitle:
                      isTelugu ? widget.recipe.titleTe : widget.recipe.title,
                  isTelugu: isTelugu);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(isTelugu
                        ? 'చిత్రం సేవ్ చేయడం విఫలమైంది'
                        : 'Image save failed: $e')));
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: AnimationLimiter(
        child: ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: const EdgeInsets.all(12),
          itemCount: instructions.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: Colors.grey.shade100),
          itemBuilder: (context, i) => AnimationConfiguration.staggeredList(
            position: i,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: isTablet ? 32 : 28,
                        height: isTablet ? 32 : 28,
                        decoration: BoxDecoration(
                          color: _accent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: _accent.withValues(alpha: 0.35),
                                blurRadius: 4,
                                offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Center(
                          child: Text('${i + 1}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isTelugu ? 'దశ ${i + 1}' : 'Step ${i + 1}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: _accent,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 3),
                            Text(instructions[i],
                                style: TextStyle(
                                    fontSize: isTablet ? 17 : 15,
                                    height: 1.55,
                                    color: Colors.grey.shade800)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
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
                    ))),
        icon: const Icon(Icons.play_arrow_rounded),
        label: Text(l10n.startCooking,
            style: TextStyle(
                fontSize: isTablet ? 20 : 18, fontWeight: FontWeight.bold)),
        style: FilledButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: isTablet ? 20 : 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          shadowColor: _accent.withValues(alpha: 0.5),
          elevation: 4,
        ),
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _toggleFavorite(BuildContext context, bool isFavorite, bool isTelugu) {
    context.read<RecipeBloc>().add(ToggleFavorite(widget.recipe.id));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(isFavorite
          ? (isTelugu
              ? 'ఇష్టమైనవాటి నుండి తీసివేయబడింది'
              : 'Removed from favorites')
          : (isTelugu ? 'ఇష్టమైనవాటిలో చేర్చబడింది' : 'Added to favorites')),
      duration: const Duration(seconds: 2),
      action: SnackBarAction(
        label: isTelugu ? 'రద్దు' : 'Undo',
        onPressed: () =>
            context.read<RecipeBloc>().add(ToggleFavorite(widget.recipe.id)),
      ),
    ));
  }

  void _shareRecipe(bool isTelugu) {
    final title = isTelugu ? widget.recipe.titleTe : widget.recipe.title;
    Share.share(
      '$title — ${widget.recipe.region} | ${widget.recipe.cookTimeDisplay} | Ruchi App 🍛',
      subject: title,
    );
  }
}

// ── Download chip ─────────────────────────────────────────────────────────────

class _DownloadChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DownloadChip(
      {required this.icon, required this.label, required this.onTap});

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
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
