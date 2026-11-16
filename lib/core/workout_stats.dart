import 'workout_history.dart';

/// Monday 00:00 (local) of [date]'s week.
DateTime weekStart(DateTime date) =>
    DateTime(date.year, date.month, date.day - (date.weekday - 1));

/// Totals for a group of logged workouts.
class PeriodStats {
  final int meters;
  final int workouts;
  final int minutes;

  const PeriodStats({this.meters = 0, this.workouts = 0, this.minutes = 0});

  factory PeriodStats.of(Iterable<LoggedWorkout> entries) => PeriodStats(
        meters: entries.fold(0, (sum, e) => sum + e.distanceMeters),
        workouts: entries.length,
        minutes: entries.fold(0, (sum, e) => sum + e.durationMinutes),
      );
}

/// Meters swum in the week starting on [start] (a Monday).
class WeekTotal {
  final DateTime start;
  final int meters;

  const WeekTotal(this.start, this.meters);
}

/// Everything the Progress screen shows, computed from the history.
///
/// Streaks use the *current* weekly goal for past weeks too (the goal's
/// history isn't stored).
class WorkoutStats {
  final PeriodStats total;
  final PeriodStats thisMonth;
  final PeriodStats lastMonth;

  /// 0 when there are no workouts.
  final int averageMeters;

  /// The longest workout by distance (most recent on a tie), or null.
  final LoggedWorkout? longest;

  /// The last [weeks] weeks, oldest first; the current week is last.
  final List<WeekTotal> lastWeeks;

  /// Consecutive weeks meeting the goal up to now. The current week only
  /// counts once the goal is met (until then it's still in progress).
  final int currentStreak;
  final int bestStreak;

  const WorkoutStats._({
    required this.total,
    required this.thisMonth,
    required this.lastMonth,
    required this.averageMeters,
    required this.longest,
    required this.lastWeeks,
    required this.currentStreak,
    required this.bestStreak,
  });

  factory WorkoutStats.compute(
    List<LoggedWorkout> entries, {
    required int weeklyGoal,
    DateTime? now,
    int weeks = 8,
  }) {
    final today = now ?? DateTime.now();

    // Months: [start, next start).
    final prevMonthStart = DateTime(today.year, today.month - 1);
    final monthStart = DateTime(today.year, today.month);
    final nextMonthStart = DateTime(today.year, today.month + 1);
    bool inRange(LoggedWorkout e, DateTime from, DateTime to) =>
        !e.completedAt.isBefore(from) && e.completedAt.isBefore(to);

    // Meters per week, keyed by Monday.
    final perWeek = <DateTime, int>{};
    for (final e in entries) {
      final key = weekStart(e.completedAt);
      perWeek[key] = (perWeek[key] ?? 0) + e.distanceMeters;
    }
    final thisWeek = weekStart(today);
    DateTime weeksAgo(int n) => DateTime(thisWeek.year, thisWeek.month, thisWeek.day - 7 * n);
    bool met(DateTime week) => (perWeek[week] ?? 0) >= weeklyGoal;

    // Current streak: from this week (if already met) or last week, backwards.
    var currentStreak = 0;
    for (var n = met(thisWeek) ? 0 : 1;; n++) {
      if (!met(weeksAgo(n))) break;
      currentStreak++;
    }

    // Best streak: every week from the first workout to now.
    var bestStreak = 0;
    if (entries.isNotEmpty) {
      final first = entries
          .map((e) => weekStart(e.completedAt))
          .reduce((a, b) => a.isBefore(b) ? a : b);
      var run = 0;
      for (var week = first;
          !week.isAfter(thisWeek);
          week = DateTime(week.year, week.month, week.day + 7)) {
        run = met(week) ? run + 1 : 0;
        if (run > bestStreak) bestStreak = run;
      }
    }

    LoggedWorkout? longest;
    for (final e in entries) {
      if (longest == null ||
          e.distanceMeters > longest.distanceMeters ||
          (e.distanceMeters == longest.distanceMeters &&
              e.completedAt.isAfter(longest.completedAt))) {
        longest = e;
      }
    }

    final total = PeriodStats.of(entries);
    return WorkoutStats._(
      total: total,
      thisMonth: PeriodStats.of(entries.where((e) => inRange(e, monthStart, nextMonthStart))),
      lastMonth: PeriodStats.of(entries.where((e) => inRange(e, prevMonthStart, monthStart))),
      averageMeters: total.workouts == 0 ? 0 : (total.meters / total.workouts).round(),
      longest: longest,
      lastWeeks: [
        for (var n = weeks - 1; n >= 0; n--) WeekTotal(weeksAgo(n), perWeek[weeksAgo(n)] ?? 0),
      ],
      currentStreak: currentStreak,
      bestStreak: bestStreak,
    );
  }
}
