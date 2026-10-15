# ArrowFlow — Flutter

One-tap arrow puzzle game, rewritten in Flutter from the original
React Native + TypeScript version (`~/workspace/arrowflow/`).

## Game

Tap an arrow to slide it off the board in the direction it points — only if
its exit path is clear. Tapping a blocked arrow flashes red, shakes the
board, and costs 1 heart (3 hearts per level). Clear all arrows to win.

- 500+ deterministic levels (seeded RNG: xmur3 + mulberry32, bit-for-bit
  compatible with the original for the RNG stream)
- Reverse-construction generator: solvable by construction, acyclic blocker
  graph
- Daily Challenge: one shared level per calendar day, gold stars
- Economy: 100 coins / 3 hints / 1 eraser / 1 heart to start (PRD §7)
- AdMob with Google test IDs (banner, interstitial, rewarded)

## Project layout

```
lib/
  main.dart            — entry point, theme, orientation lock
  theme.dart           — light/dark AppTheme
  ads.dart             — AdMob wrapper (test IDs, graceful degradation)
  audio.dart           — sound effects (CC0 wavs in assets/sounds/)
  game/
    types.dart         — Dir, Cell, Arrow, LevelData, Badge
    rng.dart           — seeded RNG (verified against the TS original)
    generator.dart     — deterministic level generator
    economy.dart       — prices, rewards
    daily.dart         — date keys
  state/
    app_state.dart     — ChangeNotifier store + SharedPreferences
  widgets/
    game_board.dart    — CustomPainter board, tap detection, animations
    confetti.dart      — level-complete confetti
    ad_banner.dart     — AdMob banner
  screens/             — welcome, tabs, home, daily, me, game,
                         settings, shop, help, about, privacy,
                         awards, achievements
android/               — package com.nctti.arrowflow, AdMob app ID in manifest
.github/workflows/    — CI builds the debug APK
```

## Build (CI)

Pushes to `main` trigger `.github/workflows/build.yml`, which runs
`flutter build apk --debug` and uploads the APK as an artifact.
Do **not** build locally — the local VM is not set up for Flutter.

## Notes

- Original branding only (never Easybrain). All levels are procedurally
  generated; all sounds are self-synthesized (CC0).
- `android/app/build.gradle` signs release with the debug key for now —
  replace with a real keystore before Play release.
- Remove-ads purchase is stubbed (TODO: wire `in_app_purchase`).
