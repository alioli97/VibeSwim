import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

/// Hands a backup file to the user (share sheet on phones, download on web).
typedef ExportBackupFn = Future<void> Function(String json, String fileName);

/// Lets the user choose a backup file; returns its text, or null if cancelled.
typedef PickBackupFn = Future<String?> Function();

/// `swimvibe-backup-2026-11-17.json`
String backupFileName(DateTime date) =>
    'swimvibe-backup-${date.year}-${_two(date.month)}-${_two(date.day)}.json';

String _two(int n) => n.toString().padLeft(2, '0');

Future<void> shareBackupFile(String json, String fileName) async {
  final file = XFile.fromData(
    Uint8List.fromList(utf8.encode(json)),
    mimeType: 'application/json',
    name: fileName,
  );
  await SharePlus.instance.share(
    ShareParams(files: [file], fileNameOverrides: [fileName], subject: fileName),
  );
}

Future<String?> pickBackupFile() async {
  final file = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: const ['json'],
  );
  return file?.xFile.readAsString();
}
