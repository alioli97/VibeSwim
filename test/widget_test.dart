import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:swimvibe/core/app_state.dart';
import 'package:swimvibe/core/workout_picker.dart';
import 'package:swimvibe/main.dart';

void main() {
  setUpAll(() {
    // Tests have no network: don't try to download Google Fonts.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('home screen renders and switches language', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final appState = AppState(await SharedPreferences.getInstance());

    await tester.pumpWidget(SwimVibeApp(appState: appState));
    await tester.pump();

    expect(find.text('SwimVibe'), findsOneWidget);
    expect(find.text('READY FOR A SET?'), findsOneWidget);
    expect(find.text('Generate Workout'), findsOneWidget);

    // Distance mode is active by default; picking a time switches to time mode.
    AnimatedOpacity cardOpacity(String title) => tester.widget<AnimatedOpacity>(
        find.ancestor(of: find.text(title), matching: find.byType(AnimatedOpacity)));
    expect(cardOpacity('Target total meters').opacity, 1);
    expect(cardOpacity('Available Time').opacity, 0.4);

    await tester.ensureVisible(find.text('45'));
    await tester.tap(find.text('45'));
    await tester.pumpAndSettle();

    expect(cardOpacity('Target total meters').opacity, 0.4);
    expect(cardOpacity('Available Time').opacity, 1);

    // CUSTOM time: type 60 minutes and it shows up selected.
    await tester.ensureVisible(find.text('CUSTOM'));
    await tester.tap(find.text('CUSTOM'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '60');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('60'), findsOneWidget);

    // Invalid input keeps the previous value.
    await tester.tap(find.text('CUSTOM'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '0');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('60'), findsOneWidget);

    // Custom distance keeps the exact typed value (no rounding to 1800).
    await tester.ensureVisible(find.text('SET CUSTOM'));
    await tester.tap(find.text('SET CUSTOM'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '1850');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('1850'), findsOneWidget);
    expect(cardOpacity('Target total meters').opacity, 1);

    appState.setLanguage('es');
    await tester.pump();

    expect(find.text('¿LISTO PARA ENTRENAR?'), findsOneWidget);
    expect(find.text('Generar Entreno'), findsOneWidget);
    expect(find.text('MINUTOS'), findsNWidgets(3));
    expect(find.text('ENTRENOS'), findsOneWidget); // bottom nav (uppercased)
    expect(find.text('HISTORIAL'), findsOneWidget);

    // Dialog buttons are translated.
    await tester.tap(find.text('PERSONALIZAR'));
    await tester.pumpAndSettle();
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Guardar'), findsOneWidget);
  });

  testWidgets('difficulty chips select and persist the filter', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final appState = AppState(await SharedPreferences.getInstance());
    await tester.pumpWidget(SwimVibeApp(appState: appState));
    await tester.pump();

    expect(appState.difficulty, DifficultyFilter.any);
    await tester.ensureVisible(find.text('Intermediate'));
    await tester.tap(find.text('Intermediate'));
    await tester.pump();

    expect(appState.difficulty, DifficultyFilter.intermediate);
    expect(AppState(appState.prefs).difficulty, DifficultyFilter.intermediate); // persisted
  });
}
