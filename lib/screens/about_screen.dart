// ArrowFlow — about screen (original copy).

import 'package:flutter/material.dart';

import '../theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: theme.bg,
        foregroundColor: theme.text,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: theme.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.arrow_upward,
                  size: 56, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text('ArrowFlow',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: theme.text)),
            Text('Version 1.0.0',
                style: TextStyle(color: theme.muted)),
            const SizedBox(height: 24),
            Text(
              'ArrowFlow is an original one-tap logic puzzle game.\n\n'
              'Tap an arrow to slide it off the board in the direction it points — '
              'but only if its exit path is clear. Plan your removal order, '
              'protect your hearts, and clear every arrow to win.\n\n'
              'All puzzles are generated on your device with a deterministic '
              'algorithm, so every player in the world gets the same Level N.\n\n'
              'Made with Flutter.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: theme.muted, fontSize: 15, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
