import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:swimvibe/core/workout_picker.dart';

Map<String, dynamic> workout(String id, int? distance, int? minutes) => {
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

  group('pickByDistance', () {
    String? pick(int distance, {Random? random}) =>
        pickByDistance(workouts, targetDistance: distance, random: random)?['id']
            as String?;

    test('returns the exact distance when it exists', () {
      expect(pick(1500), '1500a');
    });

    test('ignores the duration (long workouts can be picked)', () {
      expect(pick(2500), '2200a');
    });

    test('picks the closest distance above or below', () {
      expect(pick(300), '400a');
      expect(pick(1400), '1500a');
    });

    test('on a tie the longer distance wins', () {
      expect(pick(1000), '1100a'); // |900-1000| == |1100-1000|
    });

    test('chooses randomly among workouts with the same distance', () {
      final picked = {
        for (var seed = 0; seed < 20; seed++) pick(900, random: Random(seed)),
      };
      expect(picked, {'900a', '900b'});
    });

    test('returns null when there are no workouts', () {
      expect(pickByDistance([], targetDistance: 1000), isNull);
    });

    test('ignores rows without a distance', () {
      expect(
        pickByDistance([workout('x', null, 10), workout('y', 400, 10)],
            targetDistance: 1000)?['id'],
        'y',
      );
    });
  });

  group('pickByTime', () {
    String? pick(int minutes, {Random? random}) =>
        pickByTime(workouts, availableMinutes: minutes, random: random)?['id']
            as String?;

    test('returns the exact duration when it exists', () {
      expect(pick(27), '1100a');
    });

    test('picks the longest workout that does not exceed the time', () {
      expect(pick(30), '1100a'); // 27 min; 36 min would exceed
      expect(pick(25), '900a'); // 21 min; 26 min would exceed
      expect(pick(120), '2200a');
    });

    test('ignores the distance', () {
      expect(pick(10), '400a');
    });

    test('chooses randomly among workouts with the same duration', () {
      final sameDuration = [workout('a', 800, 20), workout('b', 900, 20)];
      final picked = {
        for (var seed = 0; seed < 20; seed++)
          pickByTime(sameDuration, availableMinutes: 20, random: Random(seed))?['id'],
      };
      expect(picked, {'a', 'b'});
    });

    test('returns null when nothing fits in the time', () {
      expect(pick(5), isNull);
    });

    test('ignores rows without a duration', () {
      expect(
        pickByTime([workout('x', 1000, null), workout('y', 400, 10)],
            availableMinutes: 60)?['id'],
        'y',
      );
    });
  });
}
