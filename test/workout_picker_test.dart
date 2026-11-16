import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:swimvibe/core/workout_picker.dart';

Map<String, dynamic> workout(String id, int distance, int? minutes) => {
      'id': id,
      'distance_meters': distance,
      'duration_minutes': minutes,
    };

void main() {
  final workouts = [
    workout('400a', 400, 9),
    workout('800a', 800, 18),
    workout('900a', 900, 21),
    workout('900b', 900, 26),
    workout('1100a', 1100, 27),
    workout('1500a', 1500, 36),
    workout('2200a', 2200, 62),
  ];

  String? pickId(int distance, int minutes, {Random? random}) => pickWorkout(
        workouts,
        targetDistance: distance,
        availableMinutes: minutes,
        random: random,
      )?['id'] as String?;

  test('returns the exact distance when it fits in the time', () {
    expect(pickId(1500, 45), '1500a');
  });

  test('picks the closest distance that fits in the time', () {
    // 2500 m with 30 min: 1500 (36) and 2200 (62) are too long -> 1100.
    expect(pickId(2500, 30), '1100a');
    // 2500 m with 90 min: 2200 is the closest.
    expect(pickId(2500, 90), '2200a');
  });

  test('can pick a longer distance when it is closer', () {
    expect(pickId(300, 30), '400a');
    expect(pickId(1000, 30), '1100a'); // |1100-1000| = |900-1000| -> longer wins
  });

  test('on a distance tie the longer workout wins', () {
    expect(pickId(850, 30), startsWith('900'));
  });

  test('chooses randomly among workouts with the same distance', () {
    final picked = {
      for (var seed = 0; seed < 20; seed++) pickId(900, 30, random: Random(seed)),
    };
    expect(picked, {'900a', '900b'});
  });

  test('respects the available time within the same distance', () {
    expect(pickId(900, 22), '900a');
  });

  test('returns null when nothing fits in the time', () {
    expect(pickId(1000, 5), isNull);
    expect(pickWorkout([], targetDistance: 1000, availableMinutes: 60), isNull);
  });

  test('ignores rows without a duration', () {
    expect(
      pickWorkout(
        [workout('x', 1000, null), workout('y', 400, 10)],
        targetDistance: 1000,
        availableMinutes: 60,
      )?['id'],
      'y',
    );
  });
}
