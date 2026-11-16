import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:swimvibe/core/app_state.dart';
import 'package:swimvibe/core/workout_picker.dart';
import 'package:swimvibe/core/workout_repository.dart';
import 'package:swimvibe/core/workout_share.dart';
import 'package:swimvibe/screens/workout_detail_screen.dart';

/// In-memory stand-in for Supabase, applying the same duration filter.
class FakeWorkoutRepository implements WorkoutRepository {
  final List<Map<String, dynamic>> rows;
  int? lastMaxMinutes;

  FakeWorkoutRepository(this.rows);

  @override
  Future<List<Map<String, dynamic>>> fetchWorkouts({int? maxMinutes}) async {
    lastMaxMinutes = maxMinutes;
    return rows
        .where((r) => maxMinutes == null || (r['duration_minutes'] as int) <= maxMinutes)
        .toList();
  }
}

Map<String, dynamic> workout(String title, int meters, int minutes) => {
      'id': title,
      'title_en': title,
      'distance_meters': meters,
      'duration_minutes': minutes,
    };

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  final rows = [
    workout('Short', 1500, 30),
    workout('Medium', 2400, 45),
    workout('Long', 3500, 70),
  ];

  Future<AppState> pumpDetail(
    WidgetTester tester, {
    required SearchMode mode,
    required int value,
    required WorkoutRepository repository,
    ShareTextFn? share,
    String lang = 'en',
    DifficultyFilter difficulty = DifficultyFilter.any,
    List<String> doneRecently = const [],
  }) async {
    SharedPreferences.setMockInitialValues({AppState.keyLanguage: lang});
    final appState = AppState(await SharedPreferences.getInstance());
    for (final id in doneRecently) {
      await appState.history.add({'id': id, 'distance_meters': 100},
          completedAt: DateTime.now().subtract(const Duration(days: 3)));
    }
    await tester.pumpWidget(MaterialApp(
      home: WorkoutDetailScreen(
        appState: appState,
        mode: mode,
        value: value,
        repository: repository,
        share: share ?? (_, _) async {},
        difficulty: difficulty,
      ),
    ));
    await tester.pumpAndSettle();
    return appState;
  }

  testWidgets('distance mode shows the closest workout', (tester) async {
    final repo = FakeWorkoutRepository(rows);
    await pumpDetail(tester, mode: SearchMode.distance, value: 2500, repository: repo);

    expect(repo.lastMaxMinutes, isNull);
    expect(find.text('MEDIUM'), findsOneWidget);
    expect(find.text('SHORT'), findsNothing);
  });

  testWidgets('time mode picks the longest workout that fits', (tester) async {
    final repo = FakeWorkoutRepository(rows);
    await pumpDetail(tester, mode: SearchMode.time, value: 60, repository: repo);

    expect(repo.lastMaxMinutes, 60);
    expect(find.text('MEDIUM'), findsOneWidget);
    expect(find.text('LONG'), findsNothing);
  });

  testWidgets('shows a message when no workout fits the time', (tester) async {
    await pumpDetail(tester,
        mode: SearchMode.time, value: 20, repository: FakeWorkoutRepository(rows));

    expect(find.byIcon(Icons.search_off), findsOneWidget);
    expect(find.text('MEDIUM'), findsNothing);
    expect(find.text('Finish & Log'), findsOneWidget); // stays disabled
    final button = tester.widget<ElevatedButton>(
        find.ancestor(of: find.text('Finish & Log'), matching: find.byType(ElevatedButton)));
    expect(button.onPressed, isNull);
  });

  testWidgets('Finish & Log saves the workout once', (tester) async {
    final appState = await pumpDetail(tester,
        mode: SearchMode.distance, value: 1500, repository: FakeWorkoutRepository(rows));

    await tester.tap(find.text('Finish & Log'));
    await tester.pumpAndSettle();

    expect(appState.history.entries, hasLength(1));
    expect(appState.history.entries.single.workout['title_en'], 'Short');
    expect(find.text('Saved to your history'), findsOneWidget);
    expect(find.text('Logged'), findsOneWidget);

    final button = tester.widget<ElevatedButton>(
        find.ancestor(of: find.text('Logged'), matching: find.byType(ElevatedButton)));
    expect(button.onPressed, isNull);
  });

  testWidgets('share button shares the shown workout', (tester) async {
    final shared = <(String, String)>[];
    await pumpDetail(tester,
        mode: SearchMode.distance,
        value: 2500,
        repository: FakeWorkoutRepository(rows),
        share: (text, subject) async => shared.add((text, subject)));

    await tester.tap(find.byTooltip('Share'));
    await tester.pump();

    expect(shared, hasLength(1));
    expect(shared.single.$2, 'Medium');
    expect(shared.single.$1, startsWith('🏊 Medium\n\n2400 m · 45 min'));
  });

  testWidgets('share failure shows a message', (tester) async {
    await pumpDetail(tester,
        mode: SearchMode.distance,
        value: 2500,
        repository: FakeWorkoutRepository(rows),
        share: (_, _) async => throw Exception('no share sheet'));

    await tester.tap(find.byTooltip('Share'));
    await tester.pump();

    expect(find.text('Could not share the workout'), findsOneWidget);
  });

  testWidgets('share button is disabled when no workout fits', (tester) async {
    await pumpDetail(tester,
        mode: SearchMode.time, value: 20, repository: FakeWorkoutRepository(rows));

    final button = tester.widget<IconButton>(
        find.ancestor(of: find.byIcon(Icons.share), matching: find.byType(IconButton)));
    expect(button.onPressed, isNull);
  });

  testWidgets('Generate another cycles through the next closest without repeating',
      (tester) async {
    final appState = await pumpDetail(tester,
        mode: SearchMode.distance, value: 2500, repository: FakeWorkoutRepository(rows));
    expect(find.text('MEDIUM'), findsOneWidget);

    // Log it, then ask for another: the new one can be logged again.
    await tester.tap(find.text('Finish & Log'));
    await tester.pumpAndSettle();
    expect(find.text('Logged'), findsOneWidget);

    Future<void> another() async {
      await tester.tap(find.byTooltip('Generate another'));
      await tester.pumpAndSettle();
    }

    await another();
    expect(find.text('LONG'), findsOneWidget); // 1000 m away, tie with Short → longer
    expect(find.text('Finish & Log'), findsOneWidget);

    await another();
    expect(find.text('SHORT'), findsOneWidget);

    await another(); // all seen: starts over, skipping the current one
    expect(find.text('MEDIUM'), findsOneWidget);

    expect(appState.history.entries, hasLength(1));
  });

  testWidgets('Generate another says so when there is no other workout', (tester) async {
    await pumpDetail(tester,
        mode: SearchMode.time,
        value: 40,
        repository: FakeWorkoutRepository(rows)); // only Short fits in 40 min

    await tester.tap(find.byTooltip('Generate another'));
    await tester.pump();

    expect(find.text('SHORT'), findsOneWidget);
    expect(find.text('No other workout matches'), findsOneWidget);
  });

  testWidgets('bottom actions fit on a small phone in Spanish', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpDetail(tester,
        mode: SearchMode.distance,
        value: 2500,
        repository: FakeWorkoutRepository(rows),
        lang: 'es');

    expect(find.byTooltip('Generar otro'), findsOneWidget);
    expect(find.text('Terminar y guardar'), findsOneWidget);
    expect(tester.takeException(), isNull); // no overflow
  });

  testWidgets('settings button changes the language on the detail screen', (tester) async {
    final appState = await pumpDetail(tester,
        mode: SearchMode.distance, value: 2500, repository: FakeWorkoutRepository(rows));
    expect(find.text('Finish & Log'), findsOneWidget);

    await tester.tap(find.byTooltip('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Català'));
    await tester.pumpAndSettle();

    expect(appState.currentLanguage, 'ca');
    expect(find.text('Acabar i desar'), findsOneWidget);
  });

  group('smarter picking', () {
    final leveled = [
      {...workout('Easy 2400', 2400, 45), 'difficulty_level_en': 'Beginner'},
      {...workout('Hard 2400', 2400, 45), 'difficulty_level_en': 'Advanced / Expert'},
      {...workout('Mid 2200', 2200, 40), 'difficulty_level_en': 'Intermediate'},
    ];

    testWidgets('skips a workout done in the last 14 days', (tester) async {
      await pumpDetail(tester,
          mode: SearchMode.distance,
          value: 2500,
          repository: FakeWorkoutRepository(rows),
          doneRecently: ['Medium']);

      expect(find.text('MEDIUM'), findsNothing);
      expect(find.text('LONG'), findsOneWidget); // next closest that wasn't done
    });

    testWidgets('still shows a recent workout when nothing else fits', (tester) async {
      await pumpDetail(tester,
          mode: SearchMode.time,
          value: 40,
          repository: FakeWorkoutRepository(rows), // only Short fits
          doneRecently: ['Short']);

      expect(find.text('SHORT'), findsOneWidget);
    });

    testWidgets('only picks workouts of the chosen difficulty', (tester) async {
      await pumpDetail(tester,
          mode: SearchMode.distance,
          value: 2400,
          repository: FakeWorkoutRepository(leveled),
          difficulty: DifficultyFilter.advanced);

      expect(find.text('HARD 2400'), findsOneWidget);
    });

    testWidgets('says when no workout has the chosen difficulty', (tester) async {
      await pumpDetail(tester,
          mode: SearchMode.distance,
          value: 2400,
          repository: FakeWorkoutRepository(rows), // no difficulty at all
          difficulty: DifficultyFilter.beginner);

      expect(find.text('No beginner workouts match. Try another difficulty.'), findsOneWidget);
    });
  });

  testWidgets('star button adds and removes the workout from favorites', (tester) async {
    final appState = await pumpDetail(tester,
        mode: SearchMode.distance, value: 2500, repository: FakeWorkoutRepository(rows));

    await tester.tap(find.byTooltip('Add to favorites'));
    await tester.pumpAndSettle();
    expect(appState.favorites.isFavorite('Medium'), isTrue);
    expect(find.text('Added to favorites'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove from favorites'));
    await tester.pumpAndSettle();
    expect(appState.favorites.items, isEmpty);

    // Let the snackbar time out so no timers are left pending.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
