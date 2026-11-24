import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:swimvibe/theme/app_theme.dart';

/// Runs before every test file: loads the bundled fonts (assets/google_fonts/)
/// up front, so no font finishes loading in the middle of a test and leaves a
/// "fonts changed" frame callback pending after it.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  final text = AppTheme.lightTheme.textTheme;
  await GoogleFonts.pendingFonts([
    text.displayLarge,
    text.displaySmall,
    text.titleLarge,
    text.bodyMedium,
  ]);
  await testMain();
}
