import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:swimvibe/core/app_state.dart';
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

    appState.setLanguage('es');
    await tester.pump();

    expect(find.text('¿LISTO PARA ENTRENAR?'), findsOneWidget);
    expect(find.text('Generar Entreno'), findsOneWidget);
  });
}
