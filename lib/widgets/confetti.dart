// ArrowFlow — simple confetti burst for the level-complete overlay.

import 'dart:math' as math;

import 'package:flutter/material.dart';

class Confetti extends StatefulWidget {
  const Confetti({super.key});

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Piece> _pieces;
  final _rand = math.Random(12345);

  static const _colors = [
    Color(0xFFFF3B5C),
    Color(0xFFFFB800),
    Color(0xFF2F6DF6),
    Color(0xFF22C55E),
    Color(0xFFA855F7),
    Color(0xFFFFFFFF),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();
    _pieces = List.generate(90, (_) {
      final angle = _rand.nextDouble() * math.pi * 2;
      final speed = 120 + _rand.nextDouble() * 320;
      return _Piece(
        angle: angle,
        speed: speed,
        color: _colors[_rand.nextInt(_colors.length)],
        size: 5 + _rand.nextDouble() * 7,
        spin: _rand.nextDouble() * math.pi * 2,
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _ConfettiPainter(_pieces, _ctrl.value),
      ),
    );
  }
}

class _Piece {
  final double angle;
  final double speed;
  final Color color;
  final double size;
  final double spin;
  _Piece({
    required this.angle,
    required this.speed,
    required this.color,
    required this.size,
    required this.spin,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Piece> pieces;
  final double t;
  _ConfettiPainter(this.pieces, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.35);
    for (final p in pieces) {
      final dist = p.speed * t;
      final x = center.dx + math.cos(p.angle) * dist;
      final y = center.dy + math.sin(p.angle) * dist + 220 * t * t;
      final alpha = (1 - t).clamp(0.0, 1.0);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin + t * 6);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
        Paint()..color = p.color.withValues(alpha: alpha),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
