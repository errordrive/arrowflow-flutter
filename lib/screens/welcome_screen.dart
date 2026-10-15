// ArrowFlow — welcome / onboarding (original terms copy).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../audio.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'tabs_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const _terms = '''
Welcome to ArrowFlow!

ArrowFlow is a one-tap logic puzzle. Tap an arrow to slide it off the board in the direction it points — but only if its exit path is clear. Clear every arrow to win the level.

• You have 3 hearts per level. Tapping a blocked arrow costs 1 heart.
• Hints highlight a free arrow. Erasers remove any single arrow.
• Daily Challenges give you a gold star every day you win.

By tapping "I Agree" you accept these terms:
• ArrowFlow is provided as-is for entertainment.
• Your progress is stored only on this device.
• Ads (test ads in this build) support development.

Play fair, have fun!
''';

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.arrow_upward, size: 56, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Text('ArrowFlow',
                  style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: theme.text)),
              const SizedBox(height: 4),
              Text('One-tap arrow puzzle',
                  style: TextStyle(fontSize: 15, color: theme.muted)),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.border),
                  ),
                  child: const SingleChildScrollView(
                    child: Text(_terms,
                        style: TextStyle(fontSize: 14, height: 1.5)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Sounds.instance.play('click');
                  context.read<AppState>().setOnboarded();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const TabsScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                ),
                child:
                    const Text('I Agree — Start Playing', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
