import 'dart:math';

/// Picks the workout that best matches the requested session.
///
/// Rules:
/// 1. Only workouts whose `duration_minutes` is <= [availableMinutes].
/// 2. Among those, the closest `distance_meters` to [targetDistance]
///    (above or below). On a tie, the longer distance wins.
/// 3. If several workouts share that distance, one is chosen at random.
///
/// Returns null when no workout fits in the available time.
Map<String, dynamic>? pickWorkout(
  List<Map<String, dynamic>> workouts, {
  required int targetDistance,
  required int availableMinutes,
  Random? random,
}) {
  final candidates = workouts.where((w) {
    final duration = w['duration_minutes'];
    return w['distance_meters'] is int &&
        duration is int &&
        duration <= availableMinutes;
  }).toList();
  if (candidates.isEmpty) return null;

  int? bestDistance;
  for (final w in candidates) {
    final distance = w['distance_meters'] as int;
    if (bestDistance == null) {
      bestDistance = distance;
      continue;
    }
    final diff = (distance - targetDistance).abs();
    final bestDiff = (bestDistance - targetDistance).abs();
    if (diff < bestDiff || (diff == bestDiff && distance > bestDistance)) {
      bestDistance = distance;
    }
  }

  final best = candidates.where((w) => w['distance_meters'] == bestDistance).toList();
  return best[(random ?? Random()).nextInt(best.length)];
}
