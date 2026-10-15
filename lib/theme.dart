// ArrowFlow — app theme (light + dark).

import 'package:flutter/material.dart';

class AppTheme {
  final Color bg;
  final Color card;
  final Color text;
  final Color muted;
  final Color primary;
  final Color primarySoft;
  final Color border;
  final Color heart;
  final Color gold;
  final Color arrow;
  final Brightness brightness;

  const AppTheme({
    required this.bg,
    required this.card,
    required this.text,
    required this.muted,
    required this.primary,
    required this.primarySoft,
    required this.border,
    required this.heart,
    required this.gold,
    required this.arrow,
    required this.brightness,
  });

  static const light = AppTheme(
    bg: Color(0xFFF7F9FF),
    card: Color(0xFFFFFFFF),
    text: Color(0xFF1A2233),
    muted: Color(0xFF6B7690),
    primary: Color(0xFF2F6DF6),
    primarySoft: Color(0xFFE3EBFE),
    border: Color(0xFFE2E8F5),
    heart: Color(0xFFFF3B5C),
    gold: Color(0xFFFFB800),
    arrow: Color(0xFF2F6DF6),
    brightness: Brightness.light,
  );

  static const dark = AppTheme(
    bg: Color(0xFF0E1424),
    card: Color(0xFF1A2338),
    text: Color(0xFFF2F5FF),
    muted: Color(0xFF93A0C0),
    primary: Color(0xFF5B8DEF),
    primarySoft: Color(0xFF22345C),
    border: Color(0xFF2A3752),
    heart: Color(0xFFFF5C7A),
    gold: Color(0xFFFFC93B),
    arrow: Color(0xFF5B8DEF),
    brightness: Brightness.dark,
  );
}

extension ThemeOf on BuildContext {
  AppTheme get appTheme =>
      Theme.of(this).brightness == Brightness.dark ? AppTheme.dark : AppTheme.light;
}
