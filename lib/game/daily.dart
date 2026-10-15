// Daily Challenge helpers. Ported from src/game/daily.ts.

String dailyKey([DateTime? date]) {
  final d = date ?? DateTime.now();
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$day';
}

String monthKey([DateTime? date]) {
  final d = date ?? DateTime.now();
  final m = d.month.toString().padLeft(2, '0');
  return '${d.year}-$m';
}
