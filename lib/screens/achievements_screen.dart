// ArrowFlow — achievements.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme.dart';

class _Achievement {
  final String title;
  final String desc;
  final IconData icon;
  final bool Function(AppState) unlocked;
  const _Achievement(this.title, this.desc, this.icon, this.unlocked);
}

final _achievements = [
  _Achievement('First Steps', 'Clear level 1', Icons.play_arrow,
      (s) => s.level > 1),
  _Achievement('Getting Warm', 'Reach level 10', Icons.whatshot,
      (s) => s.level > 10),
  _Achievement('Puzzle Solver', 'Reach level 50', Icons.psychology,
      (s) => s.level > 50),
  _Achievement('Arrow Master', 'Reach level 100', Icons.military_tech,
      (s) => s.level > 100),
  _Achievement('Centurion', 'Reach level 200', Icons.workspace_premium,
      (s) => s.level > 200),
  _Achievement(
      'Daily Grinder', 'Complete 5 daily challenges', Icons.calendar_month,
      (s) =>
          s.dailyDone.values.where((v) => v).length >= 5),
  _Achievement('Star Collector', 'Earn 10 stars', Icons.star,
      (s) => s.stars.values.fold<int>(0, (a, b) => a + b) >= 10),
  _Achievement('Rich', 'Hold 1000 coins', Icons.monetization_on,
      (s) => s.coins >= 1000),
];

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final state = context.watch<AppState>();
    final unlockedCount =
        _achievements.where((a) => a.unlocked(state)).length;

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: theme.bg,
        foregroundColor: theme.text,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('$unlockedCount / ${_achievements.length} unlocked',
              style: TextStyle(color: theme.muted, fontSize: 14)),
          const SizedBox(height: 12),
          ..._achievements.map((a) {
            final un = a.unlocked(state);
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: un ? theme.primary : theme.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: un
                          ? theme.primarySoft
                          : theme.bg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(a.icon,
                        color: un ? theme.primary : theme.muted,
                        size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.title,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: theme.text)),
                        Text(a.desc,
                            style: TextStyle(
                                fontSize: 13, color: theme.muted)),
                      ],
                    ),
                  ),
                  if (un)
                    const Icon(Icons.check_circle,
                        color: Colors.green),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
