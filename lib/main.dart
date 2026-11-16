import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'core/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Date formats for en/es/ca (used by DateFormat in the history screen).
  await initializeDateFormatting();

  await Supabase.initialize(
    url: 'https://ryjxewdvrcpumnbivvrb.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ5anhld2R2cmNwdW1uYml2dnJiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUyNDExODMsImV4cCI6MjA5MDgxNzE4M30.hPv0-dv3UlUGWEVZgpUgULPn3omGDHHA3ExsrBTpuRQ',
  );

  final prefs = await SharedPreferences.getInstance();
  final appState = AppState(prefs);

  runApp(SwimVibeApp(appState: appState));
}

class SwimVibeApp extends StatelessWidget {
  final AppState appState;

  const SwimVibeApp({Key? key, required this.appState}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return MaterialApp(
          title: 'SwimVibe',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            dragDevices: {
              PointerDeviceKind.mouse,
              PointerDeviceKind.touch,
              PointerDeviceKind.stylus,
              PointerDeviceKind.trackpad,
            },
          ),
          home: HomeScreen(appState: appState),
        );
      }
    );
  }
}
