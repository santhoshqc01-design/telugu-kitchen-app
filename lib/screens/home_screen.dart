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
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    context.read<VoiceBloc>().add(const InitializeVoice());
    context.read<RecipeBloc>().add(const LoadRecipes());
    // Rebuild when search text changes (clear button + suggestions)
    _searchController.addListener(() => setState(() {}));
    // Show suggestions when search field is focused
    _searchFocusNode.addListener(() {
      setState(() => _showSuggestions = _searchFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
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
    _searchFocusNode.unfocus();
    setState(() => _showSuggestions = false);
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
          FavoritesScreen(
            onBrowse: () => setState(() => _selectedIndex = 0),
          ),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildNavBar(l10n),
      // FAB removed — voice mic is now inside the search bar
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

  // Returns time-based greeting and emoji
  (String, String) _getGreeting(bool isTelugu) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return isTelugu ? ('శుభోదయం', '🌅') : ('Good Morning', '🌅');
    } else if (hour < 17) {
      return isTelugu ? ('శుభ మధ్యాహ్నం', '☀️') : ('Good Afternoon', '☀️');
    } else if (hour < 20) {
      return isTelugu ? ('శుభ సాయంత్రం', '🌇') : ('Good Evening', '🌇');
    } else {
      return isTelugu ? ('శుభ రాత్రి', '🌙') : ('Good Night', '🌙');
    }
  }

  Widget _buildSliverAppBar(bool isTelugu) {
    final (greeting, emoji) = _getGreeting(isTelugu);

    return SliverAppBar(
      expandedHeight: 240,
      floating: false,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.orange.shade800,
      // title: only appears in the collapsed app bar (when scrolled up).
      // Do NOT put a title inside FlexibleSpaceBar — Flutter renders it
      // over the background in expanded state too, causing double text.
      title: Text(
        isTelugu ? 'రుచి' : 'Ruchi',
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 20,
          letterSpacing: 0.5,
          color: Colors.white,
          shadows: [
            Shadow(blurRadius: 4, color: Colors.black38, offset: Offset(0, 2))
          ],
        ),
      ),
      // Hide the SliverAppBar title while expanded — it only shows when pinned/collapsed
      titleSpacing: 0,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        // Full expanded background
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFBF360C), // deep burnt orange
                Colors.orange.shade700,
                const Color(0xFFFF8F00), // amber
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // ── Decorative circles ────────────────────────────────────
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                left: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Positioned(
                top: 60,
                right: 20,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              // ── Content ───────────────────────────────────────────────
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Greeting row ──────────────────────────────────
                      Row(
                        children: [
                          Text(
                            '$emoji  $greeting',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // ── App name ──────────────────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'రుచి',
                            style: TextStyle(
                              fontSize: 46,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.0,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Ruchi',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.7),
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // ── Stats row ─────────────────────────────────────
                      BlocBuilder<RecipeBloc, RecipeState>(
                        builder: (context, state) {
                          if (state is! RecipeLoaded)
                            return const SizedBox.shrink();
                          final total = state.allRecipes.length;
                          final vegCount = state.allRecipes
                              .where((r) => r.isVegetarian)
                              .length;
                          final favCount = state.favoriteCount;
                          return Row(
                            children: [
                              _headerStat(
                                isTelugu ? '$total వంటకాలు' : '$total Recipes',
                                Icons.menu_book_rounded,
                              ),
                              _headerDot(),
                              _headerStat(
                                isTelugu ? '$vegCount శాక' : '$vegCount Veg',
                                Icons.eco_rounded,
                              ),
                              if (favCount > 0) ...[
                                _headerDot(),
                                _headerStat(
                                  isTelugu
                                      ? '$favCount ఇష్టమైన'
                                      : '$favCount Saved',
                                  Icons.favorite_rounded,
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ],
                  ),
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

  Widget _headerStat(String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.8)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.85),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _headerDot() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Container(
          width: 3,
          height: 3,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
      );

  // ── Search Bar ─────────────────────────────────────────────────────────────

  Widget _buildSearchBar(AppLocalizations l10n) {
    return BlocBuilder<RecipeBloc, RecipeState>(
      builder: (context, state) {
        final isTelugu = context.read<LanguageBloc>().state.isTelugu;
        final query = _searchController.text.trim();

        // Build suggestion list from allRecipes when focused
        List<Recipe> suggestions = [];
        if (state is RecipeLoaded && _showSuggestions) {
          if (query.isEmpty) {
            // Show recent / popular — top 6 by rating
            suggestions = [...state.allRecipes]
              ..sort((a, b) => b.rating.compareTo(a.rating));
            suggestions = suggestions.take(6).toList();
          } else {
            // Filter by title match
            final q = query.toLowerCase();
            suggestions = state.allRecipes
                .where((r) =>
                    r.title.toLowerCase().contains(q) ||
                    r.titleTe.contains(q) ||
                    r.category.toLowerCase().contains(q) ||
                    r.region.toLowerCase().contains(q))
                .take(8)
                .toList();
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Search input row ───────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: _showSuggestions
                    ? Border.all(color: Colors.orange.shade300, width: 1.5)
                    : null,
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(Icons.search_rounded,
                      color: _showSuggestions
                          ? Colors.orange.shade700
                          : Colors.grey.shade500,
                      size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        hintText: l10n.searchHint,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                        isDense: true,
                      ),
                      onChanged: _onSearchChanged,
                      onTap: () => setState(() => _showSuggestions = true),
                    ),
                  ),
                  // Clear button when typing
                  if (query.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.clear_rounded,
                          size: 18, color: Colors.grey.shade500),
                      onPressed: _clearSearch,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  // Mic button — inline in search bar
                  _InlineVoiceMic(
                    onStartListening: () {
                      _searchFocusNode.unfocus();
                      setState(() => _showSuggestions = false);
                      _startInlineVoiceSearch(context);
                    },
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),

            // ── Suggestion dropdown ────────────────────────────────────────
            if (_showSuggestions && suggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                      child: Row(
                        children: [
                          Icon(
                            query.isEmpty
                                ? Icons.trending_up_rounded
                                : Icons.search_rounded,
                            size: 14,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            query.isEmpty
                                ? (isTelugu
                                    ? 'ప్రసిద్ధ వంటకాలు'
                                    : 'Popular recipes')
                                : (isTelugu ? 'ఫలితాలు' : 'Results'),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Suggestion rows
                    ...suggestions.asMap().entries.map((entry) {
                      final i = entry.key;
                      final rec = entry.value;
                      final isLast = i == suggestions.length - 1;
                      return _SuggestionTile(
                        recipe: rec,
                        query: query,
                        isTelugu: isTelugu,
                        isLast: isLast,
                        onTap: () {
                          _searchFocusNode.unfocus();
                          setState(() => _showSuggestions = false);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RecipeDetailScreen(recipe: rec),
                            ),
                          );
                        },
                      );
                    }),
                  ],
                ),
              ),

            // ── No results message ─────────────────────────────────────────
            if (_showSuggestions &&
                query.isNotEmpty &&
                suggestions.isEmpty &&
                state is RecipeLoaded)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Center(
                  child: Text(
                    isTelugu
                        ? '"$query" కోసం వంటకాలు దొరకలేదు'
                        : 'No recipes found for "$query"',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _startInlineVoiceSearch(BuildContext context) {
    final voiceBloc = context.read<VoiceBloc>();
    final recipeBloc = context.read<RecipeBloc>();
    final langBloc = context.read<LanguageBloc>();
    final isTelugu = langBloc.state.isTelugu;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: voiceBloc),
          BlocProvider.value(value: recipeBloc),
          BlocProvider.value(value: langBloc),
        ],
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
          ),
          child: const VoiceSearchSheet(),
        ),
      ),
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

  // _showVoiceSearch removed — use _startInlineVoiceSearch via mic in search bar

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
    final isTelugu = context.watch<LanguageBloc>().state.isTelugu;

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag handle ─────────────────────────────────────────────────
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // ── Gradient header ─────────────────────────────────────────────
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.shade700,
                      Colors.deepOrange.shade800
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mic_rounded,
                        color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTelugu ? 'వాయిస్ సెర్చ్' : 'Voice Search',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          isTelugu
                              ? 'తెలుగు లేదా ఇంగ్లీష్‌లో మాట్లాడండి'
                              : 'Speak in Telugu or English',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Mic button with pulse ring ───────────────────────────────────
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
                  return Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (isListening) {
                            context
                                .read<VoiceBloc>()
                                .add(const StopListening());
                          } else {
                            context.read<VoiceBloc>().add(
                                  StartListening(
                                    localeId: isTelugu ? 'te_IN' : 'en_US',
                                    isSearchMode:
                                        true, // emit VoiceSearchResult, not command
                                  ),
                                );
                          }
                        },
                        child: _MicButton(isListening: isListening),
                      ),
                      const SizedBox(height: 14),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          key: ValueKey(isListening),
                          isListening
                              ? (isTelugu
                                  ? '🎙 వింటున్నాను...'
                                  : '🎙 Listening...')
                              : (isTelugu
                                  ? 'నొక్కి మాట్లాడండి'
                                  : 'Tap to speak'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isListening
                                ? FontWeight.w700
                                : FontWeight.normal,
                            color: isListening
                                ? Colors.deepOrange.shade700
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // ── Example chips ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Text(
                      isTelugu ? 'ఉదాహరణలు:' : 'Try saying:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: (isTelugu
                              ? [
                                  'బిర్యానీ',
                                  'గోంగూర కూర',
                                  'ఉదయం భోజనం',
                                  'శాకాహారం'
                                ]
                              : [
                                  'Biryani',
                                  'Gongura',
                                  'Breakfast',
                                  'Vegetarian'
                                ])
                          .map((t) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                  border:
                                      Border.all(color: Colors.orange.shade200),
                                ),
                                child: Text(
                                  '"$t"',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.orange.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ), // SingleChildScrollView
      ), // Container
    ); // SafeArea
  }
}

// ── Animated mic button ───────────────────────────────────────────────────────

class _MicButton extends StatefulWidget {
  final bool isListening;
  const _MicButton({required this.isListening});

  @override
  State<_MicButton> createState() => _MicButtonState();
}

// ── Inline voice mic button (sits inside search bar) ────────────────────────

class _InlineVoiceMic extends StatelessWidget {
  final VoidCallback onStartListening;
  const _InlineVoiceMic({required this.onStartListening});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VoiceBloc, VoiceState>(
      builder: (context, state) {
        final isListening = state is VoiceListening;
        return GestureDetector(
          onTap: onStartListening,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 36,
            height: 36,
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isListening
                  ? Colors.red.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
            ),
            child: Icon(
              isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
              size: 20,
              color: isListening ? Colors.red.shade600 : Colors.orange.shade700,
            ),
          ),
        );
      },
    );
  }
}

// ── Suggestion tile ───────────────────────────────────────────────────────────

class _SuggestionTile extends StatelessWidget {
  final Recipe recipe;
  final String query;
  final bool isTelugu;
  final bool isLast;
  final VoidCallback onTap;

  const _SuggestionTile({
    required this.recipe,
    required this.query,
    required this.isTelugu,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = isTelugu ? recipe.titleTe : recipe.title;

    return InkWell(
      onTap: onTap,
      borderRadius: isLast
          ? const BorderRadius.vertical(bottom: Radius.circular(14))
          : BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Category icon colored circle
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: recipe.categoryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(recipe.categoryIcon,
                  size: 18, color: recipe.categoryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HighlightedText(text: title, query: query),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        recipe.region,
                        style: TextStyle(
                          fontSize: 11,
                          color: recipe.regionColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '  •  ${recipe.cookTimeDisplay}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }
}

// ── Text with query highlighted in orange ─────────────────────────────────────

class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  const _HighlightedText({required this.text, required this.query});

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis);
    }
    final lower = text.toLowerCase();
    final qLower = query.toLowerCase();
    final idx = lower.indexOf(qLower);
    if (idx < 0) {
      return Text(text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis);
    }
    return Text.rich(
      TextSpan(children: [
        if (idx > 0)
          TextSpan(
              text: text.substring(0, idx),
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        TextSpan(
          text: text.substring(idx, idx + query.length),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.orange.shade700,
            backgroundColor: Colors.orange.withValues(alpha: 0.1),
          ),
        ),
        if (idx + query.length < text.length)
          TextSpan(
            text: text.substring(idx + query.length),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
      ]),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _MicButtonState extends State<_MicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _ring;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _ring = Tween(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(_MicButton old) {
    super.didUpdateWidget(old);
    if (widget.isListening && !old.isListening) {
      _pulse.repeat(reverse: true);
    } else if (!widget.isListening && old.isListening) {
      _pulse.stop();
      _pulse.reset();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ring,
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulse ring
          if (widget.isListening)
            Container(
              width: 96 * _ring.value,
              height: 96 * _ring.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.deepOrange
                    .withValues(alpha: 0.15 * (1 - (_ring.value - 1) / 0.35)),
              ),
            ),
          // Main button
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: widget.isListening
                    ? [Colors.red.shade500, Colors.red.shade700]
                    : [Colors.orange.shade600, Colors.deepOrange.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: (widget.isListening ? Colors.red : Colors.orange)
                      .withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              widget.isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }
}
