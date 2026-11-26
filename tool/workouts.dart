// Manage the workout files in workouts/ (one YAML file per row of the Supabase
// `workouts` table). See workouts/README.md.
//
//   dart run tool/workouts.dart check             validate every file
//   dart run tool/workouts.dart new 1500          create workouts/1500_00N.yaml
//   dart run tool/workouts.dart sql               SQL for files that differ from Supabase
//   dart run tool/workouts.dart sql 1500_004 ...  SQL for those files
//   dart run tool/workouts.dart pull              overwrite the files with Supabase's rows
//
// Supabase is only read (with the app's public key); the SQL is pasted into the
// dashboard's SQL Editor, so no secret key is needed.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:swimvibe/core/supabase_keys.dart';

import 'src/workout_file.dart';

final _dir = Directory('workouts');
const _sqlPath = 'build/workouts.sql';

Future<void> main(List<String> args) async {
  final command = args.isEmpty ? 'help' : args.first;
  final rest = args.skip(1).toList();
  try {
    switch (command) {
      case 'check':
        exitCode = _check(_loadAll()) ? 0 : 1;
      case 'new':
        _new(rest);
      case 'sql':
        await _sql(rest);
      case 'pull':
        await _pull();
      default:
        stdout.writeln(
          'Usage: dart run tool/workouts.dart check | new <meters> | '
          'sql [<number>...] | pull',
        );
    }
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    exitCode = 1;
  }
}

File _file(String number) => File('${_dir.path}/$number.yaml');

List<WorkoutFile> _loadAll() {
  final files =
      _dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.yaml'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  return [for (final f in files) _load(f)];
}

WorkoutFile _load(File file) {
  final name = file.uri.pathSegments.last;
  return WorkoutFile.parse(
    name.substring(0, name.length - '.yaml'.length),
    file.readAsStringSync(),
  );
}

/// Prints every problem; true if there are none.
bool _check(List<WorkoutFile> workouts) {
  var ok = true;
  final ids = <String, String>{};
  for (final w in workouts) {
    final errors = w.validate();
    final other = ids[w.id];
    if (w.id.isNotEmpty && other != null) {
      errors.add('same id as $other');
    }
    ids[w.id] = w.number;
    for (final e in errors) {
      stderr.writeln('${w.number}: $e');
      ok = false;
    }
  }
  stdout.writeln(
    ok ? '${workouts.length} workouts OK' : 'Fix the problems above.',
  );
  return ok;
}

void _new(List<String> args) {
  final meters = args.isEmpty ? null : int.tryParse(args.first);
  if (meters == null || meters <= 0 || meters > 9999) {
    throw const FormatException(
      'Usage: dart run tool/workouts.dart new <meters>',
    );
  }
  final prefix = meters.toString().padLeft(4, '0');
  var n = 1;
  while (_file('${prefix}_${n.toString().padLeft(3, '0')}').existsSync()) {
    n++;
  }
  final number = '${prefix}_${n.toString().padLeft(3, '0')}';
  _file(number).writeAsStringSync('''
# Write it in one language (es, for example) and ask Claude to fill in the other two,
# or write all three. Every line starts with its meters (200 or 4x50) and they must add
# up to distance_meters. warm_up and cool_down are optional (delete them).
# difficulty: beginner, beginner_intermediate, intermediate, intermediate_advanced,
# advanced, advanced_expert or expert.
id: ${_uuid()}
distance_meters: $meters
duration_minutes:
difficulty: intermediate
title:
  en: ""
  es: ""
  ca: ""
warm_up:
  en: ""
  es: |-
    200 suave
  ca: ""
main_set:
  en: ""
  es: |-
    4x50 técnica
  ca: ""
cool_down:
  en: ""
  es: |-
    100 suave
  ca: ""
''');
  stdout.writeln('Created ${_file(number).path}');
}

Future<void> _sql(List<String> numbers) async {
  final List<WorkoutFile> chosen;
  final all = _loadAll();
  if (numbers.isEmpty) {
    final rows = {for (final r in await _fetchRows()) r['id']: r};
    chosen = [
      for (final w in all)
        if (rows[w.id] == null || !w.matchesRow(rows[w.id]!)) w,
    ];
    if (chosen.isEmpty) {
      stdout.writeln('Every file already matches Supabase: nothing to upload.');
      return;
    }
  } else {
    chosen = [
      for (final n in numbers)
        _load(File(n.endsWith('.yaml') ? n : _file(n).path)),
    ];
  }
  if (!_check(all)) {
    exitCode = 1;
    return;
  }
  final sql = upsertSql(chosen);
  File(_sqlPath)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(sql);
  stdout
    ..writeln()
    ..write(sql)
    ..writeln()
    ..writeln(
      'Workouts: ${chosen.map((w) => w.number).join(', ')}. The SQL is also '
      'in $_sqlPath: paste it into Supabase → SQL Editor → Run.',
    );
}

Future<void> _pull() async {
  final rows = await _fetchRows();
  _dir.createSync();
  final cleaned = <String>[];
  for (final row in rows) {
    final w = WorkoutFile.fromRow(row);
    _file(w.number).writeAsStringSync(w.toYaml());
    if (!w.matchesRow(row)) cleaned.add(w.number);
  }
  stdout.writeln('Wrote ${rows.length} files to ${_dir.path}/.');
  if (cleaned.isNotEmpty) {
    stdout.writeln(
      'Tidied while writing (run `sql` to upload): ${cleaned.join(', ')}',
    );
  }
}

Future<List<Map<String, dynamic>>> _fetchRows() async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(
      Uri.parse(
        '$supabaseUrl/rest/v1/workouts?select=*&order=number_train_by_meters',
      ),
    );
    request.headers
      ..set('apikey', supabaseAnonKey)
      ..set('Authorization', 'Bearer $supabaseAnonKey');
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) {
      throw FormatException('Supabase answered ${response.statusCode}: $body');
    }
    return (jsonDecode(body) as List).cast<Map<String, dynamic>>();
  } finally {
    client.close();
  }
}

/// Random (version 4) uuid.
String _uuid() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
