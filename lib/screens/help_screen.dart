// ArrowFlow — help / FAQ.

import 'package:flutter/material.dart';

import '../theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = [
    (
      'How do I play?',
      'Tap an arrow to slide it off the board in the direction it points. '
          'It only moves if its exit path is completely clear.'
    ),
    (
      'What happens when I tap a blocked arrow?',
      'The arrow flashes red, the board shakes, and you lose 1 heart. '
          'You have 3 hearts per level.'
    ),
    (
      'What does a Hint do?',
      'A hint highlights one arrow that is free to remove right now.'
    ),
    (
      'What does the Eraser do?',
      'Arm the eraser, then tap any arrow — even a blocked one — to remove it instantly.'
    ),
    (
      'How do I earn coins?',
      'Clearing a level earns 10 + level/10 coins, plus 5 bonus coins if you '
          'finish without losing a heart.'
    ),
    (
      'What are Daily Challenges?',
      'One special puzzle per day, the same for every player. Win it to earn a gold star.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        title: const Text('Help'),
        backgroundColor: theme.bg,
        foregroundColor: theme.text,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _faqs.length,
        itemBuilder: (context, i) {
          final (q, a) = _faqs[i];
          return Card(
            color: theme.card,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            child: ExpansionTile(
              title: Text(q,
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: theme.text)),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(a,
                      style:
                          TextStyle(color: theme.muted, height: 1.5)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
