// ArrowFlow — Daily Challenges calendar tab.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../audio.dart';
import '../game/daily.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'game_screen.dart';

const _dow = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];

class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  DateTime _cursor = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final state = context.watch<AppState>();
    final todayKey = dailyKey();

    final y = _cursor.year;
    final m = _cursor.month;
    final first = DateTime(y, m, 1);
    final startOffset = (first.weekday - 1) % 7; // Monday-first
    final daysInMonth = DateTime(y, m + 1, 0).day;

    final cells = <({int? day, String key})>[];
    for (int i = 0; i < startOffset; i++) {
      cells.add((day: null, key: 'x$i'));
    }
    for (int d = 1; d <= daysInMonth; d++) {
      cells.add((day: d, key: dailyKey(DateTime(y, m, d))));
    }

    final monthStars = state.stars[monthKey(_cursor)] ?? 0;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Icon(Icons.emoji_events, size: 72, color: Color(0xFFFFB800)),
            const SizedBox(height: 8),
            Text('Daily Challenges',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: theme.text)),
            const SizedBox(height: 4),
            Text('Complete daily challenges and win gold stars!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: theme.muted)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        color: theme.text,
                        onPressed: () => setState(() {
                          _cursor = DateTime(y, m - 1, 1);
                        }),
                      ),
                      Expanded(
                        child: Text('${_months[m - 1]} $y',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: theme.text)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        color: theme.text,
                        onPressed: () => setState(() {
                          _cursor = DateTime(y, m + 1, 1);
                        }),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              size: 16, color: Color(0xFFFFB800)),
                          const SizedBox(width: 4),
                          Text('$monthStars/$daysInMonth',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: theme.text)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7),
                    itemCount: 7 + cells.length,
                    itemBuilder: (context, i) {
                      if (i < 7) {
                        return Center(
                          child: Text(_dow[i],
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: theme.muted)),
                        );
                      }
                      final c = cells[i - 7];
                      if (c.day == null) return const SizedBox.shrink();
                      final done = state.dailyDone[c.key] ?? false;
                      final isToday = c.key == todayKey;
                      return InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          Sounds.instance.play('click');
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) =>
                                  GameScreen(dailyKey: c.key)));
                        },
                        child: Container(
                          margin: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: done
                                ? theme.gold.withValues(alpha: 0.25)
                                : isToday
                                    ? theme.primarySoft
                                    : Colors.transparent,
                            border: isToday
                                ? Border.all(color: theme.primary, width: 2)
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: done
                              ? const Icon(Icons.star,
                                  size: 18, color: Color(0xFFFFB800))
                              : Text('${c.day}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: theme.text)),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
