import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:swimvibe/core/app_state.dart';
import 'package:swimvibe/main.dart';
import 'package:swimvibe/screens/history_screen.dart';
import 'package:swimvibe/screens/home_screen.dart';
import 'package:swimvibe/screens/progress_screen.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting();
  });

  Future<AppState> newAppState({String lang = 'en'}) async {
    SharedPreferences.setMockInitialValues({AppState.keyLanguage: lang});
    return AppState(await SharedPreferences.getInstance());
  }

  testWidgets('empty history shows a hint instead of stats', (tester) async {
    final appState = await newAppState();
    await tester.pumpWidget(MaterialApp(home: ProgressScreen(appState: appState)));

    expect(find.text('Your Progress'), findsOneWidget);
    expect(find.text('Log your first workout to see your stats.'), findsOneWidget);
  });

  testWidgets('shows totals, streak and month stats from the history', (tester) async {
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final appState = await newAppState(lang: 'es');
    final now = DateTime.now();
    await tester.runAsync(() async {
      await appState.history.setWeeklyGoal(1000);
      await appState.history.add(
          {'distance_meters': 1500, 'duration_minutes': 40, 'title_es': 'Larga'},
          completedAt: now);
      await appState.history.add({'distance_meters': 500, 'duration_minutes': 15},
          completedAt: now.subtract(const Duration(minutes: 5)));
    });
    await tester.pumpWidget(MaterialApp(home: ProgressScreen(appState: appState)));

    expect(find.text('Tu progreso'), findsOneWidget);
    expect(find.text('Últimas 8 semanas'), findsOneWidget);
    expect(find.text('Objetivo: 1.000m'), findsOneWidget);
    expect(find.text('2.000m'), findsWidgets); // total distance, this month
    expect(find.text('55 min'), findsOneWidget); // total time
    expect(find.text('1.000m'), findsOneWidget); // average
    expect(find.text('1.500m'), findsOneWidget); // longest
    expect(find.textContaining('Larga · '), findsOneWidget);
    expect(find.text('1 semana'), findsNWidgets(2)); // current and best streak (goal met this week)
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom nav moves between Home, History and Progress', (tester) async {
    final appState = await newAppState();
    await tester.pumpWidget(SwimVibeApp(appState: appState));
    await tester.pump();

    await tester.tap(find.text('PROGRESS'));
    await tester.pumpAndSettle();
    expect(find.byType(ProgressScreen), findsOneWidget);

    await tester.tap(find.text('HISTORY'));
    await tester.pumpAndSettle();
    expect(find.byType(HistoryScreen), findsOneWidget);
    expect(find.byType(ProgressScreen), findsNothing); // replaced, not stacked

    await tester.tap(find.text('WORKOUTS'));
    await tester.pumpAndSettle();
    expect(find.byType(HistoryScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
