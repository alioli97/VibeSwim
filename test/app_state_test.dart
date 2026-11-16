import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:swimvibe/core/app_state.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('defaults to English when no language is saved', () {
    final appState = AppState(prefs);

    expect(appState.currentLanguage, 'en');
    expect(appState.tGenerateWorkout, 'Generate Workout');
  });

  test('loads the saved language from preferences', () async {
    SharedPreferences.setMockInitialValues({AppState.keyLanguage: 'ca'});
    final appState = AppState(await SharedPreferences.getInstance());

    expect(appState.currentLanguage, 'ca');
    expect(appState.tGenerateWorkout, 'Generar Entrenament');
  });

  test('setLanguage updates strings, persists and notifies listeners', () {
    final appState = AppState(prefs);
    var notifications = 0;
    appState.addListener(() => notifications++);

    appState.setLanguage('es');

    expect(appState.currentLanguage, 'es');
    expect(appState.tGenerateWorkout, 'Generar Entreno');
    expect(prefs.getString(AppState.keyLanguage), 'es');
    expect(notifications, 1);
  });

  test('setLanguage with the current language does not notify', () {
    final appState = AppState(prefs);
    var notifications = 0;
    appState.addListener(() => notifications++);

    appState.setLanguage('en');

    expect(notifications, 0);
  });

  group('localizedDbField', () {
    final row = <String, dynamic>{
      'title_en': 'Endurance',
      'title_es': 'Resistencia',
      'title_ca': 'Resistència',
      'notes_es': 'Solo en castellano',
    };

    test('returns the column for the current language', () {
      final appState = AppState(prefs)..setLanguage('ca');

      expect(appState.localizedDbField(row, 'title'), 'Resistència');
    });

    test('falls back to English, then Spanish', () {
      final appState = AppState(prefs)..setLanguage('ca');

      expect(
        appState.localizedDbField({'title_en': 'Endurance'}, 'title'),
        'Endurance',
      );
      expect(appState.localizedDbField(row, 'notes'), 'Solo en castellano');
    });

    test('returns an empty string when no column exists', () {
      final appState = AppState(prefs);

      expect(appState.localizedDbField(row, 'missing'), '');
    });
  });
}
