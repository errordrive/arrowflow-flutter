// ArrowFlow — settings screen.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../audio.dart';
import '../state/app_state.dart';
import '../theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final state = context.watch<AppState>();

    Widget toggle(
        String title, String sub, bool value, ValueChanged<bool> onChanged) {
      return SwitchListTile(
        title: Text(title,
            style:
                TextStyle(color: theme.text, fontWeight: FontWeight.w600)),
        subtitle:
            Text(sub, style: TextStyle(color: theme.muted, fontSize: 13)),
        value: value,
        activeThumbColor: theme.primary,
        onChanged: (v) {
          Sounds.instance.play('click');
          onChanged(v);
        },
      );
    }

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: theme.bg,
        foregroundColor: theme.text,
        elevation: 0,
      ),
      body: ListView(
        children: [
          toggle('Sounds', 'Play sound effects', state.sounds,
              (v) => state.setSounds(v)),
          toggle('Vibration', 'Haptic feedback on taps', state.vibration,
              (v) => state.setVibration(v)),
          toggle('Auto-Lock', 'Lock the app when idle', state.autoLock,
              (v) => state.setAutoLock(v)),
          toggle('Dark Mode', 'Use the dark theme', state.darkMode,
              (v) => state.setDarkMode(v)),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Reset all progress?'),
                    content: const Text(
                        'This will erase your level, coins, items and stars.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(c).pop(false),
                          child: const Text('Cancel')),
                      TextButton(
                          onPressed: () => Navigator.of(c).pop(true),
                          child: const Text('Reset',
                              style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (ok == true) state.resetAll();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Reset All Progress'),
            ),
          ),
        ],
      ),
    );
  }
}
