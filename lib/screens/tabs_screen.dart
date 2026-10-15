// ArrowFlow — bottom tab navigation: Home, Daily, Me.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme.dart';
import 'daily_screen.dart';
import 'home_screen.dart';
import 'me_screen.dart';

class TabsScreen extends StatefulWidget {
  const TabsScreen({super.key});

  @override
  State<TabsScreen> createState() => _TabsScreenState();
}

class _TabsScreenState extends State<TabsScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final pages = const [HomeScreen(), DailyScreen(), MeScreen()];
    return Scaffold(
      backgroundColor: theme.bg,
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        backgroundColor: theme.card,
        selectedItemColor: theme.primary,
        unselectedItemColor: theme.muted,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Main'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Daily'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Me'),
        ],
      ),
    );
  }
}
