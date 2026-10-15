// ArrowFlow — privacy policy (original copy).

import 'package:flutter/material.dart';

import '../theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const _body = '''
Privacy Policy — ArrowFlow

Last updated: October 2026

1. Data we store
ArrowFlow stores your game progress (level, coins, items, stars, settings)
only on your device. We do not operate servers and do not receive your data.

2. Advertising
This app may show ads via Google AdMob (test ads in this build). AdMob may
collect device identifiers to serve ads, per Google's privacy policy:
https://policies.google.com/privacy

3. No accounts
There are no accounts, no sign-in, and no social features. Nothing you do in
the app is linked to your identity by us.

4. Children
ArrowFlow is a general-audience puzzle game and does not knowingly collect
data from children.

5. Changes
If this policy changes, the updated version will ship with the app.

Contact: support via the Help screen.
''';

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: theme.bg,
        foregroundColor: theme.text,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Text(_body,
            style:
                TextStyle(color: theme.text, fontSize: 14, height: 1.6)),
      ),
    );
  }
}
