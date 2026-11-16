import 'dart:math';

/// How the user searches for a workout: by distance OR by time, never both.
enum SearchMode { distance, time }

/// Picks the workout whose `distance_meters` is closest to [targetDistance]
/// (above or below; on a tie the longer distance wins). The duration is
/// ignored. If several workouts share that distance, one is chosen at random.
///
/// Returns null when there are no workouts with a distance.
Map<String, dynamic>? pickByDistance(
  List<Map<String, dynamic>> workouts, {
  required int targetDistance,
  Random? random,
}) {
  return _pickClosest(
    workouts.where((w) => w['distance_meters'] is int).toList(),
    field: 'distance_meters',
    target: targetDistance,
    random: random,
  );
}

/// Picks the workout whose `duration_minutes` is closest to
/// [availableMinutes] without exceeding it. The distance is ignored. If
/// several workouts share that duration, one is chosen at random.
///
/// Returns null when no workout fits in the available time.
Map<String, dynamic>? pickByTime(
  List<Map<String, dynamic>> workouts, {
  required int availableMinutes,
  Random? random,
}) {
  return _pickClosest(
    workouts.where((w) {
      final duration = w['duration_minutes'];
      return duration is int && duration <= availableMinutes;
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
