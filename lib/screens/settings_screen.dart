import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../blocs/language/language_bloc.dart';
import '../blocs/favorites/favorites_bloc.dart';
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
        padding: const EdgeInsets.all(16),
        children: [
          // Profile/Header Section
          _buildHeader(isTelugu),
          const SizedBox(height: 24),
          
          // Appearance Section
          _buildSectionTitle(isTelugu ? 'రూపం' : 'Appearance', isTelugu),
          const SizedBox(height: 8),
          _buildLanguageCard(context, isTelugu, l10n),
          const SizedBox(height: 16),
          
          // Features Section
          _buildSectionTitle(isTelugu ? 'సౌలభ్యాలు' : 'Features', isTelugu),
          const SizedBox(height: 8),
          _buildVoiceCommandsCard(isTelugu),
          const SizedBox(height: 8),
          _buildFavoritesCard(context, isTelugu),
          const SizedBox(height: 16),
          
          // About Section
          _buildSectionTitle(isTelugu ? 'అప్లికేషన్ గురించి' : 'About App', isTelugu),
          const SizedBox(height: 8),
          _buildAboutCard(isTelugu),
          const SizedBox(height: 8),
          _buildShareCard(context, isTelugu),
          const SizedBox(height: 8),
          _buildRateCard(context, isTelugu),
          const SizedBox(height: 24),
          
          // Footer
          _buildFooter(isTelugu),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isTelugu) {
    return Center(
      child: Column(
        children: [
          // Animated app icon
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 500),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.shade600,
                        Colors.orange.shade800,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.restaurant_menu,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Ruchi - రుచి',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isTelugu ? 'సాంప్రదాయ తెలుగు వంటకాలు' : 'Traditional Telugu Cuisine',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isTelugu) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildLanguageCard(BuildContext context, bool isTelugu, AppLocalizations l10n) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.translate,
                    color: Colors.orange.shade800,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.language,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isTelugu ? 'అనువాద భాషను మార్చండి' : 'Change app language',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildLanguageOption(
                  'English',
                  '🇺🇸',
                  !isTelugu,
                  () {
                    if (isTelugu) {
                      context.read<LanguageBloc>().add(
                        const ChangeLanguage(Locale('en', 'US')),
                      );
                    }
                  },
                ),
                const SizedBox(width: 12),
                _buildLanguageOption(
                  'తెలుగు',
                  '🇮🇳',
                  isTelugu,
                  () {
                    if (!isTelugu) {
                      context.read<LanguageBloc>().add(
                        const ChangeLanguage(Locale('te', 'IN')),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    String label,
    String flag,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.orange.shade100 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Colors.orange.shade800 : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(flag, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.orange.shade800 : Colors.grey.shade700,
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Colors.orange.shade800,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceCommandsCard(bool isTelugu) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.mic, color: Colors.blue),
        ),
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
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Show voice commands help dialog
        },
      ),
    );
  }

  Widget _buildFavoritesCard(BuildContext context, bool isTelugu) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: BlocBuilder<FavoritesBloc, FavoritesState>(
        builder: (context, state) {
          int count = 0;
          if (state is FavoritesLoaded) {
            count = state.favorites.length;
          }
          
          return ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.favorite, color: Colors.red),
            ),
            title: Text(
              isTelugu ? 'ఇష్టమైనవి' : 'Favorites',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              count > 0
                  ? (isTelugu ? '$count వంటకాలు' : '$count recipes saved')
                  : (isTelugu ? 'ఇంకా ఏమీ లేదు' : 'Nothing saved yet'),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (count > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
            onTap: () {
              // Navigate to favorites tab
            },
          );
        },
      ),
    );
  }

  Widget _buildAboutCard(bool isTelugu) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.purple.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.info, color: Colors.purple),
            ),
            title: Text(
              isTelugu ? 'వర్షన్' : 'Version',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
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
          const Divider(height: 1),
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.teal.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.code, color: Colors.teal),
            ),
            title: Text(
              isTelugu ? 'డెవలపర్' : 'Developer',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Made with ❤️ for Telugu food lovers'),
          ),
        ],
      ),
    );
  }

  Widget _buildShareCard(BuildContext context, bool isTelugu) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.share, color: Colors.green),
        ),
        title: Text(
          isTelugu ? 'షేర్ చేయండి' : 'Share App',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          isTelugu ? 'స్నేహితులకు పంపండి' : 'Tell your friends',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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

  Widget _buildRateCard(BuildContext context, bool isTelugu) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.amber.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.star, color: Colors.amber),
        ),
        title: Text(
          isTelugu ? 'రేట్ చేయండి' : 'Rate Us',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          isTelugu ? 'మీ అభిప్రాయం మాకు ముఖ్యం' : 'Your feedback matters',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            5,
            (index) => Icon(
              Icons.star,
              size: 16,
              color: Colors.amber.shade300,
            ),
          ),
        ),
        onTap: () {
          // Open app store rating
        },
      ),
    );
  }

  Widget _buildFooter(bool isTelugu) {
    return Center(
      child: Column(
        children: [
          Text(
            '© 2024 Ruchi - రుచి',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isTelugu ? 'సంప్రదాయం కలిసి రుచి' : 'Tradition meets Taste',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade400,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}