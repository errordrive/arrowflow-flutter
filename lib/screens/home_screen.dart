// ArrowFlow — home tab.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../audio.dart';
import '../game/daily.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/ad_banner.dart';
import 'game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _fmtDate() {
    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final state = context.watch<AppState>();
    final done = state.dailyDone[dailyKey()] ?? false;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.monetization_on, size: 18, color: Color(0xFFFFB800)),
                const SizedBox(width: 4),
                Text('${state.coins}',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: theme.text)),
              ],
            ),
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Sounds.instance.play('click');
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => GameScreen(dailyKey: dailyKey())));
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.calendar_month,
                        size: 28, color: Colors.white),
                    const SizedBox(height: 8),
                    const Text('DAILY CHALLENGE',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2)),
                    const SizedBox(height: 2),
                    Text(_fmtDate(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(done ? 'Completed ★' : 'Play',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: theme.primary)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text('ArrowFlow',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: theme.text)),
            const SizedBox(height: 6),
            Text('Tap an arrow to slide it off the board',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: theme.muted)),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Sounds.instance.play('click');
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => GameScreen(level: state.level)));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('New Game',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  Text('Level ${state.level}',
                      style: const TextStyle(
                          fontSize: 13, color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const AdBanner(),
          ],
        ),
      ),
    );
  }
}
