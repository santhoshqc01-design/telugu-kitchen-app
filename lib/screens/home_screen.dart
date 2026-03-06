import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lottie/lottie.dart';
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
    _searchController.addListener(() => setState(() {}));
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

  // ── Open full-screen search overlay ───────────────────────────────────────

  void _openSearchOverlay(
      BuildContext context, AppLocalizations l10n, bool isTelugu) {
    final recipeBloc = context.read<RecipeBloc>();
    final voiceBloc = context.read<VoiceBloc>();
    final langBloc = context.read<LanguageBloc>();

    Navigator.of(context)
        .push(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (ctx, animation, _) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: recipeBloc),
            BlocProvider.value(value: voiceBloc),
            BlocProvider.value(value: langBloc),
          ],
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: _SearchOverlayScreen(
              initialQuery: _searchController.text,
              onQueryCommitted: (query) {
                _searchController.text = query;
                context.read<RecipeBloc>().add(SearchRecipes(query));
              },
            ),
          ),
        ),
      ),
    )
        .then((_) {
      // When overlay closes, always hide the inline dropdown
      // and unfocus so the home screen looks clean
      _searchFocusNode.unfocus();
      if (mounted) setState(() => _showSuggestions = false);
    });
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
    );
  }

  // ── Nav Bar ────────────────────────────────────────────────────────────────

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
          SliverPersistentHeader(
            pinned: true,
            delegate: _SearchBarDelegate(
              child: _buildSearchBar(l10n),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  _buildFilterRow(l10n, isTelugu),
                  const SizedBox(height: 8),
                  _buildActiveFiltersRow(isTelugu),
                  const SizedBox(height: 8),
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
      titleSpacing: 0,
      elevation: 0,
      title: null,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        centerTitle: false,
        expandedTitleScale: 1.6,
        titlePadding: const EdgeInsetsDirectional.only(start: 20, bottom: 14),
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
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFBF360C),
                Colors.orange.shade700,
                const Color(0xFFFF8F00),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // ── Animated floating spice pattern ───────────────────────────
              const Positioned.fill(child: _SpicePatternBackground()),

              // ── Decorative depth circles ───────────────────────────────────
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
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
                    color: Colors.black.withValues(alpha: 0.07),
                  ),
                ),
              ),

              // ── Cooking pot animation (right side) ────────────────────────
              const Positioned(
                right: 12,
                bottom: 0,
                child: SizedBox(
                  width: 100,
                  height: 140,
                  child: _CookingPotAnimation(),
                ),
              ),

              // ── All text + cards (left side, avoids pot) ──────────────────
              // Vertical layout:
              //   greeting row
              //   SizedBox(10)
              //   meal-time nudge pill
              //   SizedBox(10)
              //   stats row
              //   SizedBox(12)
              //   Recipe of the Day card
              //   SizedBox(72)  ← reserved for FlexibleSpaceBar title
              Padding(
                padding: EdgeInsets.fromLTRB(
                    16, MediaQuery.paddingOf(context).top + 10, 140, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Greeting ─────────────────────────────────────────────
                    Row(
                      children: [
                        Text(
                          '$emoji  $greeting',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // ── Meal-time nudge pill ──────────────────────────────────
                    BlocBuilder<RecipeBloc, RecipeState>(
                      builder: (context, state) {
                        if (state is! RecipeLoaded) {
                          return const SizedBox.shrink();
                        }
                        final (nudgeText, nudgeIcon, filterCategory) =
                            _getMealNudge(isTelugu);
                        return GestureDetector(
                          onTap: () => context
                              .read<RecipeBloc>()
                              .add(FilterByCategory(filterCategory)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(nudgeIcon,
                                    style: const TextStyle(fontSize: 13)),
                                const SizedBox(width: 5),
                                Text(
                                  nudgeText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.95),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios_rounded,
                                    size: 9,
                                    color: Colors.white.withValues(alpha: 0.7)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 6),

                    // ── Stats row ─────────────────────────────────────────────
                    BlocBuilder<RecipeBloc, RecipeState>(
                      builder: (context, state) {
                        if (state is! RecipeLoaded) {
                          return const SizedBox.shrink();
                        }
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
                    const SizedBox(height: 8),

                    // ── Recipe of the Day card ────────────────────────────────
                    BlocBuilder<RecipeBloc, RecipeState>(
                      builder: (context, state) {
                        if (state is! RecipeLoaded) {
                          return const SizedBox.shrink();
                        }
                        final recipe = _recipeOfTheDay(state.allRecipes);
                        if (recipe == null) return const SizedBox.shrink();
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  RecipeDetailScreen(recipe: recipe),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Star badge
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.25),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Text('⭐',
                                        style: TextStyle(fontSize: 15)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isTelugu
                                            ? 'ఈరోజు వంటకం'
                                            : "Today's Pick",
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.amber.shade200,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                      Text(
                                        isTelugu
                                            ? recipe.titleTe
                                            : recipe.title,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Quick stats
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    _miniStat(Icons.timer_outlined,
                                        recipe.cookTimeShort),
                                    const SizedBox(height: 2),
                                    _miniStat(Icons.signal_cellular_alt_rounded,
                                        recipe.difficulty),
                                  ],
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.chevron_right_rounded,
                                    color: Colors.white.withValues(alpha: 0.6),
                                    size: 18),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // ── Space for FlexibleSpaceBar title ──────────────────────
                    // title fontSize 20 × scale 1.6 ≈ 32px + bottom:14 + padding
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
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

  // ── Meal-time nudge ────────────────────────────────────────────────────────
  // Returns (label, emoji, recipeCategory) based on current hour.

  (String, String, String) _getMealNudge(bool isTelugu) {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 11) {
      return isTelugu
          ? ('అల్పాహారం చేయాలా?', '🍳', 'Breakfast')
          : ('Breakfast time?', '🍳', 'Breakfast');
    } else if (hour >= 11 && hour < 15) {
      return isTelugu
          ? ('భోజన వంటకాలు చూడండి', '🍛', 'Lunch')
          : ('Lunch ideas today', '🍛', 'Lunch');
    } else if (hour >= 15 && hour < 18) {
      return isTelugu
          ? ('స్నాక్స్ తయారు చేయండి', '☕', 'Snacks')
          : ('Snack o\'clock!', '☕', 'Snacks');
    } else if (hour >= 18 && hour < 22) {
      return isTelugu
          ? ('రాత్రి వంట ఏమి చేద్దాం?', '🌙', 'Dinner')
          : ('What\'s for dinner?', '🌙', 'Dinner');
    } else {
      return isTelugu
          ? ('లేట్ నైట్ స్నాక్ కావాలా?', '🌙', 'Snacks')
          : ('Late night snack?', '🌙', 'Snacks');
    }
  }

  // ── Recipe of the Day ──────────────────────────────────────────────────────
  // Deterministically picks one recipe per calendar day using day-of-year seed.
  // Same recipe all day, changes at midnight — no state/storage needed.

  Recipe? _recipeOfTheDay(List<Recipe> recipes) {
    if (recipes.isEmpty) return null;
    final now = DateTime.now();
    final seed = now.year * 1000 + now.month * 31 + now.day;
    return recipes[seed % recipes.length];
  }

  // ── Mini stat badge (used in Recipe of the Day card) ──────────────────────

  Widget _miniStat(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: Colors.white.withValues(alpha: 0.65)),
        const SizedBox(width: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── Search Bar ─────────────────────────────────────────────────────────────

  Widget _buildSearchBar(AppLocalizations l10n) {
    return BlocBuilder<RecipeBloc, RecipeState>(
      builder: (context, state) {
        final isTelugu = context.read<LanguageBloc>().state.isTelugu;
        final query = _searchController.text.trim();

        List<Recipe> suggestions = [];
        if (state is RecipeLoaded && _showSuggestions) {
          if (query.isEmpty) {
            suggestions = [...state.allRecipes]
              ..sort((a, b) => b.rating.compareTo(a.rating));
            suggestions = suggestions.take(6).toList();
          } else {
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

        return TapRegion(
          onTapOutside: (_) {
            _searchFocusNode.unfocus();
            if (_showSuggestions) setState(() => _showSuggestions = false);
          },
          child: GestureDetector(
            onTap: () => _openSearchOverlay(context, l10n, isTelugu),
            behavior: HitTestBehavior.translucent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Search input ───────────────────────────────────────────────
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
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            inputDecorationTheme: const InputDecorationTheme(
                              filled: true,
                              fillColor: Colors.transparent,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            readOnly: true,
                            decoration: InputDecoration(
                              hintText: l10n.searchHint,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: true,
                              fillColor: Colors.transparent,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              isDense: true,
                            ),
                            onTap: () =>
                                _openSearchOverlay(context, l10n, isTelugu),
                          ),
                        ),
                      ),
                      if (query.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.clear_rounded,
                              size: 18, color: Colors.grey.shade500),
                          onPressed: _clearSearch,
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 36, minHeight: 36),
                        ),
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
                                  builder: (_) =>
                                      RecipeDetailScreen(recipe: rec),
                                ),
                              );
                            },
                          );
                        }),
                      ],
                    ),
                  ),

                // ── No results ─────────────────────────────────────────────────
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
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 13),
                      ),
                    ),
                  ),
              ],
            ),
          ), // GestureDetector
        );
      },
    );
  }

  void _startInlineVoiceSearch(BuildContext context) {
    final voiceBloc = context.read<VoiceBloc>();
    final recipeBloc = context.read<RecipeBloc>();
    final langBloc = context.read<LanguageBloc>();
    final isTelugu = langBloc.state.isTelugu;

    voiceBloc.add(StartListening(
      localeId: isTelugu ? 'te_IN' : 'en_US',
      isSearchMode: true,
    ));

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
    ).then((_) {
      if (voiceBloc.state is VoiceListening) {
        voiceBloc.add(const StopListening());
      }
    });
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
          chips.add(_activeFilterChip(
            label: isTelugu
                ? (RecipeCategories.telugu[state.selectedCategory] ??
                    state.selectedCategory)
                : state.selectedCategory,
            onRemove: () =>
                context.read<RecipeBloc>().add(const FilterByCategory('All')),
          ));
        }
        if (state.selectedRegion != 'All') {
          chips.add(_activeFilterChip(
            label: isTelugu
                ? (RecipeRegions.telugu[state.selectedRegion] ??
                    state.selectedRegion)
                : state.selectedRegion,
            onRemove: () =>
                context.read<RecipeBloc>().add(const FilterByRegion('All')),
          ));
        }
        if (state.selectedDifficulty != 'All') {
          chips.add(_activeFilterChip(
            label: isTelugu
                ? (RecipeDifficulty.telugu[state.selectedDifficulty] ??
                    state.selectedDifficulty)
                : state.selectedDifficulty,
            onRemove: () =>
                context.read<RecipeBloc>().add(const FilterByDifficulty('All')),
          ));
        }
        if (state.vegetarianOnly) {
          chips.add(_activeFilterChip(
            label: isTelugu ? 'శాకాహారం' : 'Veg only',
            color: const Color(0xFF2E7D32),
            onRemove: () =>
                context.read<RecipeBloc>().add(const ToggleVegetarian()),
          ));
        }
        if (state.maxCookTimeMinutes != null) {
          chips.add(_activeFilterChip(
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

  Widget _activeFilterChip({
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

  // ── Combined filter row: categories + regions in one horizontal scroll ──────
  // Replaces separate _buildCategories and _buildRegions.
  // All chips are uniform height (~36px) — saves ~150px vs the old layout.

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

  static const _regionData = [
    ('Andhra', Color(0xFFE65100), 'ఆంధ్ర'),
    ('Telangana', Color(0xFF880E4F), 'తెలంగాణ'),
    ('Rayalaseema', Color(0xFF1B5E20), 'రాయలసీమ'),
  ];

  Widget _buildFilterRow(AppLocalizations l10n, bool isTelugu) {
    return BlocBuilder<RecipeBloc, RecipeState>(
      builder: (context, state) {
        final selCat = state is RecipeLoaded ? state.selectedCategory : 'All';
        final selRegion = state is RecipeLoaded ? state.selectedRegion : 'All';

        // Build chip list: categories first, then a subtle divider, then regions
        final chips = <Widget>[];

        // Category chips
        for (final (name, icon, color, teluguName) in _categoryData) {
          final isSelected = selCat == name;
          final label = isTelugu
              ? teluguName
              : _getCategoryName(l10n, name.toLowerCase());
          chips.add(_selectionFilterChip(
            label: label,
            icon: icon,
            color: color,
            isSelected: isSelected,
            onTap: () => context
                .read<RecipeBloc>()
                .add(FilterByCategory(isSelected ? 'All' : name)),
          ));
        }

        // Divider between categories and regions
        chips.add(
          Container(
            width: 1,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            color: Colors.grey.shade300,
          ),
        );

        // Region chips
        for (final (name, color, teluguName) in _regionData) {
          final isSelected = selRegion == name;
          final label =
              isTelugu ? teluguName : _getRegionName(l10n, name.toLowerCase());
          chips.add(_selectionFilterChip(
            label: label,
            color: color,
            isSelected: isSelected,
            onTap: () => context
                .read<RecipeBloc>()
                .add(FilterByRegion(isSelected ? 'All' : name)),
          ));
        }

        return SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: chips,
          ),
        );
      },
    );
  }

  Widget _selectionFilterChip({
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: isSelected ? Colors.white : color),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
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
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (state is RecipeLoaded && !hasFilters)
                  Text(
                    '$count ${isTelugu ? "వంటకాలు" : "recipes"}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            FilterChip(
              label: Text(isTelugu ? 'శాకా' : 'Veg'),
              selected: isVeg,
              onSelected: (_) =>
                  context.read<RecipeBloc>().add(const ToggleVegetarian()),
              avatar: Icon(Icons.eco_rounded,
                  size: 16,
                  color: isVeg ? Colors.white : const Color(0xFF2E7D32)),
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
          return AnimationLimiter(
            child: SliverPadding(
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
                    return AnimationConfiguration.staggeredGrid(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      columnCount: 2,
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: RecipeCard(
                            recipe: recipe,
                            isFavorite: state.isFavorite(recipe.id),
                            isTelugu: isTelugu,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    RecipeDetailScreen(recipe: recipe),
                              ),
                            ),
                            onFavoriteToggle: () => context
                                .read<RecipeBloc>()
                                .add(ToggleFavorite(recipe.id)),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: state.recipes.length,
                ),
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
            Lottie.asset(
              'assets/lottie/food_animation.json',
              width: 200,
              repeat: true,
              errorBuilder: (context, error, stackTrace) => Icon(
                hasFilters
                    ? Icons.filter_alt_off_rounded
                    : Icons.search_off_rounded,
                size: 64,
                color: Colors.grey.shade300,
              ),
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
        child: GestureDetector(
          onLongPress: () => _showContextMenu(context),
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
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _badge(recipe.region, recipe.regionColor),
                      ),
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
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    final isTelugu = context.read<LanguageBloc>().state.isTelugu;
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  isTelugu ? recipe.titleTe : recipe.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_outline_rounded,
                  color: Colors.red,
                ),
                title: Text(isFavorite
                    ? (isTelugu
                        ? 'ఇష్టమైనవాటి నుండి తీసివేయి'
                        : 'Remove from Favorites')
                    : (isTelugu ? 'ఇష్టమైనవాటికి చేర్చు' : 'Add to Favorites')),
                onTap: () {
                  Navigator.pop(context);
                  onFavoriteToggle();
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_rounded, color: Colors.blue),
                title: Text(isTelugu ? 'షేర్ చేయి' : 'Share Recipe'),
                onTap: () {
                  Navigator.pop(context);
                  final title = isTelugu ? recipe.titleTe : recipe.title;
                  Share.share(
                    '$title — ${recipe.region} | ${recipe.cookTimeDisplay} | Ruchi App 🍛',
                    subject: title,
                  );
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.play_circle_rounded, color: Colors.orange),
                title: Text(isTelugu ? 'వంట ప్రారంభించు' : 'Start Cooking'),
                onTap: () {
                  Navigator.pop(context);
                  onTap();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    // CachedNetworkImage disk cache fails silently on Android — use Image.network directly.
    if (recipe.imageUrl.isEmpty) return _imageFallback();
    return Image.network(
      recipe.imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child; // fully loaded
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(color: Colors.white),
        );
      },
      errorBuilder: (context, error, stackTrace) => _imageFallback(),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_rounded, size: 40, color: Colors.grey.shade400),
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
                recipe.titleTe.isNotEmpty ? recipe.titleTe[0] : recipe.title[0],
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
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.shade700,
                      Colors.deepOrange.shade800,
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
              BlocConsumer<VoiceBloc, VoiceState>(
                listener: (context, state) {
                  if (state is VoiceSearchResult) {
                    // FIX: capture bloc + query BEFORE Navigator.pop
                    // After pop, the sheet context is dead — reading blocs from it silently fails
                    final recipeBloc = context.read<RecipeBloc>();
                    final query = state.text;
                    recipeBloc.add(SearchRecipes(query));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_outline,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(isTelugu
                                ? 'సెర్చ్ చేస్తున్నాను: \$query'
                                : 'Searching: \$query'),
                          ],
                        ),
                        backgroundColor: Colors.orange.shade800,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                  if (state is VoiceError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red.shade700,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  final isListening = state is VoiceListening;
                  final partialText =
                      state is VoiceListening ? state.partialText : null;
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
                                    isSearchMode: true,
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
                          key: ValueKey(
                              isListening.toString() + (partialText ?? '')),
                          isListening
                              ? (partialText != null && partialText.isNotEmpty
                                  ? partialText
                                  : (isTelugu
                                      ? '🎙 వింటున్నాను...'
                                      : '🎙 Listening...'))
                              : (isTelugu
                                  ? 'నొక్కి మాట్లాడండి'
                                  : 'Tap to speak'),
                          textAlign: TextAlign.center,
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
        ),
      ),
    );
  }
}

// ─── Search Overlay Screen ────────────────────────────────────────────────────
//
// Full-screen search experience. Slides up over the home screen.
// • Keyboard-aware: results list shrinks above keyboard, never hidden behind it
// • Recent searches: stored in memory, shown when query is empty
// • Live results: fires as user types with 300ms debounce
// • Back button / swipe closes overlay and returns committed query to home

class _SearchOverlayScreen extends StatefulWidget {
  final String initialQuery;
  final ValueChanged<String> onQueryCommitted;

  const _SearchOverlayScreen({
    required this.initialQuery,
    required this.onQueryCommitted,
  });

  @override
  State<_SearchOverlayScreen> createState() => _SearchOverlayScreenState();
}

class _SearchOverlayScreenState extends State<_SearchOverlayScreen>
    with TickerProviderStateMixin {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;
  Timer? _debounce;
  Timer? _typewriterTimer;

  static final List<String> _recentSearches = [];
  static final List<Recipe> _recentlyViewed = [];

  List<Recipe> _results = [];
  bool _hasSearched = false;

  // ── Feature: category filter chips ────────────────────────────────────────
  String _selectedCategory = 'All';
  static const _categories = [
    'All',
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snacks',
    'Desserts',
    'Beverages'
  ];

  // ── Feature: staggered animation ──────────────────────────────────────────
  late AnimationController _listAnimCtrl;

  // ── Typewriter ─────────────────────────────────────────────────────────────
  final List<String> _placeholderHints = [
    'బిర్యానీ',
    'పెసరట్టు',
    'గోంగూర',
    'హలీం',
    'దోశ',
    'పూతరేకులు',
    'చికెన్ కూర',
  ];
  int _hintIndex = 0;
  String _currentHint = '';
  bool _typingForward = true;
  int _charIndex = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialQuery);
    _focus = FocusNode();
    _focus.addListener(() {
      if (_focus.hasFocus) _typewriterTimer?.cancel();
      setState(() {});
    });
    _currentHint = _placeholderHints[0];
    _listAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
      if (widget.initialQuery.isNotEmpty) {
        _runSearch(widget.initialQuery);
      } else {
        _startTypewriter();
      }
    });
    _ctrl.addListener(() => setState(() {}));
  }

  void _startTypewriter() {
    _typewriterTimer?.cancel();
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted) return;
      final target = _placeholderHints[_hintIndex];
      setState(() {
        if (_typingForward) {
          if (_charIndex < target.length) {
            _charIndex++;
            _currentHint = target.substring(0, _charIndex);
          } else {
            _typingForward = false;
          }
        } else {
          if (_charIndex > 0) {
            _charIndex--;
            _currentHint = target.substring(0, _charIndex);
          } else {
            _hintIndex = (_hintIndex + 1) % _placeholderHints.length;
            _typingForward = true;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    _debounce?.cancel();
    _typewriterTimer?.cancel();
    _listAnimCtrl.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      _startTypewriter();
      return;
    }
    _typewriterTimer?.cancel();
    _debounce =
        Timer(const Duration(milliseconds: 300), () => _runSearch(value));
  }

  void _runSearch(String query) {
    final state = context.read<RecipeBloc>().state;
    if (state is! RecipeLoaded) return;
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }
    var matched = state.allRecipes
        .where((r) =>
            r.title.toLowerCase().contains(q) ||
            r.titleTe.contains(q) ||
            r.category.toLowerCase().contains(q) ||
            r.region.toLowerCase().contains(q) ||
            r.tags.any((t) => t.toLowerCase().contains(q)) ||
            r.ingredients.any((i) => i.toLowerCase().contains(q)))
        .toList();
    // Apply category filter
    if (_selectedCategory != 'All') {
      matched = matched.where((r) => r.category == _selectedCategory).toList();
    }
    setState(() {
      _results = matched;
      _hasSearched = true;
    });
    // Trigger staggered animation
    _listAnimCtrl.forward(from: 0);
  }

  void _commitSearch(String query) {
    if (query.trim().isEmpty) return;
    _recentSearches.remove(query);
    _recentSearches.insert(0, query);
    if (_recentSearches.length > 10) _recentSearches.removeLast();
    widget.onQueryCommitted(query.trim());
    Navigator.of(context).pop();
  }

  void _openRecipe(Recipe recipe) {
    _recentlyViewed.removeWhere((r) => r.id == recipe.id);
    _recentlyViewed.insert(0, recipe);
    if (_recentlyViewed.length > 8) _recentlyViewed.removeLast();
    final q = _ctrl.text.trim();
    if (q.isNotEmpty) {
      _recentSearches.remove(q);
      _recentSearches.insert(0, q);
      widget.onQueryCommitted(q);
    }
    Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe)));
  }

  void _clear() {
    _ctrl.clear();
    setState(() {
      _results = [];
      _hasSearched = false;
      _selectedCategory = 'All';
    });
    _startTypewriter();
  }

  // ── Feature: voice search ──────────────────────────────────────────────────
  void _startVoiceSearch(BuildContext context) {
    final voiceBloc = context.read<VoiceBloc>();
    final recipeBloc = context.read<RecipeBloc>();
    final langBloc = context.read<LanguageBloc>();
    final isTelugu = langBloc.state.isTelugu;

    voiceBloc.add(StartListening(
      localeId: isTelugu ? 'te_IN' : 'en_US',
      isSearchMode: true,
    ));

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
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
          child: BlocListener<VoiceBloc, VoiceState>(
            listener: (ctx, state) {
              if (state is VoiceSearchResult && state.text.isNotEmpty) {
                Navigator.pop(ctx);
                _ctrl.text = state.text;
                _runSearch(state.text);
              }
            },
            child: const VoiceSearchSheet(),
          ),
        ),
      ),
    ).then((_) {
      if (voiceBloc.state is VoiceListening) {
        voiceBloc.add(const StopListening());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTelugu = context.watch<LanguageBloc>().state.isTelugu;
    final query = _ctrl.text.trim();
    final mq = MediaQuery.of(context);
    final topPad = mq.padding.top;
    final bottomPad = mq.padding.bottom;
    final kb = mq.viewInsets.bottom;

    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.white),
      child: Material(
        color: Colors.white,
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(8, topPad + 8, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded,
                        color: Colors.grey.shade700, size: 22),
                    onPressed: () {
                      widget.onQueryCommitted(_ctrl.text.trim());
                      Navigator.of(context).pop();
                    },
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _typewriterTimer?.cancel();
                        _focus.requestFocus();
                      },
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _focus.hasFocus
                                ? Colors.orange.shade400
                                : Colors.grey.shade200,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 10),
                            Icon(Icons.search_rounded,
                                color: Colors.grey.shade500, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  inputDecorationTheme:
                                      const InputDecorationTheme(
                                    filled: true,
                                    fillColor: Colors.transparent,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 12),
                                    isDense: true,
                                  ),
                                ),
                                child: TextField(
                                  controller: _ctrl,
                                  focusNode: _focus,
                                  onChanged: _onChanged,
                                  onSubmitted: _commitSearch,
                                  textInputAction: TextInputAction.search,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87),
                                  decoration: InputDecoration(
                                    hintText: isTelugu
                                        ? '$_currentHint కోసం శోధించండి'
                                        : 'Search for $_currentHint',
                                    hintStyle: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 14),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: true,
                                    fillColor: Colors.transparent,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),
                            ),
                            if (query.isNotEmpty)
                              GestureDetector(
                                onTap: _clear,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  child: Icon(Icons.close_rounded,
                                      color: Colors.grey.shade500, size: 18),
                                ),
                              ),
                            // ── Feature: voice search mic ──────────────────
                            GestureDetector(
                              onTap: () => _startVoiceSearch(context),
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(right: 10, left: 2),
                                child: Icon(Icons.mic_rounded,
                                    color: query.isEmpty
                                        ? Colors.orange.shade600
                                        : Colors.grey.shade400,
                                    size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Feature: category filter chips ─────────────────────────────
            if (query.isNotEmpty) ...[
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final cat = _categories[i];
                    final isSelected = _selectedCategory == cat;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedCategory = cat);
                        _runSearch(_ctrl.text);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.orange.shade700
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? Colors.orange.shade700
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          isTelugu ? _categoryTe(cat) : cat,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 4),
            ],

            const Divider(height: 1, color: Color(0xFFEEEEEE)),

            // ── Body ───────────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: kb > 0 ? kb : bottomPad),
                child: query.isEmpty
                    ? _buildEmptyState(isTelugu)
                    : _hasSearched
                        ? _buildResults(isTelugu, query)
                        : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryTe(String cat) {
    const map = {
      'All': 'అన్నీ',
      'Breakfast': 'అల్పాహారం',
      'Lunch': 'భోజనం',
      'Dinner': 'రాత్రి భోజనం',
      'Snacks': 'స్నాక్స్',
      'Desserts': 'స్వీట్లు',
      'Beverages': 'పానీయాలు',
    };
    return map[cat] ?? cat;
  }

  Widget _buildEmptyState(bool isTelugu) {
    final state = context.watch<RecipeBloc>().state;
    final popular = state is RecipeLoaded
        ? ([...state.allRecipes]..sort((a, b) => b.rating.compareTo(a.rating)))
            .take(8)
            .toList()
        : <Recipe>[];

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      children: [
        // ── Feature: past searches wrap grid with long-press delete ─────────
        if (_recentSearches.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Text(
                  isTelugu ? 'మీ గత శోధనలు' : 'YOUR PAST SEARCHES',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade700,
                      letterSpacing: 0.6),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _recentSearches.clear()),
                  child: Text(isTelugu ? 'తొలగించు' : 'Clear',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches.map((q) {
                return GestureDetector(
                  onTap: () {
                    _ctrl.text = q;
                    _ctrl.selection = TextSelection.fromPosition(
                        TextPosition(offset: q.length));
                    _focus.requestFocus();
                    _runSearch(q);
                  },
                  // ── Feature: long press to delete individual chip ──────────
                  onLongPress: () {
                    setState(() => _recentSearches.remove(q));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            isTelugu ? '"$q" తొలగించబడింది' : 'Removed "$q"'),
                        duration: const Duration(seconds: 2),
                        action: SnackBarAction(
                          label: isTelugu ? 'రద్దు' : 'Undo',
                          onPressed: () => setState(() {
                            _recentSearches.insert(0, q);
                          }),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_rounded,
                            size: 13, color: Colors.grey.shade400),
                        const SizedBox(width: 5),
                        Text(q,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, indent: 16, endIndent: 16),
        ],

        // Cook again
        if (_recentlyViewed.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Text(isTelugu ? 'మళ్ళీ వండండి' : 'Cook Again',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade800)),
          ),
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _recentlyViewed.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final r = _recentlyViewed[i];
                return GestureDetector(
                  onTap: () => _openRecipe(r),
                  child: Container(
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(10)),
                          child: SizedBox(
                            height: 70,
                            width: 100,
                            child: Image.network(r.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                      color:
                                          r.regionColor.withValues(alpha: 0.15),
                                      child: Center(
                                          child: Text(r.titleTe[0],
                                              style: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: r.regionColor))),
                                    )),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: Text(isTelugu ? r.titleTe : r.title,
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, indent: 16, endIndent: 16),
        ],

        // Popular recipes
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Text(isTelugu ? 'ప్రసిద్ధ వంటకాలు' : 'Popular Recipes',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade800)),
        ),
        ...popular.map((r) => _recipeTile(r, isTelugu, '')),
      ],
    );
  }

  Widget _buildResults(bool isTelugu, String query) {
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
                isTelugu
                    ? '"$query" కోసం వంటకాలు దొరకలేదు'
                    : 'No recipes found for "$query"',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
                isTelugu
                    ? 'వేరే పదాలతో ప్రయత్నించండి'
                    : 'Try different keywords',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
          ],
        ),
      );
    }

    // ── Feature: staggered slide-up animation ──────────────────────────────
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              isTelugu
                  ? '${_results.length} వంటకాలు దొరికాయి'
                  : '${_results.length} recipes found',
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              // Stagger each tile's animation by index
              final itemAnim = Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _listAnimCtrl,
                curve: Interval(
                  (i * 0.08).clamp(0.0, 0.8),
                  ((i * 0.08) + 0.4).clamp(0.0, 1.0),
                  curve: Curves.easeOutCubic,
                ),
              ));
              final fadeAnim = Tween<double>(begin: 0, end: 1).animate(
                CurvedAnimation(
                  parent: _listAnimCtrl,
                  curve: Interval(
                    (i * 0.08).clamp(0.0, 0.8),
                    ((i * 0.08) + 0.3).clamp(0.0, 1.0),
                  ),
                ),
              );
              return FadeTransition(
                opacity: fadeAnim,
                child: SlideTransition(
                  position: itemAnim,
                  child: Column(
                    children: [
                      _recipeTile(_results[i], isTelugu, query),
                      if (i < _results.length - 1)
                        const Divider(height: 1, indent: 70, endIndent: 16),
                    ],
                  ),
                ),
              );
            },
            childCount: _results.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }

  Widget _recipeTile(Recipe recipe, bool isTelugu, String query) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 52,
          height: 52,
          child: Image.network(recipe.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                    color: recipe.regionColor.withValues(alpha: 0.15),
                    child: Center(
                        child: Text(
                            recipe.titleTe.isNotEmpty
                                ? recipe.titleTe[0]
                                : recipe.title[0],
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: recipe.regionColor))),
                  )),
        ),
      ),
      // ── Feature: highlighted matched text ──────────────────────────────
      title: _HighlightText(
        text: isTelugu ? recipe.titleTe : recipe.title,
        query: query,
        baseStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        highlightStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Colors.orange.shade700),
      ),
      subtitle: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: recipe.regionColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4)),
            child: Text(recipe.region,
                style: TextStyle(
                    fontSize: 10,
                    color: recipe.regionColor,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 6),
          Icon(Icons.timer_outlined, size: 11, color: Colors.grey.shade400),
          const SizedBox(width: 2),
          Text(recipe.cookTimeShort,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          const SizedBox(width: 6),
          Icon(Icons.star_rounded, size: 11, color: Colors.amber.shade600),
          const SizedBox(width: 2),
          Text(recipe.ratingDisplay,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
      trailing: Icon(Icons.chevron_right_rounded,
          color: Colors.grey.shade300, size: 20),
      onTap: () => _openRecipe(recipe),
    );
  }
}

// ── Feature: highlight matched text widget ─────────────────────────────────────

class _HighlightText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle baseStyle;
  final TextStyle highlightStyle;

  const _HighlightText({
    required this.text,
    required this.query,
    required this.baseStyle,
    required this.highlightStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text,
          style: baseStyle, maxLines: 1, overflow: TextOverflow.ellipsis);
    }

    final q = query.toLowerCase();
    final lower = text.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final idx = lower.indexOf(q, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start), style: baseStyle));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx), style: baseStyle));
      }
      spans.add(TextSpan(
          text: text.substring(idx, idx + q.length), style: highlightStyle));
      start = idx + q.length;
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// ─── Spice Pattern Background ─────────────────────────────────────────────────
//
// Slowly drifting food/spice emoji icons across the header background.
// Very low opacity so they never compete with the text.

class _SpicePatternBackground extends StatefulWidget {
  const _SpicePatternBackground();

  @override
  State<_SpicePatternBackground> createState() =>
      _SpicePatternBackgroundState();
}

class _SpicePatternBackgroundState extends State<_SpicePatternBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // Fixed positions so they don't recalculate on every rebuild
  static const _spices = [
    ('🌶️', 0.08, 0.12, 0.0),
    ('🌿', 0.25, 0.55, 0.3),
    ('⭐', 0.55, 0.10, 0.6),
    ('🧄', 0.72, 0.65, 0.1),
    ('🫚', 0.38, 0.30, 0.8),
    ('🌰', 0.85, 0.25, 0.45),
    ('🫙', 0.15, 0.80, 0.7),
    ('🧅', 0.62, 0.88, 0.2),
    ('🌾', 0.45, 0.72, 0.55),
    ('🫛', 0.90, 0.50, 0.9),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _SpicePainter(progress: _ctrl.value),
      ),
    );
  }
}

class _SpicePainter extends CustomPainter {
  final double progress;
  const _SpicePainter({required this.progress});

  static const _items = _SpicePatternBackgroundState._spices;

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (final (emoji, fx, fy, phase) in _items) {
      // Gentle vertical drift — each icon drifts up by ~4% of height per cycle
      final drift = ((progress + phase) % 1.0);
      final x = fx * size.width;
      final y = (fy - drift * 0.08) * size.height;
      // Fade in/out based on drift position
      final opacity = (drift < 0.5 ? drift * 2 : (1 - drift) * 2) * 0.13;
      tp.text = TextSpan(
        text: emoji,
        style: TextStyle(
            fontSize: 18, color: Colors.white.withValues(alpha: opacity)),
      );
      tp.layout();
      tp.paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(_SpicePainter old) => old.progress != progress;
}

// ─── Cooking Pot Animation ────────────────────────────────────────────────────
//
// Self-contained animated widget drawn with CustomPainter.
// Pot body, lid bounce, bubbling liquid, side handles, rising steam puffs.
// No external packages — pure Flutter canvas.

class _CookingPotAnimation extends StatefulWidget {
  const _CookingPotAnimation();

  @override
  State<_CookingPotAnimation> createState() => _CookingPotAnimationState();
}

class _CookingPotAnimationState extends State<_CookingPotAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _lidCtrl;
  late final Animation<double> _lidAnim;
  late final AnimationController _bubbleCtrl;
  late final Animation<double> _bubbleAnim;
  late final AnimationController _steamCtrl;

  @override
  void initState() {
    super.initState();
    _lidCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _lidAnim = Tween(begin: 0.0, end: 6.0).animate(
      CurvedAnimation(parent: _lidCtrl, curve: Curves.easeInOut),
    );
    _bubbleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _bubbleAnim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bubbleCtrl, curve: Curves.easeInOut),
    );
    _steamCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _lidCtrl.dispose();
    _bubbleCtrl.dispose();
    _steamCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_lidAnim, _bubbleAnim, _steamCtrl]),
      builder: (_, __) => CustomPaint(
        painter: _PotPainter(
          lidOffset: _lidAnim.value,
          bubblePhase: _bubbleAnim.value,
          steamPhase: _steamCtrl.value,
        ),
      ),
    );
  }
}

class _PotPainter extends CustomPainter {
  final double lidOffset;
  final double bubblePhase;
  final double steamPhase;

  const _PotPainter({
    required this.lidOffset,
    required this.bubblePhase,
    required this.steamPhase,
  });

  static const _potBody = Color(0xFFFFECB3);
  static const _potShade = Color(0xFFFFCC80);
  static const _potRim = Color(0xFFFFB74D);
  static const _lidColor = Color(0xFFFFF3E0);
  static const _lidShade = Color(0xFFFFCC80);
  static const _handleColor = Color(0xFFFFB300);
  static const _liquidTop = Color(0xFFFF7043);
  static const _liquidBody = Color(0xFFE64A19);
  static const _steamColor = Color(0xFFFFFFFF);
  static const _bubbleColor = Color(0xFFFF8A65);
  static const _outline = Color(0x33000000);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.50;
    final cy = size.height * 0.72;
    final potW = size.width * 0.72;
    final potH = size.height * 0.34;
    final lidH = potH * 0.22;
    final rimH = potH * 0.08;

    _drawSteam(canvas, size, cx, cy - potH / 2 - lidH - lidOffset - 8);
    _drawPotBody(canvas, cx, cy, potW, potH);
    _drawLiquid(canvas, cx, cy, potW, potH, rimH);
    _drawRim(canvas, cx, cy, potW, potH, rimH);
    _drawLid(canvas, cx, cy, potW, potH, lidH, lidOffset);
    _drawHandles(canvas, cx, cy, potW, potH);
    _drawBubbles(canvas, cx, cy, potW, potH, rimH);
  }

  void _drawPotBody(Canvas canvas, double cx, double cy, double w, double h) {
    final rect = RRect.fromRectAndCorners(
      Rect.fromCenter(center: Offset(cx, cy), width: w, height: h),
      topLeft: const Radius.circular(6),
      topRight: const Radius.circular(6),
      bottomLeft: const Radius.circular(20),
      bottomRight: const Radius.circular(20),
    );
    canvas.drawRRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            colors: [_potBody, _potShade],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(rect.outerRect));
    canvas.drawRRect(
        rect,
        Paint()
          ..color = _outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }

  void _drawLiquid(
      Canvas canvas, double cx, double cy, double w, double h, double rimH) {
    final liquidTop = cy - h / 2 + rimH + 2;
    final wobble = bubblePhase * 3;
    final path = Path()
      ..moveTo(cx - w / 2 + 8, liquidTop + wobble)
      ..quadraticBezierTo(
          cx, liquidTop - wobble, cx + w / 2 - 8, liquidTop + wobble)
      ..lineTo(cx + w / 2 - 8, cy + h / 2 - 20)
      ..quadraticBezierTo(cx, cy + h / 2 - 10, cx - w / 2 + 8, cy + h / 2 - 20)
      ..close();
    canvas.drawPath(
        path,
        Paint()
          ..shader = const LinearGradient(
            colors: [_liquidTop, _liquidBody],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(path.getBounds()));
  }

  void _drawRim(
      Canvas canvas, double cx, double cy, double w, double h, double rimH) {
    final rimRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, cy - h / 2 + rimH / 2),
        width: w + 8,
        height: rimH,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(rimRect, Paint()..color = _potRim);
    canvas.drawRRect(
        rimRect,
        Paint()
          ..color = _outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
  }

  void _drawLid(Canvas canvas, double cx, double cy, double w, double h,
      double lidH, double offset) {
    final top = cy - h / 2 - lidH - offset;
    final lidPath = Path()
      ..moveTo(cx - w / 2 + 4, cy - h / 2 - offset)
      ..quadraticBezierTo(cx, top, cx + w / 2 - 4, cy - h / 2 - offset)
      ..close();
    canvas.drawPath(
        lidPath,
        Paint()
          ..shader = const LinearGradient(
            colors: [_lidColor, _lidShade],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(
            Rect.fromPoints(
                Offset(cx - w / 2, top), Offset(cx + w / 2, cy - h / 2)),
          ));
    canvas.drawPath(
        lidPath,
        Paint()
          ..color = _outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    final knobRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, top - 8), width: 18, height: 14),
      const Radius.circular(7),
    );
    canvas.drawRRect(knobRect, Paint()..color = _handleColor);
    canvas.drawRRect(
        knobRect,
        Paint()
          ..color = _outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
  }

  void _drawHandles(Canvas canvas, double cx, double cy, double w, double h) {
    for (final side in [-1.0, 1.0]) {
      final hx = cx + side * (w / 2 + 14);
      final hy = cy - h / 4;
      final handleRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(hx, hy), width: 20, height: 26),
        const Radius.circular(10),
      );
      canvas.drawRRect(handleRect, Paint()..color = _handleColor);
      canvas.drawRRect(
          handleRect,
          Paint()
            ..color = _outline
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(hx, hy), width: 10, height: 14),
        Paint()..color = const Color(0x40000000),
      );
    }
  }

  void _drawBubbles(
      Canvas canvas, double cx, double cy, double w, double h, double rimH) {
    final liquidTop = cy - h / 2 + rimH + 4;
    final bubblePaint = Paint()
      ..color = _bubbleColor.withValues(alpha: 0.6 + bubblePhase * 0.4);
    final bubbles = [
      (cx - w * 0.18, liquidTop + 6 - bubblePhase * 4, 4.0),
      (cx + w * 0.05, liquidTop + 2 - bubblePhase * 3, 5.5),
      (cx + w * 0.22, liquidTop + 8 - bubblePhase * 5, 3.5),
    ];
    for (final (bx, by, br) in bubbles) {
      canvas.drawCircle(Offset(bx, by), br, bubblePaint);
    }
  }

  void _drawSteam(Canvas canvas, Size size, double cx, double baseY) {
    final columns = [
      (cx - 18.0, 0.0),
      (cx, 0.33),
      (cx + 18.0, 0.67),
    ];
    for (final (sx, phaseOffset) in columns) {
      for (int i = 0; i < 2; i++) {
        final puffPhase = (steamPhase + phaseOffset + i * 0.5) % 1.0;
        final progress = Curves.easeOut.transform(puffPhase);
        final py = baseY - progress * 60;
        final drift = (puffPhase * 2 - 1) * 8;
        final radius = 6.0 + progress * 12;
        final alpha = (1 - progress) * 0.55;
        if (alpha <= 0) continue;
        canvas.drawCircle(
          Offset(sx + drift, py),
          radius,
          Paint()..color = _steamColor.withValues(alpha: alpha),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PotPainter old) =>
      old.lidOffset != lidOffset ||
      old.bubblePhase != bubblePhase ||
      old.steamPhase != steamPhase;
}

// ─── Mic Button ───────────────────────────────────────────────────────────────

class _MicButton extends StatefulWidget {
  final bool isListening;
  const _MicButton({required this.isListening});

  @override
  State<_MicButton> createState() => _MicButtonState();
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

// ─── Inline Voice Mic ─────────────────────────────────────────────────────────

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

// ─── Suggestion Tile ──────────────────────────────────────────────────────────

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

// ─── Highlighted Text ─────────────────────────────────────────────────────────

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

// ─── Search Bar Delegate ──────────────────────────────────────────────────────

class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _SearchBarDelegate({required this.child});

  @override
  double get minExtent => 64;
  @override
  double get maxExtent => 64;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      alignment: Alignment.center,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _SearchBarDelegate oldDelegate) => true;
}
