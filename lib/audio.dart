// ArrowFlow — tiny sound helper (self-synthesized CC0 wavs in assets/sounds/).

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class Sounds {
  Sounds._();
  static final Sounds instance = Sounds._();

  final AudioPlayer _player = AudioPlayer();
  bool enabled = true;

  static const _files = {
    'click': 'sounds/click.wav',
    'tap': 'sounds/tap.wav',
    'whoosh': 'sounds/whoosh.wav',
    'fail': 'sounds/fail.wav',
    'success': 'sounds/success.wav',
    'heart': 'sounds/heart.wav',
  };

  Future<void> play(String name) async {
    if (!enabled) return;
    final file = _files[name];
    if (file == null) return;
    try {
      await _player.play(AssetSource(file));
    } catch (e) {
      debugPrint('sound failed: $e');
    }
  }
}
