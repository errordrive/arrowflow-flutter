// ArrowFlow — awards (star chests, PRD §7).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../audio.dart';
import '../game/daily.dart';
import '../game/economy.dart';
import '../state/app_state.dart';
import '../theme.dart';

class AwardsScreen extends StatelessWidget {
  const AwardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final state = context.watch<AppState>();
    final stars = state.stars[monthKey()] ?? 0;

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        title: const Text('Awards'),
        backgroundColor: theme.bg,
        foregroundColor: theme.text,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, size: 40, color: Colors.white),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$stars stars this month',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                    const Text('Win daily challenges to earn stars',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...starChests.map((chest) {
            final reached = stars >= chest.stars;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: reached ? theme.gold : theme.border,
                    width: reached ? 2 : 1),
              ),
              child: Row(
                children: [
                  Icon(
                    reached ? Icons.emoji_events : Icons.lock_outline,
                    color: reached ? theme.gold : theme.muted,
                    size: 32,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${chest.stars} stars',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: theme.text)),
                        Text(chest.reward,
                            style: TextStyle(
                                fontSize: 13, color: theme.muted)),
                      ],
                    ),
                  ),
                  if (reached)
                    ElevatedButton(
                      onPressed: () {
                        Sounds.instance.play('success');
                        // Simple claim: grant a small coin bonus per chest.
                        // (Full chest inventory rewards are a TODO.)
                        state.addCoins(25);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Chest claimed: +25 coins!'),
                              duration: Duration(seconds: 1)),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.gold,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Claim'),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
