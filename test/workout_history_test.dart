import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:swimvibe/core/workout_history.dart';

Map<String, dynamic> workout(String id, int distance) => {
      'id': id,
      'distance_meters': distance,
      'duration_minutes': 20,
      'title_en': 'Workout $id',
      'title_es': 'Entreno $id',
    };

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('starts empty', () {
    final history = WorkoutHistory(prefs);

    expect(history.entries, isEmpty);
    expect(history.totalDistance, 0);
  });

  test('add stores entries newest first and notifies', () async {
    final history = WorkoutHistory(prefs);
    var notifications = 0;
    history.addListener(() => notifications++);

    await history.add(workout('a', 800), completedAt: DateTime(2026, 11, 10, 9));
    await history.add(workout('b', 1500), completedAt: DateTime(2026, 11, 12, 9));
    await history.add(workout('c', 400), completedAt: DateTime(2026, 11, 11, 9));

    expect(history.entries.map((e) => e.workout['id']), ['b', 'c', 'a']);
    expect(history.totalDistance, 2700);
    expect(notifications, 3);
  });

  test('persists across instances (app restart)', () async {
    final completedAt = DateTime(2026, 11, 12, 18, 30);
    await WorkoutHistory(prefs).add(workout('a', 900), completedAt: completedAt);

    final reloaded = WorkoutHistory(prefs);

    expect(reloaded.entries, hasLength(1));
    expect(reloaded.entries.single.workout['title_es'], 'Entreno a');
    expect(reloaded.entries.single.completedAt, completedAt);
    expect(reloaded.totalDistance, 900);
  });

  test('distanceThisWeek counts from Monday 00:00', () async {
    final history = WorkoutHistory(prefs);
    // Wednesday 2026-11-18; that week starts Monday 2026-11-16.
    final now = DateTime(2026, 11, 18, 12);

    await history.add(workout('sun', 1000), completedAt: DateTime(2026, 11, 15, 23, 59));
    await history.add(workout('mon', 800), completedAt: DateTime(2026, 11, 16, 0, 0));
    await history.add(workout('wed', 400), completedAt: DateTime(2026, 11, 18, 8));

    expect(history.distanceThisWeek(now), 1200);
  });

  test('remove deletes only that entry, persists, and restore undoes it', () async {
    final history = WorkoutHistory(prefs);
    // Two identical workouts logged on different days.
    await history.add(workout('a', 800), completedAt: DateTime(2026, 11, 10, 9));
    await history.add(workout('a', 800), completedAt: DateTime(2026, 11, 12, 9));
    await history.add(workout('b', 400), completedAt: DateTime(2026, 11, 11, 9));
    final mistake = history.entries.first; // a on the 12th

    expect(await history.remove(mistake), isTrue);
    expect(history.entries.map((e) => e.completedAt.day), [11, 10]);
    expect(history.totalDistance, 1200);
    expect(WorkoutHistory(prefs).entries, hasLength(2)); // persisted

    expect(await history.remove(mistake), isFalse); // already gone

    await history.restore(mistake);
    expect(history.entries.map((e) => e.completedAt.day), [12, 11, 10]);
    expect(WorkoutHistory(prefs).totalDistance, 2000);
  });

  test('weekly goal defaults to 5000 and can be changed and persisted', () async {
    final history = WorkoutHistory(prefs);
    var notifications = 0;
    history.addListener(() => notifications++);

    expect(history.weeklyGoalMeters, WorkoutHistory.defaultWeeklyGoalMeters);
    expect(history.weeklyGoalMeters, 5000);

    await history.setWeeklyGoal(8000);
    expect(history.weeklyGoalMeters, 8000);
    expect(WorkoutHistory(prefs).weeklyGoalMeters, 8000);

    await history.setWeeklyGoal(0); // invalid: ignored
    await history.setWeeklyGoal(8000); // unchanged: no notification
    expect(history.weeklyGoalMeters, 8000);
    expect(notifications, 1);
  });

  test('ignores corrupt stored data', () async {
    SharedPreferences.setMockInitialValues({WorkoutHistory.keyHistory: 'not json'});
    expect(WorkoutHistory(await SharedPreferences.getInstance()).entries, isEmpty);

    SharedPreferences.setMockInitialValues({
      WorkoutHistory.keyHistory:
          '[{"workout": {"distance_meters": 500}, "completed_at": "2026-11-10T10:00:00Z"}, {"bad": 1}, 3]',
    });
    final history = WorkoutHistory(await SharedPreferences.getInstance());
    expect(history.entries, hasLength(1));
    expect(history.totalDistance, 500);
  });
}
