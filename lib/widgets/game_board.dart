// ArrowFlow — the puzzle board (CustomPainter).
// - Arrows drawn as polylines through cell centers with a head triangle.
// - Tap: nearest arrow within 24dp of the touch point (PRD §5.7).
// - Removal: arrow slides off along its direction and fades.
// - Blocked tap: arrow flashes red + board shakes.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/types.dart';
import '../theme.dart';

const double tapTolerance = 24.0; // dp, PRD §5.7
const int leaveMs = 420;
const int flashMs = 450;
const int shakeMs = 400;

double _distToSeg(double px, double py, double ax, double ay, double bx, double by) {
  final dx = bx - ax;
  final dy = by - ay;
  final len2 = dx * dx + dy * dy;
  double t = len2 == 0 ? 0 : ((px - ax) * dx + (py - ay) * dy) / len2;
  t = t.clamp(0.0, 1.0);
  final cx = ax + t * dx - px;
  final cy = ay + t * dy - py;
  return math.sqrt(cx * cx + cy * cy);
}

/// Returns the nearest active arrow within [tapTolerance], or null.
Arrow? nearestArrow(
  Offset pos,
  double cell,
  LevelData level,
  Set<int> Function() isActive,
) {
  Arrow? best;
  double bestD = tapTolerance;
  for (final a in level.arrows) {
    if (!isActive(a.id)) continue;
    final pts = a.cells
        .map((c) => Offset((c.x + 0.5) * cell, (c.y + 0.5) * cell))
        .toList();
    double d = double.infinity;
    for (int i = 1; i < pts.length; i++) {
      d = math.min(
          d,
          _distToSeg(pos.dx, pos.dy, pts[i - 1].dx, pts[i - 1].dy, pts[i].dx,
              pts[i].dy));
    }
    // also consider the head triangle area
    final head = pts.last;
    d = math.min(d, (pos - head).distance - cell * 0.2);
    if (d < bestD) {
      bestD = d;
      best = a;
    }
  }
  return best;
}

class BoardView extends StatelessWidget {
  final LevelData level;
  final Set<int> goneIds;
  final Map<int, DateTime> leaving; // id -> started at
  final int? hintId;
  final int? flashId;
  final DateTime? flashAt;
  final DateTime? shakeAt;
  final AppTheme theme;
  final void Function(Arrow) onTapArrow;

  const BoardView({
    super.key,
    required this.level,
    required this.goneIds,
    required this.leaving,
    required this.hintId,
    required this.flashId,
    required this.flashAt,
    required this.shakeAt,
    required this.theme,
    required this.onTapArrow,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellW = constraints.maxWidth / level.w;
        final cellH = constraints.maxHeight / level.h;
        final cell = math.min(cellW, cellH);
        final boardW = cell * level.w;
        final boardH = cell * level.h;
        return Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              // details.localPosition is relative to the GestureDetector box,
              // which is exactly boardW x boardH here.
              final a = nearestArrow(
                details.localPosition,
                cell,
                level,
                (id) => !goneIds.contains(id) && !leaving.containsKey(id),
              );
              if (a != null) onTapArrow(a);
            },
            child: SizedBox(
              width: boardW,
              height: boardH,
              child: CustomPaint(
                painter: _BoardPainter(
                  level: level,
                  cell: cell,
                  goneIds: goneIds,
                  leaving: leaving,
                  hintId: hintId,
                  flashId: flashId,
                  flashAt: flashAt,
                  shakeAt: shakeAt,
                  theme: theme,
                  now: DateTime.now(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BoardPainter extends CustomPainter {
  final LevelData level;
  final double cell;
  final Set<int> goneIds;
  final Map<int, DateTime> leaving;
  final int? hintId;
  final int? flashId;
  final DateTime? flashAt;
  final DateTime? shakeAt;
  final AppTheme theme;
  final DateTime now;

  _BoardPainter({
    required this.level,
    required this.cell,
    required this.goneIds,
    required this.leaving,
    required this.hintId,
    required this.flashId,
    required this.flashAt,
    required this.shakeAt,
    required this.theme,
    required this.now,
  });

  Offset _center(Cell c) => Offset((c.x + 0.5) * cell, (c.y + 0.5) * cell);

  Path _headTriangle(Offset tip, Dir dir, double s) {
    final p = Path();
    switch (dir) {
      case Dir.up:
        p.moveTo(tip.dx - s, tip.dy + s * 1.4);
        p.lineTo(tip.dx + s, tip.dy + s * 1.4);
        p.lineTo(tip.dx, tip.dy);
        break;
      case Dir.down:
        p.moveTo(tip.dx - s, tip.dy - s * 1.4);
        p.lineTo(tip.dx + s, tip.dy - s * 1.4);
        p.lineTo(tip.dx, tip.dy);
        break;
      case Dir.left:
        p.moveTo(tip.dx + s * 1.4, tip.dy - s);
        p.lineTo(tip.dx + s * 1.4, tip.dy + s);
        p.lineTo(tip.dx, tip.dy);
        break;
      case Dir.right:
        p.moveTo(tip.dx - s * 1.4, tip.dy - s);
        p.lineTo(tip.dx - s * 1.4, tip.dy + s);
        p.lineTo(tip.dx, tip.dy);
        break;
    }
    p.close();
    return p;
  }

  void _drawArrow(Canvas canvas, Arrow a, Color color, double alpha) {
    final pts = a.cells.map(_center).toList();
    final paint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..strokeWidth = cell * 0.22
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(path, paint);
    final tip = pts.last;
    canvas.drawPath(
      _headTriangle(tip, a.dir, cell * 0.24),
      Paint()..color = color.withValues(alpha: alpha),
    );
    // tail dot
    canvas.drawCircle(
      pts.first,
      cell * 0.11,
      Paint()..color = color.withValues(alpha: alpha),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // board background
    final bgPaint = Paint()..color = theme.card;
    final bgRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(16),
    );
    canvas.drawRRect(bgRect, bgPaint);

    // subtle grid
    final gridPaint = Paint()
      ..color = theme.border.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    for (int x = 1; x < level.w; x++) {
      canvas.drawLine(
          Offset(x * cell, 0), Offset(x * cell, size.height), gridPaint);
    }
    for (int y = 1; y < level.h; y++) {
      canvas.drawLine(
          Offset(0, y * cell), Offset(size.width, y * cell), gridPaint);
    }

    // shake offset for blocked taps
    double ox = 0;
    if (shakeAt != null) {
      final e = now.difference(shakeAt!).inMilliseconds;
      if (e < shakeMs) {
        ox = math.sin(e * 0.06) * 7 * (1 - e / shakeMs);
      }
    }
    canvas.save();
    canvas.translate(ox, 0);

    for (final a in level.arrows) {
      if (goneIds.contains(a.id)) continue;

      final started = leaving[a.id];
      if (started != null) {
        final e = now.difference(started).inMilliseconds;
        final t = (e / leaveMs).clamp(0.0, 1.0);
        final (dx, dy) = a.dir.vec;
        final head = _center(a.cells.last);
        final dist = (dx == 1
                ? size.width - head.dx
                : dx == -1
                    ? head.dx
                    : dy == 1
                        ? size.height - head.dy
                        : head.dy) +
            cell * 1.5;
        // ease-in like the original (quad in)
        final ease = t * t;
        canvas.save();
        canvas.translate(dx * dist * ease, dy * dist * ease);
        _drawArrow(canvas, a, theme.arrow, t < 0.7 ? 1.0 : 1 - (t - 0.7) / 0.3);
        canvas.restore();
        continue;
      }

      Color color = theme.arrow;
      bool isFlash = false;
      if (flashId == a.id && flashAt != null) {
        final e = now.difference(flashAt!).inMilliseconds;
        if (e < flashMs) {
          isFlash = true;
          // blink red
          color = (e ~/ 120) % 2 == 0 ? theme.heart : theme.arrow;
        }
      }
      if (hintId == a.id && !isFlash) {
        // gold glow under the hinted arrow
        _drawArrow(canvas, a, theme.gold.withValues(alpha: 0.45), 1.0);
      }
      _drawArrow(canvas, a, color, 1.0);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BoardPainter old) => true;
}
