import 'package:share_plus/share_plus.dart';

import 'app_state.dart';

/// Opens the system share sheet (on web: Web Share API, else a mailto link).
typedef ShareTextFn = Future<void> Function(String text, String subject);

Future<void> shareWithSystem(String text, String subject) =>
    SharePlus.instance.share(ShareParams(text: text, subject: subject));

/// Plain-text version of [workout] in the current language, for sharing.
/// Empty fields are left out.
String workoutShareText(AppState appState, Map<String, dynamic> workout) {
  final title = appState.localizedDbField(workout, 'title');
  final difficulty = appState.localizedDbField(workout, 'difficulty_level');
  final distance = workout['distance_meters'];
  final duration = workout['duration_minutes'];

  final stats = [
    if (distance != null) '$distance m',
    if (duration != null) '$duration min',
    if (difficulty.isNotEmpty) difficulty,
  ].join(' · ');

  final sections = [
    (appState.tWarmUp, appState.localizedDbField(workout, 'warm_up_text')),
    (appState.tMainSet, appState.localizedDbField(workout, 'main_set_text')),
    (appState.tCoolDown, appState.localizedDbField(workout, 'cool_down_text')),
  ].where((s) => s.$2.trim().isNotEmpty);

  return [
    '🏊 ${title.isNotEmpty ? title : appState.tWorkout}',
    if (stats.isNotEmpty) stats,
    for (final (label, text) in sections) '$label\n${text.trim()}',
    '— SwimVibe',
  ].join('\n\n');
}
