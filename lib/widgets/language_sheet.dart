import 'package:material_ui/material_ui.dart';

import '../core/app_state.dart';
import '../theme/app_theme.dart';

/// Bottom sheet to pick the app language (opened from the ⚙ buttons).
/// Language names are shown in their own language.
Future<void> showLanguageSheet(BuildContext context, AppState appState) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      Widget option(String code, String name, String emoji) {
        final isSelected = appState.currentLanguage == code;
        return GestureDetector(
          onTap: () {
            appState.setLanguage(code);
            Navigator.pop(context);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primary.withValues(alpha: 0.05)
                  : AppTheme.surfaceContainerLow,
              border: Border.all(
                color: isSelected ? AppTheme.primary : Colors.transparent,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: isSelected ? AppTheme.primary : AppTheme.onBackground,
                          )),
                ),
                if (isSelected) const Icon(Icons.check_circle, color: AppTheme.primary),
              ],
            ),
          ),
        );
      }

      return Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        padding: const EdgeInsets.only(top: 16, bottom: 48, left: 32, right: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(appState.tLanguage,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.primary, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.secondary),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 16),
            option('es', 'Español', '🇪🇸'),
            option('en', 'English', '🇬🇧'),
            option('ca', 'Català', '🇦🇩'),
          ],
        ),
      );
    },
  );
}
