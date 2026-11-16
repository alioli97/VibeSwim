import 'dart:math';

/// How the user searches for a workout: by distance OR by time, never both.
enum SearchMode { distance, time }

/// Picks the workout whose `distance_meters` is closest to [targetDistance]
/// (above or below; on a tie the longer distance wins). The duration is
/// ignored. If several workouts share that distance, one is chosen at random.
///
/// Workouts whose `id` is in [exclude] are skipped (used by "Generate
/// another" so the next closest is chosen once a distance is used up).
///
/// Returns null when there are no workouts with a distance.
Map<String, dynamic>? pickByDistance(
  List<Map<String, dynamic>> workouts, {
  required int targetDistance,
  Set<Object?> exclude = const {},
  Random? random,
}) {
  return _pickClosest(
    workouts
        .where((w) => w['distance_meters'] is int && !exclude.contains(w['id']))
        .toList(),
    field: 'distance_meters',
    target: targetDistance,
    random: random,
  );
}

/// Picks the workout whose `duration_minutes` is closest to
/// [availableMinutes] without exceeding it. The distance is ignored. If
/// several workouts share that duration, one is chosen at random.
///
/// Workouts whose `id` is in [exclude] are skipped.
///
/// Returns null when no workout fits in the available time.
Map<String, dynamic>? pickByTime(
  List<Map<String, dynamic>> workouts, {
  required int availableMinutes,
  Set<Object?> exclude = const {},
  Random? random,
}) {
  return _pickClosest(
    workouts.where((w) {
      final duration = w['duration_minutes'];
      return duration is int &&
          duration <= availableMinutes &&
          !exclude.contains(w['id']);
    }).toList(),
    field: 'duration_minutes',
    target: availableMinutes,
    random: random,
  );
}

/// Closest [field] value to [target] (ties → larger value), random among
/// the candidates that share it. [candidates] must all have an int [field].
Map<String, dynamic>? _pickClosest(
  List<Map<String, dynamic>> candidates, {
  required String field,
  required int target,
  Random? random,
}) {
  if (candidates.isEmpty) return null;

  var best = candidates.first[field] as int;
  for (final w in candidates) {
    final value = w[field] as int;
    final diff = (value - target).abs();
    final bestDiff = (best - target).abs();
    if (diff < bestDiff || (diff == bestDiff && value > best)) {
      best = value;
    }
  }

  final matches = candidates.where((w) => w[field] == best).toList();
  return matches[(random ?? Random()).nextInt(matches.length)];
}

/// Difficulty chosen on the home screen before generating.
enum DifficultyFilter { any, beginner, intermediate, advanced }

/// Whether [workout] fits [filter], based on `difficulty_level_en` (free
/// text such as "Beginner / Intermediate"): a combo matches each of its
/// levels, and "Expert" counts as advanced. Workouts without a difficulty
/// only match [DifficultyFilter.any].
bool matchesDifficulty(Map<String, dynamic> workout, DifficultyFilter filter) {
  if (filter == DifficultyFilter.any) return true;
  final level = '${workout['difficulty_level_en'] ?? ''}'.toLowerCase();
  return switch (filter) {
    DifficultyFilter.any => true,
    DifficultyFilter.beginner => level.contains('beginner'),
    DifficultyFilter.intermediate => level.contains('intermediate'),
    DifficultyFilter.advanced => level.contains('advanced') || level.contains('expert'),
  };
}
