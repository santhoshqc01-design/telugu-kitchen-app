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
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (value.length > 2) {
        context.read<RecipeBloc>().add(SearchRecipes(value));
      }
    });
  }

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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.appName,
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_outline),
            selectedIcon: const Icon(Icons.favorite),
            label: l10n.favorites,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.settings,
          ),
        ],
      ),
      // IMPROVED: Compact FAB instead of extended (fixes overlap)
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () => _showVoiceSearch(context),
              backgroundColor: Colors.orange.shade800,
              child: const Icon(Icons.mic, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildHomeTab(AppLocalizations l10n, bool isTelugu) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<RecipeBloc>().add(const LoadRecipes());
      },
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                isTelugu ? 'రుచి' : 'Ruchi',
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
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.orange.shade800,
                      Colors.orange.shade600,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.restaurant_menu,
                    size: 80,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBar(l10n),
                  const SizedBox(height: 24),
                  _buildCategories(l10n, isTelugu),
                  const SizedBox(height: 24),
                  _buildRegions(l10n, isTelugu),
                  const SizedBox(height: 24),
                  _buildSectionHeader(isTelugu),
                ],
              ),
            ),
          ),
          _buildRecipeGrid(),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations l10n) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: l10n.searchHint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  context.read<RecipeBloc>().add(const LoadRecipes());
                  setState(() {});
                },
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

  Widget _buildCategories(AppLocalizations l10n, bool isTelugu) {
    final categories = [
      ('breakfast', Icons.breakfast_dining, Colors.orange, 'ఉదయం భోజనం'),
      ('lunch', Icons.lunch_dining, Colors.green, 'మధ్యాహ్న భోజనం'),
      ('dinner', Icons.dinner_dining, Colors.purple, 'రాత్రి భోజనం'),
      ('snacks', Icons.cookie, Colors.pink, 'స్నాక్స్'),
      ('desserts', Icons.cake, Colors.red, 'డెజర్ట్స్'),
      ('beverages', Icons.local_cafe, Colors.brown, 'పానీయాలు'),
    ];

    return SizedBox(
      height: 110, // Increased height
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final (key, icon, color, teluguName) = categories[index];
          final displayName =
              isTelugu ? teluguName : _getCategoryName(l10n, key);

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 80, // Fixed width
              child: Column(
                children: [
                  InkWell(
                    onTap: () => context.read<RecipeBloc>().add(
                          FilterByCategory(key.capitalize()),
                        ),
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(icon, color: color, size: 32),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    displayName,
                    style: const TextStyle(fontSize: 11), // Smaller font
                    textAlign: TextAlign.center,
                    maxLines: 2, // Allow 2 lines
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRegions(AppLocalizations l10n, bool isTelugu) {
    final regions = [
      ('andhra', Colors.orange),
      ('telangana', Colors.pink),
      ('rayalaseema', Colors.green),
    ];

    return Row(
      children: regions.map((region) {
        final (name, color) = region;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => context.read<RecipeBloc>().add(
                    FilterByRegion(name.capitalize()),
                  ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.8),
                      color.withOpacity(0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getRegionName(l10n, name),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(bool isTelugu) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          isTelugu ? 'ప్రత్యేక వంటకాలు' : 'Featured Recipes',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        TextButton(
          onPressed: () {
            // Could add view all functionality
          },
          child: Text(
            isTelugu ? 'అన్నీ చూడు' : 'View All',
            style: TextStyle(color: Colors.orange.shade800),
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeGrid() {
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
                (context, index) => const ShimmerRecipeCard(),
                childCount: 6,
              ),
            ),
          );
        }

        if (state is RecipeLoaded) {
          if (state.recipes.isEmpty) {
            return SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(AppLocalizations.of(context).noRecipes),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<RecipeBloc>().add(const LoadRecipes());
                      },
                      child: const Text('Clear Filters'),
                    ),
                  ],
                ),
              ),
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
                  return RecipeCard(
                    recipe: state.recipes[index],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecipeDetailScreen(
                          recipe: state.recipes[index],
                        ),
                      ),
                    ),
                  );
                },
                childCount: state.recipes.length,
              ),
            ),
          );
        }

        return const SliverFillRemaining(
          child: Center(child: Text('Error loading recipes')),
        );
      },
    );
  }

  void _showVoiceSearch(BuildContext context) {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Voice search works best on mobile. Please type your search.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to resize
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width - 32, // Margin on sides
      ),
      builder: (context) => const VoiceSearchSheet(),
    );
  }

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

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

// IMPROVED: Shimmer loading card
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
            Expanded(
              flex: 3,
              child: Container(color: Colors.white),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 60,
                      color: Colors.white,
                    ),
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

// IMPROVED: RecipeCard with better image handling
// IMPROVED: RecipeCard with better image handling and more info
class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isTelugu = context.watch<LanguageBloc>().state.isTelugu;

    return Hero(
      tag: 'recipe-${recipe.id}',
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.orange.withOpacity(0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // IMPROVED: Better image loading with fallback
                    _buildImage(),

                    // Region badge (top left)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _getRegionColor(recipe.region).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          recipe.region,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Veg/Non-Veg badge (top right)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              recipe.isVegetarian ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              recipe.isVegetarian
                                  ? Icons.circle
                                  : Icons.restaurant,
                              color: Colors.white,
                              size: 10,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              recipe.isVegetarian ? 'Veg' : 'Non-Veg',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Difficulty badge (bottom left)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          recipe.difficulty,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          _buildStat(
                            Icons.timer,
                            '${recipe.cookTimeMinutes} min',
                            Colors.grey.shade600,
                          ),
                          const SizedBox(width: 12),
                          _buildStat(
                            Icons.star,
                            recipe.rating.toString(),
                            Colors.amber,
                          ),
                          const SizedBox(width: 12),
                          _buildStat(
                            Icons.local_fire_department,
                            '${recipe.calories}',
                            Colors.orange,
                          ),
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
      // ERROR HANDLER - Shows placeholder on error
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey.shade200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.restaurant,
                size: 50,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 8),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _getRegionColor(recipe.region).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    recipe.titleTe.isNotEmpty
                        ? recipe.titleTe[0]
                        : recipe.title[0],
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _getRegionColor(recipe.region),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No Image',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
      // LOADING HANDLER - Shows shimmer while loading
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            color: Colors.white,
          ),
        );
      },
    );
  }

  Widget _buildStat(IconData icon, String value, Color color) {
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

  Color _getRegionColor(String region) {
    switch (region) {
      case 'Andhra':
        return Colors.orange;
      case 'Telangana':
        return Colors.pink;
      case 'Rayalaseema':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }
}

class VoiceSearchSheet extends StatelessWidget {
  const VoiceSearchSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTelugu = context.watch<LanguageBloc>().state.isTelugu;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final isVerySmallScreen = screenSize.width < 320;

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenSize.height * 0.5,
        minHeight: 300,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: isSmallScreen ? 16 : 24),

            // Title
            Text(
              l10n.voiceCommands,
              style: TextStyle(
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),

            // Subtitle
            Text(
              l10n.speakNow,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallScreen ? 24 : 32),

            // Mic button with responsive size
            BlocConsumer<VoiceBloc, VoiceState>(
              listener: (context, state) {
                if (state is VoiceSearchResult) {
                  // Use new state
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
                final micSize =
                    isVerySmallScreen ? 80 : (isSmallScreen ? 100 : 120);

                return GestureDetector(
                  onTap: () {
                    if (isListening) {
                      context.read<VoiceBloc>().add(const StopListening());
                    } else {
                      context.read<VoiceBloc>().add(
                            StartListening(
                              localeId: isTelugu ? 'te_IN' : 'en_US',
                            ),
                          );
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: micSize.toDouble(),
                    height: micSize.toDouble(),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isListening ? Colors.red : Colors.orange,
                      boxShadow: [
                        BoxShadow(
                          color: (isListening ? Colors.red : Colors.orange)
                              .withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      isListening ? Icons.mic : Icons.mic_none,
                      size: isVerySmallScreen ? 32 : (isSmallScreen ? 40 : 48),
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: isSmallScreen ? 16 : 24),

            // Examples with wrapping
            if (!isVerySmallScreen) ...[
              Text(
                isTelugu ? 'ఉదాహరణలు:' : 'Examples:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: isTelugu
                    ? [
                        _buildExampleChip('"బిర్యానీ"'),
                        _buildExampleChip('"గోంగూర"'),
                        _buildExampleChip('"ఉదయం భోజనం"'),
                      ]
                    : [
                        _buildExampleChip('"Biryani"'),
                        _buildExampleChip('"Gongura"'),
                        _buildExampleChip('"Breakfast"'),
                      ],
              ),
            ],
            SizedBox(height: isSmallScreen ? 16 : 24),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleChip(String text) {
    return Chip(
      label: Text(
        text,
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
