// ArrowFlow — Flutter entry point.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'ads.dart';
import 'audio.dart';
import 'screens/tabs_screen.dart';
import 'screens/welcome_screen.dart';
import 'state/app_state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Ads.instance.init();
  final appState = AppState();
  await appState.load();
  Sounds.instance.enabled = appState.sounds;
  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const ArrowFlowApp(),
    ),
  );
}

class ArrowFlowApp extends StatelessWidget {
  const ArrowFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.loaded) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    Sounds.instance.enabled = state.sounds;
    Ads.instance.removedAds = state.removedAds;

    return MaterialApp(
      title: 'ArrowFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.light.primary,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.dark.primary,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: state.darkMode ? ThemeMode.dark : ThemeMode.light,
      home: state.onboarded ? const TabsScreen() : const WelcomeScreen(),
    );
  }
}
