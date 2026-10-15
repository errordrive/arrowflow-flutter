// ArrowFlow — core game types (ported from src/game/types.ts).

enum Dir { up, down, left, right }

extension DirVec on Dir {
  (int, int) get vec => switch (this) {
        Dir.up => (0, -1),
        Dir.down => (0, 1),
        Dir.left => (-1, 0),
        Dir.right => (1, 0),
      };
}

class Cell {
  final int x;
  final int y;
  const Cell(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      other is Cell && other.x == x && other.y == y;

  @override
  int get hashCode => x * 1000003 ^ y;

  String get key => '$x,$y';
}

class Arrow {
  final int id;
  final List<Cell> cells; // ordered tail -> head
  final Dir dir; // direction of the final segment (head points here)
  const Arrow({required this.id, required this.cells, required this.dir});
}

enum Badge { easy, normal, hard, expert, master, insane }

extension BadgeLabel on Badge {
  String get label => switch (this) {
        Badge.easy => 'Easy',
        Badge.normal => 'Normal',
        Badge.hard => 'Hard',
        Badge.expert => 'Expert',
        Badge.master => 'Master',
        Badge.insane => 'Insane',
      };
}

class LevelParams {
  final int w;
  final int h;
  final int arrowTarget;
  final int minLen;
  final int maxLen;
  final double bendProb;
  final double blockerBias;
  const LevelParams({
    required this.w,
    required this.h,
    required this.arrowTarget,
    required this.minLen,
    required this.maxLen,
    required this.bendProb,
    required this.blockerBias,
  });
}

class LevelData {
  final int n;
  final int w;
  final int h;
  final List<Arrow> arrows;
  final List<(int, int)> blockers; // (blockerId, blockedId)
  final double difficulty;
  final Badge badge;
  final String seed;
  const LevelData({
    required this.n,
    required this.w,
    required this.h,
    required this.arrows,
    required this.blockers,
    required this.difficulty,
    required this.badge,
    required this.seed,
  });
}
