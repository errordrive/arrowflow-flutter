// ArrowFlow — main game screen (ported from app/game.tsx, PRD §5).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../ads.dart';
import '../audio.dart';
import '../game/daily.dart';
import '../game/economy.dart';
import '../game/generator.dart';
import '../game/types.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/ad_banner.dart';
import '../widgets/confetti.dart';
import '../widgets/game_board.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';

class GameScreen extends StatefulWidget {
  final int? level;
  final String? dailyKey;

  const GameScreen({super.key, this.level, this.dailyKey})
      : assert(level != null || dailyKey != null);

  bool get isDaily => dailyKey != null;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final LevelData levelData;

  final Set<int> _gone = {};
  final Map<int, DateTime> _leaving = {};
  Timer? _animTimer;

  int _hearts = Economy.heartsPerLevel;
  bool _flawless = true;
  bool _completed = false;
  int _coinsEarned = 0;
  int? _hintId;
  Timer? _hintTimer;
  bool _eraserArmed = false;
  int? _flashId;
  DateTime? _flashAt;
  DateTime? _shakeAt;
  bool _showOutOfLives = false;
  int _rewardedUsed = 0;

  @override
  void initState() {
    super.initState();
    levelData = widget.isDaily
        ? generateDailyLevel(widget.dailyKey!)
        : generateLevel(widget.level!);
    // Pre-generate the next level in the background (PRD §5.6 performance).
    if (!widget.isDaily) {
      Future.delayed(const Duration(milliseconds: 300), () {
        generateLevel(levelData.n + 1);
      });
    }
  }

  @override
  void dispose() {
    _animTimer?.cancel();
    _hintTimer?.cancel();
    super.dispose();
  }

  bool _isFree(Arrow a) {
    bool removed(int id) => _gone.contains(id) || _leaving.containsKey(id);
    for (final (blocker, blocked) in levelData.blockers) {
      if (blocked == a.id && !removed(blocker)) return false;
    }
    return true;
  }

  void _ensureAnimTimer() {
    _animTimer ??= Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted) return;
      bool changed = false;
      final now = DateTime.now();
      final done = <int>[];
      for (final e in _leaving.entries) {
        if (now.difference(e.value).inMilliseconds >= leaveMs) {
          done.add(e.key);
        } else {
          changed = true; // still animating
        }
      }
      for (final id in done) {
        _leaving.remove(id);
        _gone.add(id);
      }
      // keep ticking while flash/shake active
      if (_flashAt != null &&
          now.difference(_flashAt!).inMilliseconds < flashMs) {
        changed = true;
      }
      if (_shakeAt != null &&
          now.difference(_shakeAt!).inMilliseconds < shakeMs) {
        changed = true;
      }
      if (done.isNotEmpty || changed) setState(() {});
      if (done.isEmpty && !changed) {
        _animTimer?.cancel();
        _animTimer = null;
      }
      if (done.isNotEmpty && _gone.length == levelData.arrows.length) {
        _finishLevel();
      }
    });
  }

  void _doRemove(Arrow a) {
    _leaving[a.id] = DateTime.now();
    _ensureAnimTimer();
    Sounds.instance.play('whoosh');
    if (context.read<AppState>().vibration) {
      HapticFeedback.lightImpact();
    }
    setState(() {});
  }

  void _finishLevel() {
    setState(() => _completed = true);
    final state = context.read<AppState>();
    final coins = widget.isDaily
        ? Economy.dailyRewardCoins
        : Economy.coinReward(levelData.n, _flawless);
    setState(() => _coinsEarned = coins);
    if (widget.isDaily) {
      state.completeDaily(
          widget.dailyKey!, widget.dailyKey!.substring(0, 7));
    } else {
      state.completeLevel(levelData.n, coins);
    }
    Sounds.instance.play('success');
    HapticFeedback.heavyImpact();
    if (!widget.isDaily) {
      Ads.instance.maybeShowInterstitial(levelData.n);
    }
  }

  void _tapArrow(Arrow a) {
    if (_completed || _showOutOfLives) return;
    if (_leaving.containsKey(a.id) || _gone.contains(a.id)) return;
    final state = context.read<AppState>();

    if (_eraserArmed) {
      if (state.useEraser()) {
        setState(() => _eraserArmed = false);
        _doRemove(a);
      } else {
        setState(() => _eraserArmed = false);
        _goShop();
      }
      return;
    }

    if (_isFree(a)) {
      if (_hintId == a.id) setState(() => _hintId = null);
      _doRemove(a);
    } else {
      // Blocked: red flash, lose a heart (PRD §5.2).
      final now = DateTime.now();
      setState(() {
        _flashId = a.id;
        _flashAt = now;
        _shakeAt = now;
        _flawless = false;
      });
      _ensureAnimTimer();
      Sounds.instance.play('fail');
      HapticFeedback.heavyImpact();
      setState(() {
        _hearts = (_hearts - 1).clamp(0, Economy.heartsPerLevel);
        if (_hearts <= 0) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) setState(() => _showOutOfLives = true);
          });
        }
      });
    }
  }

  void _pressHint() {
    final state = context.read<AppState>();
    if (!state.useHint()) {
      _goShop();
      return;
    }
    Sounds.instance.play('click');
    bool alive(int id) => !_gone.contains(id) && !_leaving.containsKey(id);
    final byId = {for (final a in levelData.arrows) a.id: a};
    Arrow? best;
    int bestScore = -1;
    for (final f in levelData.arrows) {
      if (!alive(f.id) || !_isFree(f)) continue;
      int blocks = 0;
      int freesNow = 0;
      for (final (blocker, blocked) in levelData.blockers) {
        if (blocker != f.id || !alive(blocked)) continue;
        blocks++;
        bool stillBlocked = false;
        for (final (bl2, bd2) in levelData.blockers) {
          if (bd2 == blocked && bl2 != f.id && alive(bl2)) {
            stillBlocked = true;
            break;
          }
        }
        if (!stillBlocked) freesNow++;
      }
      final score = blocks * 2 + freesNow * 3;
      if (score > bestScore) {
        bestScore = score;
        best = f;
      }
    }
    if (best != null) {
      final id = best.id;
      setState(() => _hintId = id);
      _hintTimer?.cancel();
      _hintTimer = Timer(const Duration(milliseconds: 4500), () {
        if (mounted) setState(() => _hintId = null);
      });
    }
  }

  void _pressEraser() {
    final state = context.read<AppState>();
    if (_eraserArmed) {
      setState(() => _eraserArmed = false);
      return;
    }
    if (state.erasers < 1) {
      _goShop();
      return;
    }
    setState(() => _eraserArmed = true);
    Sounds.instance.play('click');
  }

  void _goShop() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ShopScreen()));
  }

  void _restartLevel() {
    _animTimer?.cancel();
    _animTimer = null;
    _hintTimer?.cancel();
    setState(() {
      _gone.clear();
      _leaving.clear();
      _hearts = Economy.heartsPerLevel;
      _flawless = true;
      _completed = false;
      _hintId = null;
      _eraserArmed = false;
      _flashId = null;
      _flashAt = null;
      _shakeAt = null;
      _showOutOfLives = false;
      _rewardedUsed = 0;
    });
    Sounds.instance.play('click');
  }

  void _useExtraHeart() {
    if (context.read<AppState>().useExtraHeart()) {
      setState(() {
        _hearts = 1;
        _showOutOfLives = false;
      });
      Sounds.instance.play('heart');
    }
  }

  Future<void> _watchAdForHeart() async {
    final ok = await Ads.instance.showRewarded();
    if (ok && mounted) {
      setState(() {
        _hearts = 1;
        _rewardedUsed++;
        _showOutOfLives = false;
      });
      Sounds.instance.play('heart');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final state = context.watch<AppState>();
    final remaining =
        levelData.arrows.length - _gone.length - _leaving.length;
    final title =
        widget.isDaily ? 'Daily Challenge' : 'Level ${levelData.n}';

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
          children: [
            // header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 28),
                    color: theme.text,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(title,
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: theme.text)),
                        if (!widget.isDaily) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.primarySoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(levelData.badge.label,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: theme.primary)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, size: 24),
                    color: theme.text,
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen())),
                  ),
                ],
              ),
            ),
            // status row
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.card,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text('$remaining left',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.muted)),
                  ),
                  Row(
                    children: List.generate(
                      3,
                      (i) => Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(
                          i < _hearts
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 26,
                          color: theme.heart,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.card,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            size: 16, color: Color(0xFFFFB800)),
                        Text(' ${state.hints}',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_eraserArmed)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('Tap any arrow to erase it',
                    style: TextStyle(
                        color: theme.primary,
                        fontWeight: FontWeight.w600)),
              ),
            // board
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24),
                child: BoardView(
                  level: levelData,
                  goneIds: _gone,
                  leaving: _leaving,
                  hintId: _hintId,
                  flashId: _flashId,
                  flashAt: _flashAt,
                  shakeAt: _shakeAt,
                  theme: theme,
                  onTapArrow: _tapArrow,
                ),
              ),
            ),
            // tools
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _toolButton(
                    theme: theme,
                    icon: Icons.lightbulb,
                    iconColor: theme.gold,
                    label: 'Hint',
                    count: state.hints,
                    armed: false,
                    onTap: _pressHint,
                  ),
                  const SizedBox(width: 32),
                  _toolButton(
                    theme: theme,
                    icon: Icons.delete_outline,
                    iconColor: theme.primary,
                    label: 'Eraser',
                    count: state.erasers,
                    armed: _eraserArmed,
                    onTap: _pressEraser,
                  ),
                ],
              ),
            ),
            const AdBanner(),
              ],
            ),
            // level complete overlay
            if (_completed)
              Container(
                color: theme.primary.withValues(alpha: 0.92),
                child: Stack(
                  children: [
                    const Confetti(),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Level Completed!',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          Text(
                              '+$_coinsEarned coins${widget.isDaily ? '  ★ 1 star' : ''}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 24),
                          if (!widget.isDaily)
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                      builder: (_) => GameScreen(
                                          level: levelData.n + 1)),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: theme.primary,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 28, vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(24)),
                              ),
                              child: Text(
                                  'Next Game — Level ${levelData.n + 1}',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                            ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).popUntil(
                                  (r) => r.isFirst);
                            },
                            child: const Text('Main',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            // out of lives modal (PRD §5.5)
            if (_showOutOfLives)
              Container(
                color: Colors.black.withValues(alpha: 0.45),
                alignment: Alignment.center,
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.card,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Out of Lives!',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: theme.text)),
                      const SizedBox(height: 12),
                      Icon(Icons.favorite,
                          size: 64, color: theme.heart),
                      const SizedBox(height: 12),
                      if (state.extraHearts > 0)
                        _modalBtn(
                            theme,
                            'Use Extra Heart (${state.extraHearts})',
                            _useExtraHeart),
                      if (_rewardedUsed <
                          Economy.maxRewardedHeartsPerLevel)
                        _modalBtn(theme, 'Get More Lives — watch ad',
                            _watchAdForHeart),
                      TextButton(
                        onPressed: () {
                          setState(
                              () => _showOutOfLives = false);
                          _goShop();
                        },
                        child: Text('Buy heart pack',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.primary)),
                      ),
                      TextButton(
                        onPressed: _restartLevel,
                        child: Text('Restart Game',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.primary)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _modalBtn(
      AppTheme theme, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(240, 48),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24)),
        ),
        child:
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _toolButton({
    required AppTheme theme,
    required IconData icon,
    required Color iconColor,
    required String label,
    required int count,
    required bool armed,
    required VoidCallback onTap,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(42),
          onTap: onTap,
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: armed ? theme.primarySoft : theme.card,
              border: Border.all(
                  color: armed ? theme.primary : theme.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 26, color: iconColor),
                const SizedBox(height: 2),
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.text)),
              ],
            ),
          ),
        ),
        Positioned(
          top: -4,
          right: -4,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('$count',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}
