// ArrowFlow — Me tab (profile, awards, achievements, settings links).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../audio.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'about_screen.dart';
import 'achievements_screen.dart';
import 'awards_screen.dart';
import 'help_screen.dart';
import 'privacy_screen.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';

class MeScreen extends StatelessWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final state = context.watch<AppState>();
    final totalStars =
        state.stars.values.fold<int>(0, (a, b) => a + b);

    Widget tile({
      required IconData icon,
      required String title,
      String? trailing,
      required VoidCallback onTap,
    }) {
      return InkWell(
        onTap: () {
          Sounds.instance.play('click');
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: theme.card,
            border: Border(bottom: BorderSide(color: theme.border)),
          ),
          child: Row(
            children: [
              Icon(icon, color: theme.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.text)),
              ),
              if (trailing != null)
                Text(trailing,
                    style:
                        TextStyle(fontSize: 14, color: theme.muted)),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, color: theme.muted),
            ],
          ),
        ),
      );
    }

    void go(Widget page) => Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => page));

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: theme.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person,
                  size: 48, color: theme.primary),
            ),
          ),
          const SizedBox(height: 12),
          Text('Player',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: theme.text)),
          const SizedBox(height: 4),
          Text('Level ${state.level}  •  ★ $totalStars stars',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: theme.muted)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _stat(theme, Icons.monetization_on, '${state.coins}', 'Coins',
                  const Color(0xFFFFB800)),
              _stat(theme, Icons.lightbulb, '${state.hints}', 'Hints',
                  theme.gold),
              _stat(theme, Icons.delete_outline, '${state.erasers}',
                  'Erasers', theme.primary),
              _stat(theme, Icons.favorite, '${state.extraHearts}', 'Hearts',
                  theme.heart),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                tile(
                    icon: Icons.emoji_events,
                    title: 'Awards',
                    onTap: () => go(const AwardsScreen())),
                tile(
                    icon: Icons.military_tech,
                    title: 'Achievements',
                    onTap: () => go(const AchievementsScreen())),
                tile(
                    icon: Icons.shopping_bag,
                    title: 'Shop',
                    onTap: () => go(const ShopScreen())),
                tile(
                    icon: Icons.settings,
                    title: 'Settings',
                    onTap: () => go(const SettingsScreen())),
                tile(
                    icon: Icons.help_outline,
                    title: 'Help',
                    onTap: () => go(const HelpScreen())),
                tile(
                    icon: Icons.info_outline,
                    title: 'About',
                    onTap: () => go(const AboutScreen())),
                tile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () => go(const PrivacyScreen())),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(AppTheme theme, IconData icon, String value, String label,
      Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: theme.text)),
        Text(label, style: TextStyle(fontSize: 12, color: theme.muted)),
      ],
    );
  }
}
