import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:swimvibe/core/app_state.dart';
import 'package:swimvibe/core/workout_share.dart';

void main() {
  Future<AppState> appStateIn(String lang) async {
    SharedPreferences.setMockInitialValues({AppState.keyLanguage: lang});
    return AppState(await SharedPreferences.getInstance());
  }

  final full = {
    'title_en': 'Pyramid',
    'title_es': 'Pirámide',
    'distance_meters': 2500,
    'duration_minutes': 45,
    'difficulty_level_es': 'Media',
    'warm_up_text_es': '400 libre suave\n',
    'main_set_text_es': '4x100 fuerte',
    'cool_down_text_es': '200 espalda',
  };

  test('builds the whole workout in the current language', () async {
    final text = workoutShareText(await appStateIn('es'), full);

    expect(
      text,
      '🏊 Pirámide\n\n'
      '2500 m · 45 min · Media\n\n'
      'Calentamiento\n400 libre suave\n\n'
      'Serie principal\n4x100 fuerte\n\n'
      'Vuelta a la calma\n200 espalda\n\n'
      '— SwimVibe',
    );
  });

  test('leaves out missing fields and falls back to a generic title', () async {
    final text = workoutShareText(await appStateIn('en'), {
      'distance_meters': 1500,
      'main_set_text_en': '10x100',
    });

    expect(text, '🏊 Workout\n\n1500 m\n\nMain Set\n10x100\n\n— SwimVibe');
  });
}
