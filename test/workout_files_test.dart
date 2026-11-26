import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/src/workout_file.dart';

const _valid = '''
id: 4abad035-9e7c-4817-aaf3-f31c1d8fc949
distance_meters: 600
duration_minutes: 20
difficulty: beginner
title:
  en: "Easy It's"
  es: "Fácil"
  ca: "Fàcil"
warm_up:
  en: |-
    200 easy
  es: |-
    200 suave
  ca: |-
    200 suau
main_set:
  en: |-
    4x50 kick
    100 drills
  es: |-
    4x50 pies
    100 técnica
  ca: |-
    4x50 peus
    100 tècnica
cool_down:
  en: |-
    100 easy
  es: |-
    100 suave
  ca: |-
    100 suau
''';

WorkoutFile _parse(String yaml, [String number = '0600_001']) =>
    WorkoutFile.parse(number, yaml);

void main() {
  test('every file in workouts/ is valid and ids are unique', () {
    final files = Directory('workouts')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.yaml'))
        .toList();
    expect(files, isNotEmpty);
    final ids = <String>{};
    for (final file in files) {
      final name = file.uri.pathSegments.last.replaceAll('.yaml', '');
      final workout = WorkoutFile.parse(name, file.readAsStringSync());
      expect(workout.validate(), isEmpty, reason: name);
      expect(ids.add(workout.id), isTrue, reason: '$name repeats an id');
    }
  });

  test('a complete workout is valid and becomes a row', () {
    final w = _parse(_valid);
    expect(w.validate(), isEmpty);
    final row = w.toRow();
    expect(row['number_train_by_meters'], '0600_001');
    expect(row['difficulty_level_es'], 'Principiante');
    expect(row['main_set_text_ca'], '4x50 peus\n100 tècnica');
  });

  test('YAML output parses back to the same row', () {
    final w = _parse(_valid);
    expect(_parse(w.toYaml()).toRow(), w.toRow());
  });

  test('meters that do not add up are reported per language', () {
    final w = _parse(_valid.replaceFirst('4x50 pies', '4x25 pies'));
    expect(w.validate(), ['the es lines add up to 500 m, not 600 m']);
  });

  test('missing translations, lines without meters and bad names', () {
    final w = _parse(
      _valid
          .replaceFirst('"Fàcil"', '""')
          .replaceFirst('100 tècnica', 'tècnica')
          .replaceFirst('difficulty: beginner', 'difficulty: easy'),
      '0500_001',
    );
    final errors = w.validate();
    expect(errors, contains('title.ca is missing'));
    expect(errors, contains(startsWith('difficulty must be one of')));
    expect(errors, contains(startsWith('main_set.ca: "tècnica" must start')));
    expect(errors, contains(startsWith('the number 0500 does not match')));
  });

  test('warm-up and cool-down are optional, but all or no languages', () {
    final noWarmUp = _valid
        .replaceFirst(RegExp(r'warm_up:[\s\S]*?main_set:'), 'main_set:')
        .replaceFirst('distance_meters: 600', 'distance_meters: 400');
    expect(_parse(noWarmUp, '0400_001').validate(), isEmpty);
    expect(_parse(noWarmUp, '0400_001').toRow()['warm_up_text_en'], '');

    final partial = _valid.replaceFirst(
      '    200 suau\n',
      '    200 suau\n    200 extra\n',
    );
    expect(
      _parse(partial).validate(),
      contains(startsWith('warm_up has a different number of lines')),
    );
  });

  test('rows from Supabase are tidied', () {
    final row = _parse(_valid).toRow()
      ..['number_train_by_meters'] = '0600_1'
      ..['warm_up_text_en'] = '200 easy\n'
      ..['main_set_text_es'] = r'4x50 pies\n100 técnica';
    final w = WorkoutFile.fromRow(row);
    expect(w.number, '0600_001');
    expect(w.validate(), isEmpty);
    expect(w.matchesRow(row), isFalse);
    expect(w.matchesRow(w.toRow()), isTrue);

    final dash = WorkoutFile.fromRow({...row, 'cool_down_text_en': '-'});
    expect(dash.texts['cool_down']!['en'], '');
  });

  test('distances of 10000 m and more use five digits', () {
    final w = _parse(
      _valid.replaceFirst('distance_meters: 600', 'distance_meters: 10000'),
      '10000_001',
    );
    expect(w.validate(), isNot(contains(startsWith('the file name'))));
    expect(w.validate(), isNot(contains(startsWith('the number'))));
  });

  test('the SQL upserts by id and escapes quotes', () {
    final sql = upsertSql([_parse(_valid)]);
    expect(sql, startsWith('insert into workouts (id, number_train_by_meters'));
    expect(sql, contains("'Easy It''s'"));
    expect(sql, contains('on conflict (id) do update set'));
    expect(sql, contains('title_en = excluded.title_en'));
    expect(sql, isNot(contains('  id = excluded.id')));
  });
}
