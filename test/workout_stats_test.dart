import 'package:flutter_test/flutter_test.dart';

import 'package:swimvibe/core/workout_history.dart';
import 'package:swimvibe/core/workout_stats.dart';

LoggedWorkout logged(int meters, DateTime at, {int minutes = 30}) => LoggedWorkout(
      workout: {'distance_meters': meters, 'duration_minutes': minutes},
      completedAt: at,
    );

void main() {
  // Wednesday; its week starts on Monday 16 Nov 2026.
  final now = DateTime(2026, 11, 18, 12);

  final entries = [
    logged(1000, DateTime(2026, 11, 17, 8)), // this week: 1000 (goal not met yet)
    logged(2000, DateTime(2026, 11, 10, 8)), // week of 9 Nov: 2000 ✓
    logged(1500, DateTime(2026, 11, 3, 8)), // week of 2 Nov: 2500 ✓
    logged(1000, DateTime(2026, 11, 5, 8)),
    // week of 26 Oct: nothing
    logged(2000, DateTime(2026, 10, 20, 8)), // 19 Oct ✓
    logged(2500, DateTime(2026, 10, 13, 8)), // 12 Oct ✓
    logged(3000, DateTime(2026, 10, 6, 8)), // 5 Oct ✓
  ];

  final stats = WorkoutStats.compute(entries, weeklyGoal: 2000, now: now);

  test('totals and averages', () {
    expect(stats.total.meters, 13000);
    expect(stats.total.workouts, 7);
    expect(stats.total.minutes, 210);
    expect(stats.averageMeters, 1857);
    expect(stats.longest!.distanceMeters, 3000);
  });

  test('this month vs last month', () {
    expect(stats.thisMonth.meters, 5500);
    expect(stats.thisMonth.workouts, 4);
    expect(stats.lastMonth.meters, 7500);
    expect(stats.lastMonth.workouts, 3);
  });

  test('last 8 weeks, oldest first, Monday-based', () {
    expect(stats.lastWeeks.map((w) => w.start.day), [28, 5, 12, 19, 26, 2, 9, 16]);
    expect(stats.lastWeeks.map((w) => w.meters), [0, 3000, 2500, 2000, 0, 2500, 2000, 1000]);
  });

  test('streaks: current week in progress does not break the streak', () {
    expect(stats.currentStreak, 2);
    expect(stats.bestStreak, 3);
  });

  test('current week counts once the goal is met', () {
    final more = [...entries, logged(1000, DateTime(2026, 11, 18, 8))];
    final s = WorkoutStats.compute(more, weeklyGoal: 2000, now: now);
    expect(s.currentStreak, 3);
    expect(s.bestStreak, 3);
  });

  test('a missed week resets the current streak', () {
    final s = WorkoutStats.compute(entries, weeklyGoal: 2000, now: DateTime(2026, 11, 25));
    // Week of 16 Nov ended with 1000 < 2000.
    expect(s.currentStreak, 0);
  });

  test('empty history', () {
    final s = WorkoutStats.compute([], weeklyGoal: 5000, now: now);
    expect(s.total.workouts, 0);
    expect(s.averageMeters, 0);
    expect(s.longest, isNull);
    expect(s.currentStreak, 0);
    expect(s.bestStreak, 0);
    expect(s.lastWeeks, hasLength(8));
  });
}
