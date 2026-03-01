import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../blocs/recipe/recipe_bloc.dart';
import '../blocs/language/language_bloc.dart';
import '../l10n/app_localizations.dart';
import '../models/recipe_model.dart';
import 'recipe_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  /// Called when user taps "Browse Recipes" on the empty-state screen.
  /// HomeScreen passes a callback that switches the bottom nav to tab 0.
  final VoidCallback? onBrowse;
  const FavoritesScreen({super.key, this.onBrowse});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim()),
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: isTelugu
                    ? 'ఇష్టమైనవాటిోల్ వెతకండి...'
                    : 'Search favorites...',
                hintStyle:
                    TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                prefixIcon: Icon(Icons.search_rounded,
                    color: Colors.white.withValues(alpha: 0.8)),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: Colors.white70),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.15),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
        actions: [
          // Sort favorites
          BlocBuilder<RecipeBloc, RecipeState>(
            builder: (context, state) {
              if (state is! RecipeLoaded || state.favoriteCount == 0) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.sort_rounded),
                tooltip: isTelugu ? 'క్రమపద్ధతి' : 'Sort',
                onPressed: () => _showSortOptions(context, isTelugu),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<RecipeBloc, RecipeState>(
        builder: (context, state) {
          // RecipeBloc not yet loaded
          if (state is RecipeLoading || state is RecipeInitial) {
            return _buildShimmerList();
          }

          if (state is RecipeLoaded) {
            final allFavorites = state.favoriteRecipes;

            // Apply search filter
            final favorites = _query.isEmpty
                ? allFavorites
                : allFavorites.where((r) {
                    final q = _query.toLowerCase();
                    return r.title.toLowerCase().contains(q) ||
                        r.titleTe.contains(q) ||
                        r.category.toLowerCase().contains(q) ||
                        r.region.toLowerCase().contains(q);
                  }).toList();

            if (allFavorites.isEmpty) {
              return _buildEmptyState(context, isTelugu);
            }

            if (favorites.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off_rounded,
                        size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      isTelugu
                          ? '"$_query" కు పోలికలు లేవు'
                          : 'No favorites match "$_query"',
                      style:
                          TextStyle(fontSize: 16, color: Colors.grey.shade500),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {},
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                itemCount: favorites.length,
                itemBuilder: (context, i) => _FavoriteCard(
                  recipe: favorites[i],
                  isTelugu: isTelugu,
                ),
              ),
            );
          }

          // Error state
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  isTelugu ? 'లోపం జరిగింది' : 'Something went wrong',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () =>
                      context.read<RecipeBloc>().add(const LoadRecipes()),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(isTelugu ? 'మళ్ళీ ప్రయత్నించండి' : 'Retry'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context, bool isTelugu) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pulsing heart
            _PulsingHeart(),
            const SizedBox(height: 24),
            Text(
              isTelugu ? 'ఇంకా ఇష్టమైనవి లేవు' : 'No favorites yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isTelugu
                  ? 'వంటకాలపై గుండె బటన్ నొక్కి మీకు నచ్చినవి ఇక్కడ చేర్చండి'
                  : 'Tap the heart on any recipe to save it here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: widget.onBrowse,
              icon: const Icon(Icons.explore_rounded),
              label: Text(isTelugu ? 'వంటకాలను చూడండి' : 'Browse Recipes'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange.shade800,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shimmer Loading ────────────────────────────────────────────────────────

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 16, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(height: 12, width: 120, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(height: 12, width: 80, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Sort Options ───────────────────────────────────────────────────────────

  void _showSortOptions(BuildContext context, bool isTelugu) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              isTelugu ? 'క్రమపద్ధతి' : 'Sort favorites',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.star_rounded, color: Colors.amber),
              title: Text(isTelugu ? 'టాప్ రేటెడ్' : 'Top Rated'),
              onTap: () {
                Navigator.pop(context);
                context
                    .read<RecipeBloc>()
                    .add(const SortRecipes(RecipeSortOrder.topRated));
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer_rounded, color: Colors.blue),
              title: Text(isTelugu ? 'త్వరగా' : 'Quickest first'),
              onTap: () {
                Navigator.pop(context);
                context
                    .read<RecipeBloc>()
                    .add(const SortRecipes(RecipeSortOrder.quickestFirst));
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha_rounded),
              title: Text(isTelugu ? 'A-Z క్రమం' : 'Alphabetical'),
              onTap: () {
                Navigator.pop(context);
                context
                    .read<RecipeBloc>()
                    .add(const SortRecipes(RecipeSortOrder.alphabetical));
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Favorite Card (stateful for dismiss animation) ───────────────────────────

class _FavoriteCard extends StatelessWidget {
  final Recipe recipe;
  final bool isTelugu;

  const _FavoriteCard({required this.recipe, required this.isTelugu});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('fav-${recipe.id}'),
      direction: DismissDirection.endToStart,
      // Confirm before removing
      confirmDismiss: (_) => _confirmRemove(context),
      onDismissed: (_) => _remove(context, showUndo: true),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
            const SizedBox(height: 4),
            Text(
              isTelugu ? 'తొలగించు' : 'Remove',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
          ],
        ),
      ),
      child: Hero(
        tag: 'favorite-${recipe.id}',
        child: Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => RecipeDetailScreen(recipe: recipe)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _buildThumbnail(),
                  const SizedBox(width: 14),
                  Expanded(child: _buildInfo(context)),
                  _buildFavButton(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Thumbnail ──────────────────────────────────────────────────────────────

  Widget _buildThumbnail() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: CachedNetworkImage(
        imageUrl: recipe.imageUrl,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            width: 80,
            height: 80,
            color: Colors.white,
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: 80,
          height: 80,
          color: recipe.regionColor.withValues(alpha: 0.15),
          child: Center(
            child: Icon(
              Icons.restaurant_rounded,
              color: recipe.regionColor.withValues(alpha: 0.5),
              size: 32,
            ),
          ),
        ),
      ),
    );
  }

  // ── Info Column ────────────────────────────────────────────────────────────

  Widget _buildInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Veg dot + title row
        Row(
          children: [
            // Indian-standard veg/non-veg dot
            Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                  color: recipe.isVegetarian
                      ? const Color(0xFF2E7D32)
                      : Colors.red,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: recipe.isVegetarian
                        ? const Color(0xFF2E7D32)
                        : Colors.red,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Text(
                isTelugu ? recipe.titleTe : recipe.title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Region chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: recipe.regionColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            isTelugu
                ? (RecipeRegions.telugu[recipe.region] ?? recipe.region)
                : recipe.region,
            style: TextStyle(
              fontSize: 10,
              color: recipe.regionColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Stats row — uses model computed properties
        Row(
          children: [
            _stat(Icons.timer_rounded, recipe.cookTimeShort, Colors.grey),
            const SizedBox(width: 12),
            _stat(Icons.star_rounded, recipe.ratingDisplay, Colors.amber),
            const SizedBox(width: 12),
            _stat(
              recipe.difficultyIcon,
              isTelugu
                  ? (RecipeDifficulty.telugu[recipe.difficulty] ??
                      recipe.difficulty)
                  : recipe.difficulty,
              recipe.difficultyColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _stat(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(value,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  // ── Favorite Button ────────────────────────────────────────────────────────

  Widget _buildFavButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.favorite_rounded, color: Colors.red, size: 22),
      tooltip: isTelugu ? 'తొలగించు' : 'Remove',
      onPressed: () => _confirmAndRemove(context),
    );
  }

  // ── Remove Helpers ─────────────────────────────────────────────────────────

  Future<bool?> _confirmRemove(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isTelugu ? 'తొలగించాలా?' : 'Remove favorite?'),
        content: Text(
          isTelugu
              ? '${recipe.titleTe} ని ఇష్టమైనవాటి నుండి తొలగించాలా?'
              : 'Remove "${recipe.title}" from your favorites?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isTelugu ? 'రద్దు' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              isTelugu ? 'తొలగించు' : 'Remove',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndRemove(BuildContext context) async {
    final confirmed = await _confirmRemove(context);
    if (confirmed == true && context.mounted) {
      _remove(context, showUndo: true);
    }
  }

  void _remove(BuildContext context, {bool showUndo = false}) {
    context.read<RecipeBloc>().add(ToggleFavorite(recipe.id));
    if (showUndo) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isTelugu
                ? '${recipe.titleTe} తొలగించబడింది'
                : '"${recipe.title}" removed',
          ),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: isTelugu ? 'రద్దు' : 'Undo',
            onPressed: () =>
                context.read<RecipeBloc>().add(ToggleFavorite(recipe.id)),
          ),
        ),
      );
    }
  }
}

// ─── Pulsing Heart Widget ─────────────────────────────────────────────────────

class _PulsingHeart extends StatefulWidget {
  @override
  State<_PulsingHeart> createState() => _PulsingHeartState();
}

class _PulsingHeartState extends State<_PulsingHeart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Icon(
        Icons.favorite_border_rounded,
        size: 96,
        color: Colors.grey.shade300,
      ),
    );
  }
}
