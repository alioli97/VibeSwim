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
}
