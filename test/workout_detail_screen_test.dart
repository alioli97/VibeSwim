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
  }) async {
    SharedPreferences.setMockInitialValues({});
    final appState = AppState(await SharedPreferences.getInstance());
    await tester.pumpWidget(MaterialApp(
      home: WorkoutDetailScreen(
        appState: appState,
        mode: mode,
        value: value,
        repository: repository,
        share: share ?? (_, _) async {},
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

    await tester.runAsync(() async {
      await tester.tap(find.text('Finish & Log'));
      await Future<void>.delayed(Duration.zero);
    });
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
}
