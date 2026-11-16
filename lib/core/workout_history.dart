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

  /// Meters per week the "Weekly goal" progress bar aims for.
  static const int weeklyGoalMeters = 5000;

  final SharedPreferences prefs;
  final List<LoggedWorkout> _entries;

  WorkoutHistory(this.prefs) : _entries = _load(prefs);

  /// Newest first.
  List<LoggedWorkout> get entries => List.unmodifiable(_entries);

  int get totalDistance => _entries.fold(0, (sum, e) => sum + e.distanceMeters);

  /// Meters completed since Monday 00:00 (local time) of [now]'s week.
  int distanceThisWeek([DateTime? now]) {
    final today = now ?? DateTime.now();
    final monday = DateTime(today.year, today.month, today.day - (today.weekday - 1));
    return _entries
        .where((e) => !e.completedAt.isBefore(monday))
        .fold(0, (sum, e) => sum + e.distanceMeters);
  }

  Future<void> add(Map<String, dynamic> workout, {DateTime? completedAt}) async {
    _entries.insert(
      0,
      LoggedWorkout(workout: Map.of(workout), completedAt: completedAt ?? DateTime.now()),
    );
    _entries.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    notifyListeners();
    await prefs.setString(
      keyHistory,
      jsonEncode(_entries.map((e) => e.toJson()).toList()),
    );
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
