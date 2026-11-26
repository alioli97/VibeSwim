// Workout files: one YAML file per row of the Supabase `workouts` table, in `workouts/`.
// Parsing, validation, YAML output and the SQL upsert used by tool/workouts.dart.
// Plain Dart (no Flutter), so it runs with `dart run` and in `flutter test`.

import 'dart:convert';

import 'package:yaml/yaml.dart';

const languages = ['en', 'es', 'ca'];

/// Text sections, in plan order. Only the main set is required.
const sections = ['warm_up', 'main_set', 'cool_down'];

/// Allowed `difficulty` keys and their labels per language, exactly as stored in
/// `difficulty_level_<lang>` (the app filters on the English label).
const difficultyLabels = {
  'beginner': {'en': 'Beginner', 'es': 'Principiante', 'ca': 'Principiant'},
  'beginner_intermediate': {
    'en': 'Beginner / Intermediate',
    'es': 'Principiante / Intermedio',
    'ca': 'Principiant / Intermedi',
  },
  'intermediate': {'en': 'Intermediate', 'es': 'Intermedio', 'ca': 'Intermedi'},
  'intermediate_advanced': {
    'en': 'Intermediate / Advanced',
    'es': 'Intermedio / Avanzado',
    'ca': 'Intermedi / Avançat',
  },
  'advanced': {'en': 'Advanced', 'es': 'Avanzado', 'ca': 'Avançat'},
  'advanced_expert': {
    'en': 'Advanced / Expert',
    'es': 'Avanzado / Experto',
    'ca': 'Avançat / Expert',
  },
  'expert': {'en': 'Expert', 'es': 'Experto', 'ca': 'Expert'},
};

/// Columns written by [upsertSql], in this order.
final columns = [
  'id',
  'number_train_by_meters',
  'distance_meters',
  'duration_minutes',
  for (final lang in languages) 'title_$lang',
  for (final lang in languages) 'difficulty_level_$lang',
  for (final section in sections)
    for (final lang in languages) '${section}_text_$lang',
];

final _numberPattern = RegExp(r'^(\d{4})_(\d{3})$');
final _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
);

/// Meters at the start of a plan line: `300 easy` → 300, `4x50 kick` → 200.
final _amountPattern = RegExp(r'^(?:(\d+)\s*[x×]\s*)?(\d+)\b');

class WorkoutFile {
  WorkoutFile({
    required this.number,
    required this.id,
    required this.distanceMeters,
    required this.durationMinutes,
    required this.difficulty,
    required this.title,
    required this.texts,
  });

  /// `number_train_by_meters`, also the file name: `1500_004`.
  final String number;
  final String id;
  final int? distanceMeters;
  final int? durationMinutes;
  final String? difficulty;

  /// Language → text.
  final Map<String, String> title;

  /// Section → language → text (lines separated by `\n`).
  final Map<String, Map<String, String>> texts;

  /// Parses a file's YAML. Throws [FormatException] if it isn't a map of the
  /// expected shape; missing values are left empty and reported by [validate].
  factory WorkoutFile.parse(String number, String yaml) {
    final doc = loadYaml(yaml);
    if (doc is! YamlMap) {
      throw FormatException('$number: the file must be a YAML map');
    }
    Map<String, String> localized(String key) {
      final value = doc[key];
      if (value == null) return {};
      if (value is! YamlMap) {
        throw FormatException('$number: "$key" must have en/es/ca entries');
      }
      return {
        for (final entry in value.entries)
          entry.key.toString(): _clean(entry.value?.toString() ?? ''),
      };
    }

    int? integer(String key) {
      final value = doc[key];
      if (value == null || value is int) return value as int?;
      throw FormatException('$number: "$key" must be a whole number');
    }

    return WorkoutFile(
      number: number,
      id: doc['id']?.toString() ?? '',
      distanceMeters: integer('distance_meters'),
      durationMinutes: integer('duration_minutes'),
      difficulty: doc['difficulty']?.toString(),
      title: localized('title'),
      texts: {for (final section in sections) section: localized(section)},
    );
  }

  /// Builds a file from a Supabase row, cleaning the texts the same way the
  /// parser does (trimmed lines, no blank lines, a lone `-` means empty, a
  /// literal `\n` typed into the dashboard becomes a line break).
  factory WorkoutFile.fromRow(Map<String, dynamic> row) {
    final difficultyEn = row['difficulty_level_en']?.toString();
    final difficulty = difficultyLabels.entries
        .where((e) => e.value['en'] == difficultyEn)
        .map((e) => e.key)
        .firstOrNull;
    return WorkoutFile(
      number: normalizeNumber(row['number_train_by_meters']?.toString() ?? ''),
      id: row['id']?.toString() ?? '',
      distanceMeters: row['distance_meters'] as int?,
      durationMinutes: row['duration_minutes'] as int?,
      difficulty: difficulty ?? difficultyEn,
      title: {
        for (final lang in languages)
          lang: _clean(row['title_$lang']?.toString() ?? ''),
      },
      texts: {
        for (final section in sections)
          section: {
            for (final lang in languages)
              lang: _clean(
                (row['${section}_text_$lang']?.toString() ?? '').replaceAll(
                  r'\n',
                  '\n',
                ),
              ),
          },
      },
    );
  }

  /// Problems that would make the row wrong in the app; empty when it's fine.
  List<String> validate() {
    final errors = <String>[];
    final match = _numberPattern.firstMatch(number);
    if (match == null) {
      errors.add('the file name must look like 1500_004.yaml');
    } else if (distanceMeters != null &&
        int.parse(match.group(1)!) != distanceMeters) {
      errors.add(
        'the number ${match.group(1)} does not match distance_meters '
        '$distanceMeters',
      );
    }
    if (!_uuidPattern.hasMatch(id)) {
      errors.add('id must be a lowercase uuid (`new` creates one)');
    }
    if (distanceMeters == null || distanceMeters! <= 0) {
      errors.add('distance_meters is missing');
    }
    if (durationMinutes == null || durationMinutes! <= 0) {
      errors.add('duration_minutes is missing');
    }
    if (!difficultyLabels.containsKey(difficulty)) {
      errors.add(
        'difficulty must be one of: ${difficultyLabels.keys.join(', ')}',
      );
    }
    for (final lang in languages) {
      if ((title[lang] ?? '').isEmpty) errors.add('title.$lang is missing');
    }
    for (final key in [
      ...title.keys,
      for (final s in sections) ...texts[s]!.keys,
    ]) {
      if (!languages.contains(key)) {
        errors.add('unknown language "$key" (use ${languages.join('/')})');
      }
    }

    for (final section in sections) {
      final byLang = texts[section]!;
      final present = languages.where((l) => (byLang[l] ?? '').isNotEmpty);
      if (section == 'main_set' && present.isEmpty) {
        errors.add('main_set is missing');
        continue;
      }
      if (present.isEmpty) continue;
      for (final lang in languages) {
        if ((byLang[lang] ?? '').isEmpty) {
          errors.add('$section.$lang is missing');
        }
      }
      final lineCounts = {
        for (final lang in present) lang: byLang[lang]!.split('\n').length,
      };
      if (lineCounts.values.toSet().length > 1) {
        errors.add(
          '$section has a different number of lines per language: '
          '${lineCounts.entries.map((e) => '${e.key} ${e.value}').join(', ')}',
        );
      }
    }

    for (final lang in languages) {
      var total = 0;
      for (final section in sections) {
        final text = texts[section]![lang] ?? '';
        if (text.isEmpty) continue;
        for (final line in text.split('\n')) {
          final amount = _amountPattern.firstMatch(line);
          if (amount == null) {
            errors.add(
              '$section.$lang: "$line" must start with the meters '
              '(e.g. 200 or 4x50)',
            );
            continue;
          }
          total +=
              int.parse(amount.group(1) ?? '1') * int.parse(amount.group(2)!);
        }
      }
      if (distanceMeters != null && total != distanceMeters) {
        errors.add('the $lang lines add up to $total m, not $distanceMeters m');
      }
    }
    return errors;
  }

  /// The row as it goes into Supabase (empty sections are stored as '').
  Map<String, Object?> toRow() => {
    'id': id,
    'number_train_by_meters': number,
    'distance_meters': distanceMeters,
    'duration_minutes': durationMinutes,
    for (final lang in languages) 'title_$lang': title[lang] ?? '',
    for (final lang in languages)
      'difficulty_level_$lang': difficultyLabels[difficulty]?[lang] ?? '',
    for (final section in sections)
      for (final lang in languages)
        '${section}_text_$lang': texts[section]![lang] ?? '',
  };

  /// True if [row] (from Supabase) already has exactly this content.
  bool matchesRow(Map<String, dynamic> row) {
    final mine = toRow();
    return columns.every((c) => '${row[c] ?? ''}' == '${mine[c] ?? ''}');
  }

  String toYaml() {
    final out = StringBuffer()
      ..writeln('id: $id')
      ..writeln('distance_meters: ${distanceMeters ?? ''}')
      ..writeln('duration_minutes: ${durationMinutes ?? ''}')
      ..writeln('difficulty: ${difficulty ?? ''}')
      ..writeln('title:');
    for (final lang in languages) {
      out.writeln('  $lang: ${jsonEncode(title[lang] ?? '')}');
    }
    for (final section in sections) {
      final byLang = texts[section]!;
      if (languages.every((l) => (byLang[l] ?? '').isEmpty)) continue;
      out.writeln('$section:');
      for (final lang in languages) {
        final text = byLang[lang] ?? '';
        if (text.isEmpty) {
          out.writeln('  $lang: ""');
          continue;
        }
        out.writeln('  $lang: |-');
        for (final line in text.split('\n')) {
          out.writeln('    $line');
        }
      }
    }
    return out.toString();
  }
}

/// `0900_12` → `0900_012`.
String normalizeNumber(String number) {
  final parts = number.split('_');
  if (parts.length != 2) return number;
  return '${parts[0].padLeft(4, '0')}_${parts[1].padLeft(3, '0')}';
}

String _clean(String text) {
  final lines = text
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();
  if (lines.length == 1 && lines.single == '-') return '';
  return lines.join('\n');
}

String _sqlValue(Object? value) {
  if (value == null) return 'null';
  if (value is int) return '$value';
  return "'${value.toString().replaceAll("'", "''")}'";
}

/// One statement that inserts new workouts and updates existing ones (by id).
String upsertSql(Iterable<WorkoutFile> workouts) {
  final rows = workouts
      .map((w) {
        final row = w.toRow();
        return '  (${columns.map((c) => _sqlValue(row[c])).join(', ')})';
      })
      .join(',\n');
  final updates = columns
      .where((c) => c != 'id')
      .map((c) => '  $c = excluded.$c')
      .join(',\n');
  return 'insert into workouts (${columns.join(', ')})\nvalues\n$rows\n'
      'on conflict (id) do update set\n$updates;\n';
}
