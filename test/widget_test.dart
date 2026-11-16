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

    appState.setLanguage('es');
    await tester.pump();

    expect(find.text('¿LISTO PARA ENTRENAR?'), findsOneWidget);
    expect(find.text('Generar Entreno'), findsOneWidget);
  });
}
