import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import '../blocs/language/language_bloc.dart';
import '../blocs/recipe/recipe_bloc.dart';
import '../blocs/voice/voice_bloc.dart';
import '../l10n/app_localizations.dart';
import '../models/recipe_model.dart';
import '../screens/recipe_detail_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    context.read<VoiceBloc>().add(const InitializeVoice());
    context.read<RecipeBloc>().add(const LoadRecipes());
    // Rebuild when search text changes so clear button shows/hides
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Debounce: fires after 400ms idle; triggers on empty string too (clear)
  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<RecipeBloc>().add(SearchRecipes(value));
    });
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<RecipeBloc>().add(const SearchRecipes(''));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTelugu = context.watch<LanguageBloc>().state.isTelugu;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(l10n, isTelugu),
          const FavoritesScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildNavBar(l10n),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () => _showVoiceSearch(context),
              backgroundColor: Colors.orange.shade800,
              child: const Icon(Icons.mic_rounded, color: Colors.white),
            )
          : null,
    );
  }

  // ── Nav Bar (with favorites badge) ────────────────────────────────────────

  Widget _buildNavBar(AppLocalizations l10n) {
    return BlocBuilder<RecipeBloc, RecipeState>(
      builder: (context, state) {
        final favCount = state is RecipeLoaded ? state.favoriteCount : 0;
        return NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: l10n.appName,
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: favCount > 0,
                label: Text('$favCount'),
                child: const Icon(Icons.favorite_outline_rounded),
              ),
              selectedIcon: Badge(
                isLabelVisible: favCount > 0,
                label: Text('$favCount'),
                child: const Icon(Icons.favorite_rounded),
              ),
              label: l10n.favorites,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings_rounded),
              label: l10n.settings,
            ),
          ],
        );
      },
    );
  }

  // ── Home Tab ───────────────────────────────────────────────────────────────

  Widget _buildHomeTab(AppLocalizations l10n, bool isTelugu) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<RecipeBloc>().add(const ClearFilters());
        _clearSearch();
      },
      child: CustomScrollView(
        slivers: [
          _buildSliverAppBar(isTelugu),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBar(l10n),
                  const SizedBox(height: 8),
                  _buildActiveFiltersRow(isTelugu),
                  const SizedBox(height: 20),
                  _buildCategories(l10n, isTelugu),
                  const SizedBox(height: 20),
                  _buildRegions(l10n, isTelugu),
                  const SizedBox(height: 20),
                  _buildSectionHeader(isTelugu),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
          _buildRecipeGrid(isTelugu),
          const SliverPadding(padding: EdgeInsets.only(bottom: 88)),
        ],
      ),
    );
  }

  // ── Sliver App Bar ─────────────────────────────────────────────────────────

  Widget _buildSliverAppBar(bool isTelugu) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: true,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          isTelugu ? 'రుచి' : 'Ruchi',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(blurRadius: 4, color: Colors.black45, offset: Offset(0, 2))
            ],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.orange.shade800, Colors.orange.shade600],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Center(
                child: Icon(
                  Icons.restaurant_menu_rounded,
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        // Sort button
        BlocBuilder<RecipeBloc, RecipeState>(
          builder: (context, state) {
            final sortOrder = state is RecipeLoaded
                ? state.sortOrder
                : RecipeSortOrder.defaultOrder;
            return IconButton(
              icon: const Icon(Icons.sort_rounded, color: Colors.white),
              tooltip: 'Sort',
              onPressed: () => _showSortSheet(context, sortOrder),
            );
          },
        ),
        // Filter button with active-filter badge
        BlocBuilder<RecipeBloc, RecipeState>(
          builder: (context, state) {
            final filterCount =
                state is RecipeLoaded ? state.activeFilterCount : 0;
            return Badge(
              isLabelVisible: filterCount > 0,
              label: Text('$filterCount'),
              child: IconButton(
                icon: const Icon(Icons.tune_rounded, color: Colors.white),
                tooltip: 'Filters',
                onPressed: () => _showFilterSheet(context),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Search Bar ─────────────────────────────────────────────────────────────

  Widget _buildSearchBar(AppLocalizations l10n) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: l10n.searchHint,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: _clearSearch,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
      onChanged: _onSearchChanged,
    );
  }

  // ── Active Filter Chips ────────────────────────────────────────────────────

  Widget _buildActiveFiltersRow(bool isTelugu) {
    return BlocBuilder<RecipeBloc, RecipeState>(
      builder: (context, state) {
        if (state is! RecipeLoaded || !state.hasActiveFilters) {
          return const SizedBox.shrink();
        }

        final chips = <Widget>[];

        if (state.selectedCategory != 'All') {
          chips.add(_filterChip(
            label: isTelugu
                ? (RecipeCategories.telugu[state.selectedCategory] ??
                    state.selectedCategory)
                : state.selectedCategory,
            onRemove: () =>
                context.read<RecipeBloc>().add(const FilterByCategory('All')),
          ));
        }

        if (state.selectedRegion != 'All') {
          chips.add(_filterChip(
            label: isTelugu
                ? (RecipeRegions.telugu[state.selectedRegion] ??
                    state.selectedRegion)
                : state.selectedRegion,
            onRemove: () =>
                context.read<RecipeBloc>().add(const FilterByRegion('All')),
          ));
        }

        if (state.selectedDifficulty != 'All') {
          chips.add(_filterChip(
            label: isTelugu
                ? (RecipeDifficulty.telugu[state.selectedDifficulty] ??
                    state.selectedDifficulty)
                : state.selectedDifficulty,
            onRemove: () =>
                context.read<RecipeBloc>().add(const FilterByDifficulty('All')),
          ));
        }

        if (state.vegetarianOnly) {
          chips.add(_filterChip(
            label: isTelugu ? 'శాకాహారం' : 'Veg only',
            color: const Color(0xFF2E7D32),
            onRemove: () =>
                context.read<RecipeBloc>().add(const ToggleVegetarian()),
          ));
        }

        if (state.maxCookTimeMinutes != null) {
          chips.add(_filterChip(
            label: '≤ ${state.maxCookTimeMinutes} min',
            onRemove: () =>
                context.read<RecipeBloc>().add(const FilterByMaxTime(null)),
          ));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...chips,
                  TextButton.icon(
                    onPressed: () {
                      context.read<RecipeBloc>().add(const ClearFilters());
                      _clearSearch();
                    },
                    icon: const Icon(Icons.close_rounded, size: 14),
                    label: Text(isTelugu ? 'అన్నీ తీయి' : 'Clear all'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                '${state.recipes.length} ${isTelugu ? "వంటకాలు" : "recipes found"}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _filterChip({
    required String label,
    required VoidCallback onRemove,
    Color? color,
  }) {
    final chipColor = color ?? Colors.orange.shade800;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        deleteIcon: const Icon(Icons.close_rounded, size: 14),
        onDeleted: onRemove,
        backgroundColor: chipColor.withValues(alpha: 0.12),
        deleteIconColor: chipColor,
        labelStyle: TextStyle(color: chipColor, fontWeight: FontWeight.w600),
        side: BorderSide(color: chipColor.withValues(alpha: 0.3)),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  // ── Categories ─────────────────────────────────────────────────────────────

  static const _categoryData = [
    (
      'Breakfast',
      Icons.free_breakfast_rounded,
      Color(0xFFF57F17),
      'ప్రాతః భోజనం'
    ),
    ('Lunch', Icons.lunch_dining_rounded, Color(0xFF2E7D32), 'మధ్యాహ్నం'),
    ('Dinner', Icons.dinner_dining_rounded, Color(0xFF1A237E), 'రాత్రి'),
    ('Snacks', Icons.fastfood_rounded, Color(0xFF880E4F), 'స్నాక్స్'),
    ('Desserts', Icons.cake_rounded, Color(0xFF4A148C), 'మిఠాయి'),
    ('Beverages', Icons.local_cafe_rounded, Color(0xFF006064), 'పానీయాలు'),
  ];

  Widget _buildCategories(AppLocalizations l10n, bool isTelugu) {
    return BlocBuilder<RecipeBloc, RecipeState>(
      builder: (context, state) {
        final selected = state is RecipeLoaded ? state.selectedCategory : 'All';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTelugu ? 'వర్గాలు' : 'Categories',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categoryData.length,
                itemBuilder: (context, i) {
                  final (name, icon, color, teluguName) = _categoryData[i];
                  final isSelected = selected == name;
                  final label = isTelugu
                      ? teluguName
                      : _getCategoryName(l10n, name.toLowerCase());

                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: SizedBox(
                      width: 80,
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => context.read<RecipeBloc>().add(
                                  FilterByCategory(isSelected ? 'All' : name),
                                ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? color
                                    : color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.35),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                icon,
                                color: isSelected ? Colors.white : color,
                                size: 32,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: isSelected
                                  ? color
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Regions ────────────────────────────────────────────────────────────────

  static const _regionData = [
    ('Andhra', Color(0xFFE65100), Color(0xFFFF7043), 'ఆంధ్ర'),
    ('Telangana', Color(0xFF880E4F), Color(0xFFAD1457), 'తెలంగాణ'),
    ('Rayalaseema', Color(0xFF1B5E20), Color(0xFF388E3C), 'రాయలసీమ'),
  ];

  Widget _buildRegions(AppLocalizations l10n, bool isTelugu) {
    return BlocBuilder<RecipeBloc, RecipeState>(
      builder: (context, state) {
        final selected = state is RecipeLoaded ? state.selectedRegion : 'All';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTelugu ? 'ప్రాంతాలు' : 'Regions',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              children: _regionData.map((r) {
                final (name, colorStart, colorEnd, teluguName) = r;
                final isSelected = selected == name;
                final label = isTelugu
                    ? teluguName
                    : _getRegionName(l10n, name.toLowerCase());

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => context.read<RecipeBloc>().add(
                            FilterByRegion(isSelected ? 'All' : name),
                          ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isSelected
                                ? [colorStart, colorEnd]
                                : [
                                    colorStart.withValues(alpha: 0.15),
                                    colorEnd.withValues(alpha: 0.15),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: colorStart.withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : null,
                        ),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? Colors.white : colorStart,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  // ── Section Header ─────────────────────────────────────────────────────────

  Widget _buildSectionHeader(bool isTelugu) {
    return BlocBuilder<RecipeBloc, RecipeState>(
      builder: (context, state) {
        final hasFilters = state is RecipeLoaded && state.hasActiveFilters;
        final count = state is RecipeLoaded ? state.recipes.length : 0;
        final isVeg = state is RecipeLoaded && state.vegetarianOnly;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasFilters
                      ? (isTelugu ? 'ఫలితాలు' : 'Results')
                      : (isTelugu ? 'అన్ని వంటకాలు' : 'All Recipes'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (state is RecipeLoaded && !hasFilters)
                  Text(
                    '$count ${isTelugu ? "వంటకాలు" : "recipes"}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            // Veg-only quick toggle
            FilterChip(
              label: Text(isTelugu ? 'శాకా' : 'Veg'),
              selected: isVeg,
              onSelected: (_) =>
                  context.read<RecipeBloc>().add(const ToggleVegetarian()),
              avatar: Icon(
                Icons.eco_rounded,
                size: 16,
                color: isVeg ? Colors.white : const Color(0xFF2E7D32),
              ),
              selectedColor: const Color(0xFF2E7D32),
              labelStyle: TextStyle(
                color: isVeg ? Colors.white : null,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              visualDensity: VisualDensity.compact,
            ),
          ],
        );
      },
    );
  }

  // ── Recipe Grid ────────────────────────────────────────────────────────────

  Widget _buildRecipeGrid(bool isTelugu) {
    return BlocBuilder<RecipeBloc, RecipeState>(
      builder: (context, state) {
        if (state is RecipeLoading) {
          return SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, __) => const ShimmerRecipeCard(),
                childCount: 6,
              ),
            ),
          );
        }

        if (state is RecipeLoaded) {
          if (state.recipes.isEmpty) {
            return SliverFillRemaining(
              child: _buildEmptyState(isTelugu, state.hasActiveFilters),
            );
          }

          return SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final recipe = state.recipes[index];
                  return RecipeCard(
                    recipe: recipe,
                    isFavorite: state.isFavorite(recipe.id),
                    isTelugu: isTelugu,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecipeDetailScreen(recipe: recipe),
                      ),
                    ),
                    onFavoriteToggle: () => context
                        .read<RecipeBloc>()
                        .add(ToggleFavorite(recipe.id)),
                  );
                },
                childCount: state.recipes.length,
              ),
            ),
          );
        }

        return SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                const Text('Error loading recipes'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () =>
                      context.read<RecipeBloc>().add(const LoadRecipes()),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isTelugu, bool hasFilters) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilters
                  ? Icons.filter_alt_off_rounded
                  : Icons.search_off_rounded,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters
                  ? (isTelugu ? 'వంటకాలు కనుగొనబడలేదు' : 'No recipes found')
                  : (isTelugu ? 'వంటకాలు లేవు' : 'No recipes'),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              isTelugu ? 'ఫిల్టర్లు తీసివేయండి' : 'Try removing some filters',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                context.read<RecipeBloc>().add(const ClearFilters());
                _clearSearch();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text(isTelugu ? 'అన్నీ తీయి' : 'Clear filters'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sort Sheet ─────────────────────────────────────────────────────────────

  void _showSortSheet(BuildContext context, RecipeSortOrder current) {
    final isTelugu = context.read<LanguageBloc>().state.isTelugu;

    final options = [
      (
        RecipeSortOrder.defaultOrder,
        isTelugu ? 'డిఫాల్ట్' : 'Default',
        Icons.list_rounded
      ),
      (
        RecipeSortOrder.topRated,
        isTelugu ? 'టాప్ రేటెడ్' : 'Top Rated',
        Icons.star_rounded
      ),
      (
        RecipeSortOrder.quickestFirst,
        isTelugu ? 'త్వరగా' : 'Quickest first',
        Icons.timer_rounded
      ),
      (
        RecipeSortOrder.alphabetical,
        isTelugu ? 'A-Z క్రమం' : 'Alphabetical',
        Icons.sort_by_alpha_rounded
      ),
    ];

    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              isTelugu ? 'క్రమపద్ధతి' : 'Sort by',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...options.map((o) {
              final (order, label, icon) = o;
              final isSelected = current == order;
              return ListTile(
                leading: Icon(icon,
                    color: isSelected ? Colors.orange.shade800 : null),
                title: Text(label),
                trailing: isSelected
                    ? Icon(Icons.check_rounded, color: Colors.orange.shade800)
                    : null,
                selected: isSelected,
                onTap: () {
                  Navigator.pop(context);
                  context.read<RecipeBloc>().add(SortRecipes(order));
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Filter Sheet ───────────────────────────────────────────────────────────

  void _showFilterSheet(BuildContext context) {
    final isTelugu = context.read<LanguageBloc>().state.isTelugu;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => BlocBuilder<RecipeBloc, RecipeState>(
          bloc: context.read<RecipeBloc>(),
          builder: (_, state) {
            if (state is! RecipeLoaded) return const SizedBox.shrink();

            return ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  isTelugu ? 'ఫిల్టర్లు' : 'Filters',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 20),

                // Difficulty
                Text(isTelugu ? 'కష్టం స్థాయి' : 'Difficulty',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['All', ...RecipeDifficulty.all].map((d) {
                    final label = d == 'All'
                        ? (isTelugu ? 'అన్నీ' : 'All')
                        : (isTelugu ? (RecipeDifficulty.telugu[d] ?? d) : d);
                    final isSelected = state.selectedDifficulty == d;
                    return FilterChip(
                      label: Text(label),
                      selected: isSelected,
                      onSelected: (_) =>
                          context.read<RecipeBloc>().add(FilterByDifficulty(d)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Cook time
                Text(isTelugu ? 'వంట సమయం' : 'Max cook time',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [null, 15, 30, 45, 60].map((mins) {
                    final label = mins == null
                        ? (isTelugu ? 'అన్నీ' : 'Any')
                        : '≤ $mins min';
                    final isSelected = state.maxCookTimeMinutes == mins;
                    return FilterChip(
                      label: Text(label),
                      selected: isSelected,
                      onSelected: (_) =>
                          context.read<RecipeBloc>().add(FilterByMaxTime(mins)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Veg toggle
                SwitchListTile(
                  title:
                      Text(isTelugu ? 'శాకాహారం మాత్రమే' : 'Vegetarian only'),
                  subtitle:
                      Text(isTelugu ? 'మాంసాహారం తీసివేయి' : 'Hide non-veg'),
                  secondary:
                      const Icon(Icons.eco_rounded, color: Color(0xFF2E7D32)),
                  value: state.vegetarianOnly,
                  onChanged: (_) =>
                      context.read<RecipeBloc>().add(const ToggleVegetarian()),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          context.read<RecipeBloc>().add(const ClearFilters());
                          _clearSearch();
                          Navigator.pop(context);
                        },
                        child: Text(isTelugu ? 'అన్నీ తీయి' : 'Clear all'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(isTelugu ? 'చూపించు' : 'Show results'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Voice Search ───────────────────────────────────────────────────────────

  void _showVoiceSearch(BuildContext context) {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<LanguageBloc>().state.isTelugu
                ? 'మొబైల్‌లో వాయిస్ సెర్చ్ పని చేస్తుంది'
                : 'Voice search works best on mobile. Please type your search.',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width - 32,
      ),
      builder: (_) => const VoiceSearchSheet(),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _getCategoryName(AppLocalizations l10n, String key) {
    switch (key) {
      case 'breakfast':
        return l10n.breakfast;
      case 'lunch':
        return l10n.lunch;
      case 'dinner':
        return l10n.dinner;
      case 'snacks':
        return l10n.snacks;
      case 'desserts':
        return l10n.desserts;
      case 'beverages':
        return l10n.beverages;
      default:
        return key;
    }
  }

  String _getRegionName(AppLocalizations l10n, String key) {
    switch (key) {
      case 'andhra':
        return l10n.andhra;
      case 'telangana':
        return l10n.telangana;
      case 'rayalaseema':
        return l10n.rayalaseema;
      default:
        return key;
    }
  }
}

// ─── String Extension ─────────────────────────────────────────────────────────

extension StringExtension on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

// ─── Shimmer Card ─────────────────────────────────────────────────────────────

class ShimmerRecipeCard extends StatelessWidget {
  const ShimmerRecipeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: Container(color: Colors.white)),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(height: 12, width: 60, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Recipe Card ──────────────────────────────────────────────────────────────

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final bool isFavorite;
  final bool isTelugu;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.isFavorite,
    required this.isTelugu,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'recipe-${recipe.id}',
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.orange.withValues(alpha: 0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildImage(),

                    // Region badge — color comes from recipe.regionColor (no duplication)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _badge(recipe.region, recipe.regionColor),
                    ),

                    // Favorite button
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        icon: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_outline_rounded,
                          color: isFavorite ? Colors.red : Colors.white,
                          size: 20,
                          shadows: const [
                            Shadow(blurRadius: 6, color: Colors.black54),
                          ],
                        ),
                        onPressed: onFavoriteToggle,
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                    ),

                    // Veg/non-veg indicator dot (Indian food standard)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: recipe.isVegetarian
                                ? const Color(0xFF2E7D32)
                                : Colors.red,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: recipe.isVegetarian
                                  ? const Color(0xFF2E7D32)
                                  : Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Difficulty badge — color from recipe.difficultyColor
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: _badge(recipe.difficulty, recipe.difficultyColor,
                          fontSize: 9),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTelugu ? recipe.titleTe : recipe.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          _stat(Icons.timer_rounded, recipe.cookTimeShort,
                              Colors.grey),
                          const SizedBox(width: 8),
                          _stat(Icons.star_rounded, recipe.ratingDisplay,
                              Colors.amber),
                          const SizedBox(width: 8),
                          _stat(Icons.local_fire_department_rounded,
                              '${recipe.calories}', Colors.orange),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Image.network(
      recipe.imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(color: Colors.white),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_rounded,
                size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: recipe.regionColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  recipe.titleTe.isNotEmpty
                      ? recipe.titleTe[0]
                      : recipe.title[0],
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: recipe.regionColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color, {double fontSize = 10}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── Voice Search Sheet ───────────────────────────────────────────────────────

class VoiceSearchSheet extends StatelessWidget {
  const VoiceSearchSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTelugu = context.watch<LanguageBloc>().state.isTelugu;
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 360;

    return Container(
      constraints: BoxConstraints(
        maxHeight: size.height * 0.5,
        minHeight: 300,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: isSmall ? 16 : 24),
            Text(
              l10n.voiceCommands,
              style: TextStyle(
                  fontSize: isSmall ? 20 : 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.speakNow,
              style: TextStyle(
                  fontSize: isSmall ? 14 : 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmall ? 24 : 32),
            BlocConsumer<VoiceBloc, VoiceState>(
              listener: (context, state) {
                if (state is VoiceSearchResult) {
                  Navigator.pop(context);
                  context.read<RecipeBloc>().add(SearchRecipes(state.text));
                }
                if (state is VoiceError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
              builder: (context, state) {
                final isListening = state is VoiceListening;
                final micSize = isSmall ? 100.0 : 120.0;

                return GestureDetector(
                  onTap: () {
                    if (isListening) {
                      context.read<VoiceBloc>().add(const StopListening());
                    } else {
                      context.read<VoiceBloc>().add(
                            StartListening(
                                localeId: isTelugu ? 'te_IN' : 'en_US'),
                          );
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: micSize,
                    height: micSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isListening ? Colors.red : Colors.orange,
                      boxShadow: [
                        BoxShadow(
                          color: (isListening ? Colors.red : Colors.orange)
                              .withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      size: isSmall ? 40.0 : 48.0,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: isSmall ? 16 : 24),
            Text(
              isTelugu ? 'ఉదాహరణలు:' : 'Examples:',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: (isTelugu
                      ? ['"బిర్యానీ"', '"గోంగూర"', '"ఉదయం భోజనం"']
                      : ['"Biryani"', '"Gongura"', '"Breakfast"'])
                  .map((t) => Chip(
                        label: Text(t, style: const TextStyle(fontSize: 12)),
                        backgroundColor: Colors.grey.shade100,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ))
                  .toList(),
            ),
            SizedBox(height: isSmall ? 16 : 24),
          ],
        ),
      ),
    );
  }
}
