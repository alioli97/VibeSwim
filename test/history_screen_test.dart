import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:swimvibe/core/app_state.dart';
import 'package:swimvibe/screens/history_screen.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting();
  });

  Future<AppState> pumpHistory(WidgetTester tester, {String lang = 'en'}) async {
    SharedPreferences.setMockInitialValues({AppState.keyLanguage: lang});
    final appState = AppState(await SharedPreferences.getInstance());
    await tester.pumpWidget(MaterialApp(home: HistoryScreen(appState: appState)));
    return appState;
  }

  testWidgets('shows the empty state with zeroed progress', (tester) async {
    await pumpHistory(tester);

    expect(find.text('No workouts yet. Go swim!'), findsOneWidget);
    expect(find.text('0m'), findsOneWidget); // total distance
    expect(find.text('0%'), findsOneWidget); // weekly goal
  });

  testWidgets('lists logged workouts and real totals, updating live', (tester) async {
    final appState = await pumpHistory(tester, lang: 'es');

    await tester.runAsync(() async {
      await appState.history.add({
        'distance_meters': 1500,
        'title_en': 'Medley Session',
        'title_es': 'Sesión de estilos',
      });
      await appState.history.add({
        'distance_meters': 2000,
        'title_es': 'Resistencia',
      });
    });
    await tester.pump();

    expect(find.text('Aún no hay entrenos. ¡A nadar!'), findsNothing);
    expect(find.text('Sesión de estilos'), findsOneWidget);
    expect(find.text('Resistencia'), findsOneWidget);
    expect(find.text('3.500m'), findsOneWidget); // total, Spanish separator
    expect(find.text('2'), findsOneWidget); // workouts count
    expect(find.text('70%'), findsOneWidget); // 3,500 of the 5,000 m weekly goal
    expect(find.text('3.500m de 5.000m completados'), findsOneWidget);
  });

  testWidgets('deletes a workout and can undo it', (tester) async {
    final appState = await pumpHistory(tester);
    await tester.runAsync(() async {
      await appState.history.add({'distance_meters': 800, 'title_en': 'Mistake'});
      await appState.history.add({'distance_meters': 400, 'title_en': 'Keep me'},
          completedAt: DateTime.now().subtract(const Duration(hours: 1)));
    });
    await tester.pump();

    await tester.tap(find.descendant(
      of: find.ancestor(of: find.text('Mistake'), matching: find.byType(Dismissible)),
      matching: find.byTooltip('Delete'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Mistake'), findsNothing);
    expect(find.text('Keep me'), findsOneWidget);
    expect(find.text('Workout deleted'), findsOneWidget);
    expect(appState.history.totalDistance, 400);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(find.text('Mistake'), findsOneWidget);
    expect(appState.history.totalDistance, 1200);
  });

  testWidgets('swiping a workout deletes it', (tester) async {
    final appState = await pumpHistory(tester);
    await tester.runAsync(
        () => appState.history.add({'distance_meters': 800, 'title_en': 'Swipe me'}));
    await tester.pump();

    await tester.drag(find.text('Swipe me'), const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(find.text('Swipe me'), findsNothing);
    expect(appState.history.entries, isEmpty);
    expect(find.text('Workout deleted'), findsOneWidget);

    // Let the snackbar time out so no timers are left pending.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('weekly goal can be changed from the progress card', (tester) async {
    final appState = await pumpHistory(tester);
    await tester.runAsync(() => appState.history.add({'distance_meters': 1000}));
    await tester.pump();
    expect(find.text('20%'), findsOneWidget); // 1,000 of 5,000

    await tester.tap(find.text('Weekly Goal'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '2000');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('50%'), findsOneWidget); // 1,000 of 2,000
    expect(find.text('1,000m of 2,000m completed'), findsOneWidget);
    expect(appState.history.weeklyGoalMeters, 2000);
  });
}
