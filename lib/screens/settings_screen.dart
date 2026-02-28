import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../blocs/language/language_bloc.dart';
import '../blocs/recipe/recipe_bloc.dart';
import '../l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTelugu = context.watch<LanguageBloc>().state.isTelugu;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          _buildHeader(isTelugu),
          const SizedBox(height: 28),
          _buildSectionTitle(isTelugu ? 'రూపం' : 'Appearance'),
          const SizedBox(height: 8),
          _buildLanguageCard(context, isTelugu, l10n),
          const SizedBox(height: 24),
          _buildSectionTitle(isTelugu ? 'సౌలభ్యాలు' : 'Features'),
          const SizedBox(height: 8),
          _buildVoiceCommandsCard(context, isTelugu),
          const SizedBox(height: 8),
          _buildFavoritesInfoCard(context, isTelugu),
          const SizedBox(height: 8),
          _buildRecipeStatsCard(context, isTelugu),
          const SizedBox(height: 24),
          _buildSectionTitle(isTelugu ? 'అప్లికేషన్ గురించి' : 'About'),
          const SizedBox(height: 8),
          _buildAboutCard(isTelugu),
          const SizedBox(height: 8),
          _buildShareCard(context, isTelugu),
          const SizedBox(height: 8),
          _buildRateCard(context, isTelugu),
          const SizedBox(height: 24),
          _buildFooter(isTelugu),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isTelugu) {
    return Center(
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (_, value, child) =>
                Transform.scale(scale: value, child: child),
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.orange.shade500, Colors.orange.shade800],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.restaurant_menu_rounded,
                size: 44,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ruchi · రుచి',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.orange.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isTelugu
                ? 'సాంప్రదాయ తెలుగు వంటకాలు'
                : 'Traditional Telugu Cuisine',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // ── Section Title ──────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // ── Language Card ──────────────────────────────────────────────────────────

  Widget _buildLanguageCard(
      BuildContext context, bool isTelugu, AppLocalizations l10n) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                _iconBox(Icons.translate_rounded, Colors.orange.shade100,
                    Colors.orange.shade800),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.language,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        isTelugu
                            ? 'అనువాద భాషను మార్చండి'
                            : 'Change app language',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            // Language toggles
            Row(
              children: [
                _languageOption('English', '🇺🇸', !isTelugu, () {
                  if (isTelugu) {
                    context.read<LanguageBloc>().add(
                          const ChangeLanguage(Locale('en', 'US')),
                        );
                  }
                }),
                const SizedBox(width: 12),
                _languageOption('తెలుగు', '🇮🇳', isTelugu, () {
                  if (!isTelugu) {
                    context.read<LanguageBloc>().add(
                          const ChangeLanguage(Locale('te', 'IN')),
                        );
                  }
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _languageOption(
      String label, String flag, bool selected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? Colors.orange.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? Colors.orange.shade800 : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(flag, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color:
                      selected ? Colors.orange.shade800 : Colors.grey.shade700,
                  fontSize: 13,
                ),
              ),
              if (selected) ...[
                const SizedBox(height: 4),
                Icon(Icons.check_circle_rounded,
                    color: Colors.orange.shade800, size: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Voice Commands Card ────────────────────────────────────────────────────

  Widget _buildVoiceCommandsCard(BuildContext context, bool isTelugu) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _iconBox(Icons.mic_rounded, Colors.blue.shade100, Colors.blue),
        title: Text(
          isTelugu ? 'వాయిస్ కమాండ్స్' : 'Voice Commands',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          isTelugu
              ? '"తర్వాత", "మళ్ళీ", "ఆపు" అని చెప్పండి'
              : 'Say "next", "repeat", "stop" while cooking',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
        onTap: () => _showVoiceCommandsDialog(context, isTelugu),
      ),
    );
  }

  void _showVoiceCommandsDialog(BuildContext context, bool isTelugu) {
    final commands = isTelugu
        ? [
            ('తర్వాత', 'next', 'తదుపరి దశకు వెళ్ళు'),
            ('వెనక్కి', 'back', 'మునుపటి దశకు వెళ్ళు'),
            ('మళ్ళీ', 'repeat', 'దశ మళ్ళీ చదవండి'),
            ('ఆపు', 'stop', 'వంట మోడ్ ఆపు'),
            ('టైమర్', 'timer', 'కౌంట్‌డౌన్ ప్రారంభించు'),
          ]
        : [
            ('Next', 'తర్వాత', 'Go to next step'),
            ('Back', 'వెనక్కి', 'Go to previous step'),
            ('Repeat', 'మళ్ళీ', 'Read step again'),
            ('Stop', 'ఆపు', 'Exit cooking mode'),
            ('Timer', 'టైమర్', 'Start countdown'),
          ];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          isTelugu ? 'వాయిస్ కమాండ్స్' : 'Voice Commands',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isTelugu
                  ? 'వంట మోడ్‌లో ఈ పదాలు చెప్పండి:'
                  : 'Say these words in cooking mode:',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ...commands.map((c) {
              final (cmd, alt, desc) = c;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Text(
                        '"$cmd"',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        desc,
                        style: TextStyle(
                            color: Colors.grey.shade700, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isTelugu ? 'మూసివేయి' : 'Close'),
          ),
        ],
      ),
    );
  }

  // ── Favorites Info Card ────────────────────────────────────────────────────
  // Uses RecipeBloc — no more FavoritesBloc

  Widget _buildFavoritesInfoCard(BuildContext context, bool isTelugu) {
    return BlocBuilder<RecipeBloc, RecipeState>(
      builder: (context, state) {
        final count = state is RecipeLoaded ? state.favoriteCount : 0;

        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: _iconBox(
                Icons.favorite_rounded, Colors.red.shade100, Colors.red),
            title: Text(
              isTelugu ? 'ఇష్టమైనవి' : 'Favorites',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              count > 0
                  ? (isTelugu
                      ? '$count వంటకాలు నిల్వ చేయబడ్డాయి'
                      : '$count recipes saved')
                  : (isTelugu ? 'ఇంకా ఏమీ లేదు' : 'Nothing saved yet'),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (count > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade800,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              ],
            ),
            onTap: () {
              // User can switch to Favorites via bottom nav
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isTelugu
                      ? 'దిగువ నావిగేషన్‌లో ❤️ నొక్కండి'
                      : 'Tap ❤️ in the bottom nav to view favorites'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ── Recipe Stats Card ──────────────────────────────────────────────────────

  Widget _buildRecipeStatsCard(BuildContext context, bool isTelugu) {
    return BlocBuilder<RecipeBloc, RecipeState>(
      builder: (context, state) {
        if (state is! RecipeLoaded) return const SizedBox.shrink();

        final total = state.allRecipes.length;
        final vegCount = state.allRecipes.where((r) => r.isVegetarian).length;
        final regions = state.allRecipes.map((r) => r.region).toSet().length;

        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _iconBox(Icons.bar_chart_rounded, Colors.purple.shade100,
                        Colors.purple),
                    const SizedBox(width: 14),
                    Text(
                      isTelugu ? 'రెసిపీ గణాంకాలు' : 'Recipe Stats',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statPill(
                        '$total', isTelugu ? 'మొత్తం' : 'Total', Colors.orange),
                    _statPill('$vegCount', isTelugu ? 'శాకాహారం' : 'Veg',
                        const Color(0xFF2E7D32)),
                    _statPill('${total - vegCount}',
                        isTelugu ? 'మాంసాహారం' : 'Non-Veg', Colors.red),
                    _statPill('$regions', isTelugu ? 'ప్రాంతాలు' : 'Regions',
                        Colors.blue),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statPill(String value, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  // ── About Card ─────────────────────────────────────────────────────────────

  Widget _buildAboutCard(bool isTelugu) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: _iconBox(
                Icons.info_rounded, Colors.purple.shade100, Colors.purple),
            title: Text(isTelugu ? 'వర్షన్' : 'Version',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('1.0.0'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'LATEST',
                style: TextStyle(
                  color: Colors.green.shade800,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading:
                _iconBox(Icons.code_rounded, Colors.teal.shade100, Colors.teal),
            title: Text(isTelugu ? 'డెవలపర్' : 'Developer',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              isTelugu
                  ? 'తెలుగు వంట ప్రేమికుల కోసం ❤️తో తయారైంది'
                  : 'Made with ❤️ for Telugu food lovers',
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: _iconBox(Icons.restaurant_menu_rounded,
                Colors.orange.shade100, Colors.orange.shade800),
            title: Text(isTelugu ? 'వంటకాల మూలం' : 'Recipe Source',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              isTelugu
                  ? 'ఆంధ్ర, తెలంగాణ, రాయలసీమ సాంప్రదాయ వంటకాలు'
                  : 'Authentic Andhra, Telangana & Rayalaseema cuisine',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  // ── Share Card ─────────────────────────────────────────────────────────────

  Widget _buildShareCard(BuildContext context, bool isTelugu) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading:
            _iconBox(Icons.share_rounded, Colors.green.shade100, Colors.green),
        title: Text(isTelugu ? 'షేర్ చేయండి' : 'Share App',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          isTelugu ? 'స్నేహితులకు పంపండి' : 'Tell your friends',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
        onTap: () {
          Share.share(
            isTelugu
                ? 'Ruchi యాప్ చూడండి! అద్భుతమైన తెలుగు వంటకాలు: https://ruchi.app'
                : 'Check out Ruchi app! Amazing Telugu recipes: https://ruchi.app',
          );
        },
      ),
    );
  }

  // ── Rate Card ──────────────────────────────────────────────────────────────

  Widget _buildRateCard(BuildContext context, bool isTelugu) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading:
            _iconBox(Icons.star_rounded, Colors.amber.shade100, Colors.amber),
        title: Text(isTelugu ? 'రేట్ చేయండి' : 'Rate Us',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          isTelugu ? 'మీ అభిప్రాయం మాకు ముఖ్యం' : 'Your feedback matters',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            5,
            (i) => Icon(Icons.star_rounded,
                size: 16, color: Colors.amber.shade400),
          ),
        ),
        onTap: () {
          // TODO: launch app store URL via url_launcher
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isTelugu ? 'త్వరలో వస్తుంది!' : 'Coming soon!'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────

  Widget _buildFooter(bool isTelugu) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.restaurant_menu_rounded,
              size: 20, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(
            '© 2024 Ruchi · రుచి',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 4),
          Text(
            isTelugu ? 'సంప్రదాయం కలిసి రుచి' : 'Tradition meets Taste',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade400,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared Helpers ─────────────────────────────────────────────────────────

  Widget _iconBox(IconData icon, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: fg, size: 22),
    );
  }
}
