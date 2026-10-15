// ArrowFlow — deterministic level generator (ported from src/game/generator.ts).
//
// Reverse construction guarantees solvability:
//   1. Fix a removal order o1..oN. Place arrows in REVERSE (oN first).
//   2. An arrow being placed may only be accepted if its exit ray avoids
//      its own cells and every already-placed arrow's cells.
//   3. Therefore each arrow is blocked only by arrows removed BEFORE it,
//      so o1..oN is always a valid removal order.

import 'dart:math' as math;

import 'rng.dart';
import 'types.dart';

const String salt = 'arrowflow-v1';

// Difficulty weights (PRD §5.6)
const double w1 = 0.45;
const double w2 = 1.2;
const double w3 = 0.8;
const double w4 = 6.0;
const double w5 = 0.15;
const double w6 = 3.0;

const List<Dir> _allDirs = [Dir.up, Dir.down, Dir.left, Dir.right];

double _clamp(double v, double lo, double hi) => v < lo ? lo : (v > hi ? hi : v);
double _lerp(double a, double b, double t) => a + (b - a) * t;
int _clampInt(int v, int lo, int hi) => v < lo ? lo : (v > hi ? hi : v);

class _Band {
  final int n, w, h, arrows;
  const _Band(this.n, this.w, this.h, this.arrows);
}

const List<_Band> _bands = [
  _Band(1, 6, 6, 3),
  _Band(3, 8, 8, 6),
  _Band(10, 10, 10, 12),
  _Band(30, 12, 14, 20),
  _Band(70, 14, 18, 35),
  _Band(150, 18, 24, 60),
  _Band(300, 22, 30, 95),
  _Band(600, 24, 40, 150),
];

LevelParams levelParams(int n) {
  int i = 0;
  while (i < _bands.length - 2 && n > _bands[i + 1].n) {
    i++;
  }
  final a = _bands[i];
  final b = _bands[i + 1];
  final t = _clamp((n - a.n) / (b.n - a.n), 0, 1);
  final over = math.max(0, n - _bands[_bands.length - 1].n);
  final w = math.min(24, (_lerp(a.w.toDouble(), b.w.toDouble(), t)).round() + over ~/ 150);
  final h = math.min(40, (_lerp(a.h.toDouble(), b.h.toDouble(), t)).round() + over ~/ 150);
  final arrowTarget = over > 0
      ? math.min(420, 170 + over ~/ 6)
      : (_lerp(a.arrows.toDouble(), b.arrows.toDouble(), t)).round();
  return LevelParams(
    w: w,
    h: h,
    arrowTarget: math.max(2, arrowTarget),
    minLen: 2,
    maxLen: _clampInt((math.min(w, h) * 0.9).round(), 3, 12),
    bendProb: _clamp(0.12 + n / 500, 0.12, 0.5),
    blockerBias: _clamp(0.35 + n / 300, 0.35, 0.9),
  );
}

Badge badgeForLevel(int n) {
  if (n <= 10) return Badge.easy;
  if (n <= 40) return Badge.normal;
  if (n <= 100) return Badge.hard;
  if (n <= 200) return Badge.expert;
  if (n <= 400) return Badge.master;
  return Badge.insane;
}

/// Cells on the straight ray from the arrowhead along its direction to the edge.
List<Cell> exitRay(Arrow a, int w, int h) {
  final head = a.cells[a.cells.length - 1];
  final (dx, dy) = a.dir.vec;
  final cells = <Cell>[];
  int x = head.x + dx;
  int y = head.y + dy;
  while (x >= 0 && x < w && y >= 0 && y < h) {
    cells.add(Cell(x, y));
    x += dx;
    y += dy;
  }
  return cells;
}

Dir _dirOf(Cell from, Cell to) {
  if (to.x > from.x) return Dir.right;
  if (to.x < from.x) return Dir.left;
  if (to.y > from.y) return Dir.down;
  return Dir.up;
}

class _Placed {
  final List<Arrow> arrows = [];
  final Set<String> occupied = <String>{};
}

List<Cell>? _walk(
  Rng rng,
  LevelParams p,
  Set<String> occupied,
  Cell start,
  (int, int)? firstDir,
  int targetLen,
) {
  final w = p.w, h = p.h;
  final cells = <Cell>[start];
  final used = <String>{start.key};
  Cell cur = start;
  var d = firstDir ?? rng.pick(_allDirs).vec;

  for (int step = 1; step < targetLen; step++) {
    if (step > 1 && rng.chance(p.bendProb)) {
      final options =
          _allDirs.where((dd) => dd.vec != (-d.$1, -d.$2)).toList();
      d = rng.pick(options).vec;
    }
    int nx = cur.x + d.$1;
    int ny = cur.y + d.$2;
    bool blocked = nx < 0 ||
        nx >= w ||
        ny < 0 ||
        ny >= h ||
        occupied.contains('$nx,$ny') ||
        used.contains('$nx,$ny');
    if (blocked) {
      final options =
          _allDirs.where((dd) => dd.vec != (-d.$1, -d.$2)).toList();
      bool moved = false;
      for (final alt in options) {
        final (adx, ady) = alt.vec;
        final ax = cur.x + adx;
        final ay = cur.y + ady;
        if (ax < 0 || ax >= w || ay < 0 || ay >= h) continue;
        if (occupied.contains('$ax,$ay') || used.contains('$ax,$ay')) continue;
        d = (adx, ady);
        nx = ax;
        ny = ay;
        moved = true;
        break;
      }
      if (!moved) break;
    }
    cur = Cell(nx, ny);
    cells.add(cur);
    used.add(cur.key);
  }
  return cells.length >= 2 ? cells : null;
}

Arrow _commitArrow(_Placed placed, List<Cell> cells, Dir dir, int id) {
  final arrow = Arrow(id: id, cells: cells, dir: dir);
  for (final c in cells) {
    placed.occupied.add(c.key);
  }
  placed.arrows.add(arrow);
  return arrow;
}

int _pickLen(Rng rng, LevelParams p) {
  final r = rng.next();
  int hi(int a, int b) => rng.intIn(a, math.max(a, math.min(b, p.maxLen)));
  final small = p.w * p.h < 100;
  if (small) {
    if (r < 0.8) return hi(p.minLen, 3);
    return hi(4, 5);
  }
  if (r < 0.55) return hi(p.minLen, 4);
  if (r < 0.85) return hi(5, 8);
  return hi(9, p.maxLen);
}

Arrow? _tryPlaceOne(Rng rng, LevelParams p, _Placed placed, int nextId) {
  final w = p.w, h = p.h;
  final occupied = placed.occupied;

  if (rng.chance(0.35)) {
    for (int e = 0; e < 24; e++) {
      final side = rng.intIn(0, 3);
      final hx = side == 2 ? 0 : side == 3 ? w - 1 : rng.intIn(0, w - 1);
      final hy = side == 0 ? 0 : side == 1 ? h - 1 : rng.intIn(0, h - 1);
      final outward = _allDirs[side];
      if (occupied.contains('$hx,$hy')) continue;
      final (odx, ody) = outward.vec;
      final inward = (-odx, -ody);
      final targetLen = _pickLen(rng, p);
      final rev = _walk(rng, p, occupied, Cell(hx, hy), inward, targetLen);
      if (rev == null || rev.length < 2) continue;
      final cells = rev.reversed.toList();
      if (_dirOf(cells[cells.length - 2], cells[cells.length - 1]) != outward) {
        continue;
      }
      return _commitArrow(placed, cells, outward, nextId);
    }
  }

  final rayCells = <Cell>[];
  for (final a in placed.arrows) {
    for (final c in exitRay(a, w, h)) {
      if (!occupied.contains(c.key)) rayCells.add(c);
    }
  }

  for (int s = 0; s < 48; s++) {
    Cell start;
    if (placed.arrows.isNotEmpty &&
        rng.chance(p.blockerBias) &&
        rayCells.isNotEmpty) {
      start = rng.pick(rayCells);
    } else {
      start = Cell(rng.intIn(0, w - 1), rng.intIn(0, h - 1));
      if (occupied.contains(start.key)) continue;
    }

    final targetLen = _pickLen(rng, p);
    final body = _walk(rng, p, occupied, start, null, math.max(1, targetLen - 1));
    if (body == null) continue;
    final tip = body[body.length - 1];
    final own = body.map((c) => c.key).toSet();
    final dirs = [..._allDirs];
    rng.shuffle(dirs);
    int? bhx, bhy;
    Dir? bdir;
    int bestRay = -1;
    for (final d in dirs) {
      final (dx, dy) = d.vec;
      final hx = tip.x + dx;
      final hy = tip.y + dy;
      if (hx < 0 || hx >= w || hy < 0 || hy >= h) continue;
      final hk = '$hx,$hy';
      if (occupied.contains(hk) || own.contains(hk)) continue;
      bool blocked = false;
      int rayLen = 0;
      int x = hx + dx;
      int y = hy + dy;
      while (x >= 0 && x < w && y >= 0 && y < h) {
        final k = '$x,$y';
        if (own.contains(k) || occupied.contains(k)) {
          blocked = true;
          break;
        }
        rayLen++;
        x += dx;
        y += dy;
      }
      if (blocked) continue;
      if (rayLen > bestRay) {
        bestRay = rayLen;
        bhx = hx;
        bhy = hy;
        bdir = d;
      }
    }
    if (bdir != null) {
      return _commitArrow(
          placed, [...body, Cell(bhx!, bhy!)], bdir, nextId);
    }
  }
  return null;
}

_Placed _placeArrows(Rng rng, LevelParams p, int count, int startId) {
  final placed = _Placed();
  int id = startId;
  for (int i = 0; i < count; i++) {
    final a = _tryPlaceOne(rng, p, placed, id);
    if (a == null) break;
    id++;
  }
  return placed;
}

class Analysis {
  final List<(int, int)> blockers;
  final double avgBlockers;
  final int maxChainDepth;
  final double density;
  final int bends;
  final double freeRatio;
  final double difficulty;
  const Analysis({
    required this.blockers,
    required this.avgBlockers,
    required this.maxChainDepth,
    required this.density,
    required this.bends,
    required this.freeRatio,
    required this.difficulty,
  });
}

Analysis analyze(List<Arrow> arrows, int w, int h) {
  final owner = <String, int>{};
  for (final a in arrows) {
    for (final c in a.cells) {
      owner[c.key] = a.id;
    }
  }

  final blockerSet = <String>{};
  final blockedBy = <int, Set<int>>{};
  for (final b in arrows) {
    for (final c in exitRay(b, w, h)) {
      final o = owner[c.key];
      if (o == null || o == b.id) continue;
      final pair = '$o:${b.id}';
      if (!blockerSet.contains(pair)) {
        blockerSet.add(pair);
        blockedBy.putIfAbsent(b.id, () => <int>{}).add(o);
      }
    }
  }
  final blockers = blockerSet.map((s) {
    final parts = s.split(':');
    return (int.parse(parts[0]), int.parse(parts[1]));
  }).toList();

  final depth = <int, int>{};
  final byId = [...arrows]..sort((x, y) => y.id.compareTo(x.id));
  int maxDepth = 0;
  for (final a in byId) {
    int d = 1;
    final preds = blockedBy[a.id];
    if (preds != null) {
      for (final pid in preds) {
        d = math.max(d, (depth[pid] ?? 1) + 1);
      }
    }
    depth[a.id] = d;
    maxDepth = math.max(maxDepth, d);
  }

  final totalCells = arrows.fold<int>(0, (s, a) => s + a.cells.length);
  int bends = 0;
  for (final a in arrows) {
    for (int i = 2; i < a.cells.length; i++) {
      if (_dirOf(a.cells[i - 2], a.cells[i - 1]) !=
          _dirOf(a.cells[i - 1], a.cells[i])) {
        bends++;
      }
    }
  }
  final n = arrows.length;
  int totalBlockers = 0;
  for (final s in blockedBy.values) {
    totalBlockers += s.length;
  }
  final avgBlockers = n == 0 ? 0.0 : totalBlockers / n;
  final free = arrows.where((a) => !blockedBy.containsKey(a.id)).length;
  final freeRatio = n == 0 ? 1.0 : free / n;
  final density = w * h == 0 ? 0.0 : totalCells / (w * h);

  final difficulty = w1 * n +
      w2 * avgBlockers +
      w3 * maxDepth +
      w4 * density +
      w5 * bends -
      w6 * freeRatio;

  return Analysis(
    blockers: blockers,
    avgBlockers: avgBlockers,
    maxChainDepth: maxDepth,
    density: density,
    bends: bends,
    freeRatio: freeRatio,
    difficulty: difficulty,
  );
}

LevelData _assemble(int n, List<Arrow> arrows, LevelParams p, String seed) {
  final analysis = analyze(arrows, p.w, p.h);
  return LevelData(
    n: n,
    w: p.w,
    h: p.h,
    arrows: arrows,
    blockers: analysis.blockers,
    difficulty: analysis.difficulty,
    badge: badgeForLevel(n),
    seed: seed,
  );
}

final Map<int, LevelData> _cache = {};

/// Generate level n deterministically. Pure function of (n, salt).
/// Rejection sampling: try up to 30 seeds; accept the first with D > D(n-1).
LevelData generateLevel(int n) {
  if (n < 1) throw ArgumentError('level n must be >= 1');
  final cached = _cache[n];
  if (cached != null) return cached;

  final p = levelParams(n);
  final prevD = n > 1 ? generateLevel(n - 1).difficulty : null;

  LevelData? level;
  double bestD = double.negativeInfinity;
  LevelData? bestLevel;
  final attempts = n > 1 ? 30 : 10;
  for (int attempt = 0; attempt < attempts; attempt++) {
    final seed = '$salt:n=$n:a=$attempt';
    final rng = Rng(seed);
    final placed = _placeArrows(rng, p, p.arrowTarget, 1);
    if (placed.arrows.length < 2) continue;
    final cand = _assemble(n, placed.arrows, p, seed);
    if (cand.difficulty > bestD) {
      bestD = cand.difficulty;
      bestLevel = cand;
    }
    if (prevD == null || cand.difficulty > prevD) {
      level = cand;
      break;
    }
  }
  level ??= bestLevel;
  if (level == null) throw StateError('could not place level $n');
  _cache[n] = level;
  return level;
}

/// Fixed medium-difficulty params for the daily level.
LevelParams dailyParams() => const LevelParams(
      w: 6,
      h: 9,
      arrowTarget: 16,
      minLen: 2,
      maxLen: 6,
      bendProb: 0.3,
      blockerBias: 0.6,
    );

String dailySeed(String dateKey) => '$salt:daily:$dateKey';

/// Generate the Daily Challenge level for a YYYY-MM-DD date key.
LevelData generateDailyLevel(String dateKey) {
  final p = dailyParams();
  final seed = dailySeed(dateKey);
  final rng = Rng(seed);
  final placed = _placeArrows(rng, p, p.arrowTarget, 1);
  return _assemble(0, placed.arrows, p, seed);
}
