// ArrowFlow — global app state (ChangeNotifier + SharedPreferences).
// Mirrors src/state/store.ts from the original.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/economy.dart';

class AppState extends ChangeNotifier {
  static const _prefsKey = 'arrowflow-state-v1';

  int level = 1;
  int coins = Economy.startingCoins;
  int hints = Economy.startingHints;
  int erasers = Economy.startingErasers;
  int extraHearts = Economy.startingExtraHearts;
  Map<String, int> stars = {}; // monthKey -> star count
  Map<String, bool> dailyDone = {}; // dailyKey -> true
  bool sounds = true;
  bool vibration = true;
  bool autoLock = false;
  bool darkMode = false;
  bool removedAds = false;
  bool onboarded = false;

  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        level = (m['level'] as num?)?.toInt() ?? 1;
        coins = (m['coins'] as num?)?.toInt() ?? Economy.startingCoins;
        hints = (m['hints'] as num?)?.toInt() ?? Economy.startingHints;
        erasers = (m['erasers'] as num?)?.toInt() ?? Economy.startingErasers;
        extraHearts =
            (m['extraHearts'] as num?)?.toInt() ?? Economy.startingExtraHearts;
        stars = Map<String, int>.from(
            (m['stars'] as Map?)?.map((k, v) => MapEntry('$k', (v as num).toInt())) ?? {});
        dailyDone = Map<String, bool>.from(
            (m['dailyDone'] as Map?)?.map((k, v) => MapEntry('$k', v == true)) ?? {});
        sounds = m['sounds'] as bool? ?? true;
        vibration = m['vibration'] as bool? ?? true;
        autoLock = m['autoLock'] as bool? ?? false;
        darkMode = m['darkMode'] as bool? ?? false;
        removedAds = m['removedAds'] as bool? ?? false;
        onboarded = m['onboarded'] as bool? ?? false;
      } catch (_) {
        // corrupted prefs: keep defaults
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode({
        'level': level,
        'coins': coins,
        'hints': hints,
        'erasers': erasers,
        'extraHearts': extraHearts,
        'stars': stars,
        'dailyDone': dailyDone,
        'sounds': sounds,
        'vibration': vibration,
        'autoLock': autoLock,
        'darkMode': darkMode,
        'removedAds': removedAds,
        'onboarded': onboarded,
      }),
    );
  }

  void _update() {
    notifyListeners();
    _save();
  }

  int _clampInv(int n) => n.clamp(0, Economy.maxInventory);

  void completeLevel(int clearedLevel, int coinsEarned) {
    if (clearedLevel + 1 > level) level = clearedLevel + 1;
    coins += coinsEarned;
    _update();
  }

  void addCoins(int n) {
    coins += n;
    _update();
  }

  bool spendCoins(int n) {
    if (coins < n) return false;
    coins -= n;
    _update();
    return true;
  }

  void addHints(int n) {
    hints = _clampInv(hints + n);
    _update();
  }

  bool useHint() {
    if (hints < 1) return false;
    hints--;
    _update();
    return true;
  }

  void addErasers(int n) {
    erasers = _clampInv(erasers + n);
    _update();
  }

  bool useEraser() {
    if (erasers < 1) return false;
    erasers--;
    _update();
    return true;
  }

  void addExtraHearts(int n) {
    extraHearts = _clampInv(extraHearts + n);
    _update();
  }

  bool useExtraHeart() {
    if (extraHearts < 1) return false;
    extraHearts--;
    _update();
    return true;
  }

  void completeDaily(String dateKey, String month) {
    dailyDone[dateKey] = true;
    stars[month] = (stars[month] ?? 0) + 1;
    coins += Economy.dailyRewardCoins;
    _update();
  }

  void setSounds(bool v) {
    sounds = v;
    _update();
  }

  void setVibration(bool v) {
    vibration = v;
    _update();
  }

  void setAutoLock(bool v) {
    autoLock = v;
    _update();
  }

  void setDarkMode(bool v) {
    darkMode = v;
    _update();
  }

  void setRemovedAds(bool v) {
    removedAds = v;
    _update();
  }

  void setOnboarded() {
    onboarded = true;
    _update();
  }

  void resetAll() {
    level = 1;
    coins = Economy.startingCoins;
    hints = Economy.startingHints;
    erasers = Economy.startingErasers;
    extraHearts = Economy.startingExtraHearts;
    stars = {};
    dailyDone = {};
    sounds = true;
    vibration = true;
    autoLock = false;
    darkMode = false;
    removedAds = false;
    onboarded = false;
    _update();
  }
}
