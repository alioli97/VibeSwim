import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A workout the user finished, with a snapshot of the Supabase row so the
/// history works offline and keeps its translations (title_en/es/ca, ...).
class LoggedWorkout {
  final Map<String, dynamic> workout;
  final DateTime completedAt;

  const LoggedWorkout({required this.workout, required this.completedAt});

  int get distanceMeters => (workout['distance_meters'] as num?)?.toInt() ?? 0;

  Map<String, dynamic> toJson() => {
        'workout': workout,
        'completed_at': completedAt.toUtc().toIso8601String(),
      };

  /// Returns null for malformed entries instead of throwing.
  static LoggedWorkout? fromJson(Object? json) {
    if (json is! Map) return null;
    final workout = json['workout'];
    final completedAt = DateTime.tryParse('${json['completed_at']}');
    if (workout is! Map || completedAt == null) return null;
    return LoggedWorkout(
      workout: Map<String, dynamic>.from(workout),
      completedAt: completedAt.toLocal(),
    );
  }
}

/// The user's completed workouts, stored on the device in SharedPreferences.
class WorkoutHistory extends ChangeNotifier {
  static const String keyHistory = 'workout_history';
  static const String keyWeeklyGoal = 'weekly_goal_meters';
  static const int defaultWeeklyGoalMeters = 5000;

  final SharedPreferences prefs;
  final List<LoggedWorkout> _entries;
  int _weeklyGoalMeters;

  WorkoutHistory(this.prefs)
      : _entries = _load(prefs),
        _weeklyGoalMeters = _loadWeeklyGoal(prefs);

  /// Newest first.
  List<LoggedWorkout> get entries => List.unmodifiable(_entries);

  /// Meters per week the "Weekly goal" progress bar aims for (user-set).
  int get weeklyGoalMeters => _weeklyGoalMeters;

  Future<void> setWeeklyGoal(int meters) async {
    if (meters <= 0 || meters == _weeklyGoalMeters) return;
    _weeklyGoalMeters = meters;
    notifyListeners();
    await prefs.setInt(keyWeeklyGoal, meters);
  }

  int get totalDistance => _entries.fold(0, (sum, e) => sum + e.distanceMeters);

  /// Meters completed since Monday 00:00 (local time) of [now]'s week.
  int distanceThisWeek([DateTime? now]) {
    final today = now ?? DateTime.now();
    final monday = DateTime(today.year, today.month, today.day - (today.weekday - 1));
    return _entries
        .where((e) => !e.completedAt.isBefore(monday))
        .fold(0, (sum, e) => sum + e.distanceMeters);
  }

  Future<void> add(Map<String, dynamic> workout, {DateTime? completedAt}) {
    return restore(
      LoggedWorkout(workout: Map.of(workout), completedAt: completedAt ?? DateTime.now()),
    );
  }

  /// Adds [entry] back, e.g. to undo a [remove].
  Future<void> restore(LoggedWorkout entry) async {
    _entries.add(entry);
    _entries.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    notifyListeners();
    await _save();
  }

  /// Removes that exact entry (one logged by mistake). Returns false if it
  /// wasn't in the history.
  Future<bool> remove(LoggedWorkout entry) async {
    final removed = _entries.remove(entry);
    if (!removed) return false;
    notifyListeners();
    await _save();
    return true;
  }

  Future<void> _save() => prefs.setString(
        keyHistory,
        jsonEncode(_entries.map((e) => e.toJson()).toList()),
      );

  static int _loadWeeklyGoal(SharedPreferences prefs) {
    final goal = prefs.getInt(keyWeeklyGoal);
    return goal != null && goal > 0 ? goal : defaultWeeklyGoalMeters;
  }

  static List<LoggedWorkout> _load(SharedPreferences prefs) {
    final raw = prefs.getString(keyHistory);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded.map(LoggedWorkout.fromJson).whereType<LoggedWorkout>().toList()
        ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    } on FormatException {
      return [];
    }
  }
}
