// Seeded RNG: xmur3 string hash -> mulberry32 PRNG.
// Deterministic across devices so every player sees the same level N.
// Ported from src/game/rng.ts with explicit 32-bit masking (Dart ints are 64-bit).

const int _mask32 = 0xFFFFFFFF;

int _imul(int a, int b) => ((a & _mask32) * (b & _mask32)) & _mask32;

int Function() _xmur3(String str) {
  int h = (1779033703 ^ str.length) & _mask32;
  for (int i = 0; i < str.length; i++) {
    h = _imul(h ^ str.codeUnitAt(i), 3432918353);
    h = ((h << 13) | (h >> 19)) & _mask32;
  }
  return () {
    h = _imul(h ^ (h >> 16), 2246822507);
    h = _imul(h ^ (h >> 13), 3266489909);
    h = (h ^ (h >> 16)) & _mask32;
    return h;
  };
}

double Function() _mulberry32(int seed) {
  int a = seed & _mask32;
  return () {
    a = (a + 0x6D2B79F5) & _mask32;
    int t = _imul(a ^ (a >> 15), 1 | a);
    t = ((t + _imul(t ^ (t >> 7), 61 | t)) ^ t) & _mask32;
    t = (t ^ (t >> 14)) & _mask32;
    return t / 4294967296.0;
  };
}

class Rng {
  final double Function() _rand;
  Rng._(this._rand);

  factory Rng(String seedStr) => Rng._(_mulberry32(_xmur3(seedStr)()));

  double next() => _rand();

  int intIn(int min, int max) => min + (_rand() * (max - min + 1)).floor();

  bool chance(double p) => _rand() < p;

  T pick<T>(List<T> arr) => arr[(_rand() * arr.length).floor()];

  void shuffle<T>(List<T> list) {
    for (int i = list.length - 1; i > 0; i--) {
      final j = (_rand() * (i + 1)).floor();
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
  }
}
