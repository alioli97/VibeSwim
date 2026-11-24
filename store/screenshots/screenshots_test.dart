// App Store screenshots, rendered from the real screens with sample data.
//
// Not part of the regular test suite (CI only runs test/). Regenerate with:
//   flutter test store/screenshots/screenshots_test.dart --update-goldens
//   python3 store/screenshots/flatten_ios.py
// The PNGs land in store/screenshots/ios/{en,es,ca}/: 6.3" iPhone (1206×2622),
// the size App Store Connect requires ("iPhone with Dynamic Island (medium
// display)"), rendered with the iOS platform and the iPhone's safe area insets.
//
// Workouts come from workouts.json, a copy of real rows of the Supabase
// `workouts` table (the test never connects to Supabase).
//
// Lexend and Inter are the bundled app fonts. Text styles the theme doesn't
// set use the iOS system font (San Francisco), which is not available here:
// Roboto from the Flutter SDK cache stands in for it.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugDefaultTargetPlatformOverride;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:swimvibe/core/app_state.dart';
import 'package:swimvibe/core/favorites.dart';
import 'package:swimvibe/core/workout_history.dart';
import 'package:swimvibe/core/workout_picker.dart';
import 'package:swimvibe/core/workout_repository.dart';
import 'package:swimvibe/core/workout_stats.dart';
import 'package:swimvibe/main.dart';
import 'package:swimvibe/screens/history_screen.dart';
import 'package:swimvibe/screens/progress_screen.dart';
import 'package:swimvibe/screens/workout_detail_screen.dart';
import 'package:swimvibe/theme/app_theme.dart';

// 6.3" iPhone: 402×874 logical px, status bar / Dynamic Island and home
// indicator insets (62 and 34 logical px).
const _size = Size(1206, 2622);
const _pixelRatio = 3.0;
const _padding = FakeViewPadding(top: 186, bottom: 102);

/// The workout shown on the detail screenshots (by `title_en`).
const _featured = 'Individual Medley & Kick Power Session';

late final List<Map<String, dynamic>> _workouts;

class _FixedRepository implements WorkoutRepository {
  final List<Map<String, dynamic>> rows;
  const _FixedRepository(this.rows);

  @override
  Future<List<Map<String, dynamic>>> fetchWorkouts({int? maxMinutes}) async => rows;
}

Future<void> _loadFonts() async {
  // The test runs inside the SDK's flutter_tester; walk up to find the fonts.
  Directory? dir;
  for (var d = File(Platform.resolvedExecutable).parent;
      d.parent.path != d.path;
      d = d.parent) {
    for (final sub in ['material_fonts', 'artifacts/material_fonts']) {
      final candidate = Directory('${d.path}/$sub');
      if (candidate.existsSync()) dir = candidate;
    }
    if (dir != null) break;
  }
  if (dir == null) throw StateError('Material fonts not found in the SDK');
  final fonts = dir;
  Future<ByteData> read(String name) async =>
      ByteData.sublistView(await File('${fonts.path}/$name').readAsBytes());

  for (final family in [
    'Roboto',
    'CupertinoSystemText',
    'CupertinoSystemDisplay',
    '.AppleSystemUIFont',
  ]) {
    final loader = FontLoader(family);
    for (final w in ['Light', 'Regular', 'Medium', 'Bold']) {
      loader.addFont(read('Roboto-$w.ttf'));
    }
    await loader.load();
  }
  await (FontLoader('MaterialIcons')..addFont(read('MaterialIcons-Regular.otf'))).load();

  final text = AppTheme.lightTheme.textTheme;
  await GoogleFonts.pendingFonts(
      [text.displayLarge, text.displaySmall, text.titleLarge, text.bodyMedium]);
}

Map<String, dynamic> _byTitle(String title) =>
    _workouts.firstWhere((w) => w['title_en'] == title);

/// About eight weeks of swimming: two or three workouts a week, most weeks
/// above the 5 km goal, and two workouts so far this week.
String _history() {
  final monday = weekStart(DateTime.now());
  final plan = <(int, int, String)>[
    // (weeks ago, day of the week 0–6, title)
    (0, 0, 'Aerobic Endurance and Leg Propulsion'),
    (0, 1, 'Individual Medley & Kick Power Session'),
    (1, 0, 'Segmented Power & Speed Contrast Session'),
    (1, 2, 'Aerobic Endurance and Leg Propulsion'),
    (1, 4, 'Fins Endurance and Efficiency Medley'),
    (2, 1, 'Individual Medley & Kick Power Session'),
    (2, 3, 'Segmented Power & Speed Contrast Session'),
    (2, 5, 'Quality and Efficiency Session'),
    (2, 6, 'Core Freestyle Routine'),
    (3, 0, 'Aerobic Power and Speed Transfer'),
    (3, 2, 'Individual Medley & Kick Power Session'),
    (3, 4, 'Fins Endurance and Efficiency Medley'),
    (4, 1, 'Aerobic Endurance and Leg Propulsion'),
    (4, 3, 'Segmented Power & Speed Contrast Session'),
    (4, 5, 'Threshold Endurance and Consolidation Volume'),
    (5, 2, 'Individual Medley & Kick Power Session'),
    (5, 4, 'Applied Technique and Aerobic Endurance'),
    (6, 0, 'Aerobic Endurance and Medley Variety'),
    (6, 3, 'Aerobic Endurance and Leg Propulsion'),
    (6, 5, 'Fins Endurance and Efficiency Medley'),
    (7, 1, 'Quality and Efficiency Session'),
    (7, 4, 'Core Freestyle Routine'),
  ];
  return jsonEncode([
    for (final (weeksAgo, day, title) in plan)
      LoggedWorkout(
        workout: _byTitle(title),
        completedAt: monday.add(Duration(days: day - 7 * weeksAgo, hours: 7, minutes: 30)),
      ).toJson(),
  ]);
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting();
    await _loadFonts();
    final raw = await File('store/screenshots/workouts.json').readAsString();
    _workouts = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  });

  for (final lang in ['en', 'es', 'ca']) {
    testWidgets('screenshots ($lang)', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      // flutter_test draws elevation shadows as solid black outlines; render
      // real ones (restored at the end: the framework checks it is reset).
      debugDisableShadows = false;
      tester.view.physicalSize = _size;
      tester.view.devicePixelRatio = _pixelRatio;
      tester.view.padding = _padding;
      tester.view.viewPadding = _padding;
      addTearDown(tester.view.reset);
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;
      addTearDown(
          () => FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic);

      final featured = _byTitle(_featured);
      // A test, but outside test/, so the analyzer doesn't know it.
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({
        AppState.keyLanguage: lang,
        WorkoutHistory.keyHistory: _history(),
        Favorites.keyFavorites: jsonEncode([featured]),
      });
      final appState = AppState(await SharedPreferences.getInstance());

      Future<void> shot(String name) async {
        await tester.pumpAndSettle();
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('ios/$lang/$name.png'));
      }

      Future<void> show(Widget screen) async {
        await tester.pumpWidget(MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: screen,
        ));
        await tester.pumpAndSettle();
      }

      await tester.pumpWidget(SwimVibeApp(appState: appState));
      await shot('1_home');

      await show(WorkoutDetailScreen(
        appState: appState,
        mode: SearchMode.distance,
        value: 1500,
        repository: _FixedRepository([featured]),
        share: (_, _) async {},
      ));
      await shot('2_workout');


      await show(ProgressScreen(appState: appState));
      await shot('3_progress');

      await show(HistoryScreen(appState: appState));
      await shot('4_history');

      debugDisableShadows = true;
      debugDefaultTargetPlatformOverride = null;
    });
  }
}
