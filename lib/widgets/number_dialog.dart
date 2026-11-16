import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../theme/app_theme.dart';

/// Dialog to type a positive whole number (custom distance, time, weekly
/// goal...). Returns null if cancelled or the input is invalid.
Future<int?> showNumberDialog(
  BuildContext context, {
  required AppState appState,
  required String title,
  required String hint,
  required String suffix,
  int? initialValue,
}) {
  final controller = TextEditingController(text: initialValue?.toString() ?? '');
  // Not disposing `controller`: the dialog still uses it during its closing
  // animation after showDialog returns.
  return showDialog<int>(
    context: context,
    builder: (context) {
      void save() {
        final parsed = int.tryParse(controller.text.trim());
        Navigator.pop(context, parsed != null && parsed > 0 ? parsed : null);
      }

      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(color: AppTheme.primary)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          onSubmitted: (_) => save(),
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffix,
            border: const OutlineInputBorder(),
            focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: AppTheme.primaryContainer, width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(appState.tCancel, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryContainer,
              foregroundColor: Colors.white,
            ),
            onPressed: save,
            child: Text(appState.tSave),
          ),
        ],
      );
    },
  );
}
