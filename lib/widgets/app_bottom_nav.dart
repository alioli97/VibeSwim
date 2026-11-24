import 'package:material_ui/material_ui.dart';

import '../core/app_state.dart';
import '../screens/history_screen.dart';
import '../screens/progress_screen.dart';
import '../theme/app_theme.dart';

enum AppTab { workouts, history, progress }

/// Bottom navigation shared by Home, History and Progress.
///
/// Home is always the first route; History/Progress are pushed on top of it
/// (and replace each other), so "Workouts" pops back to Home.
class AppBottomNav extends StatelessWidget {
  final AppState appState;
  final AppTab current;

  const AppBottomNav({
    super.key,
    required this.appState,
    required this.current,
  });

  void _go(BuildContext context, AppTab tab) {
    if (tab == current) return;
    final navigator = Navigator.of(context);
    if (tab == AppTab.workouts) {
      navigator.popUntil((route) => route.isFirst);
      return;
    }
    final route = PageRouteBuilder<void>(
      pageBuilder: (_, _, _) => tab == AppTab.history
          ? HistoryScreen(appState: appState)
          : ProgressScreen(appState: appState),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
    if (current == AppTab.workouts) {
      navigator.push(route);
    } else {
      navigator.pushReplacement(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 24, top: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.08),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _item(context, AppTab.workouts, Icons.pool, appState.tNavWorkouts),
          _item(context, AppTab.history, Icons.history, appState.tNavHistory),
          _item(
            context,
            AppTab.progress,
            Icons.insights,
            appState.tNavProgress,
          ),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, AppTab tab, IconData icon, String label) {
    final isActive = tab == current;
    final color = isActive ? Colors.white : Colors.grey;
    // Flexible + scaleDown: long labels (e.g. "ENTRENAMENTS") shrink on
    // narrow phones instead of overflowing.
    return Flexible(
      child: GestureDetector(
        onTap: () => _go(context, tab),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: isActive
              ? BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryContainer],
                  ),
                  borderRadius: BorderRadius.circular(16),
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
