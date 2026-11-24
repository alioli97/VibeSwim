import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../core/app_state.dart';
import '../core/workout_history.dart';
import '../core/workout_stats.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';

/// Statistics computed from the on-device history: weekly chart, totals,
/// this month vs last month and the weekly-goal streak.
class ProgressScreen extends StatelessWidget {
  final AppState appState;

  const ProgressScreen({super.key, required this.appState});

  WorkoutHistory get _history => appState.history;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _history,
      builder: (context, _) {
        final entries = _history.entries;
        final stats = WorkoutStats.compute(
          entries,
          weeklyGoal: _history.weeklyGoalMeters,
        );
        return Scaffold(
          backgroundColor: AppTheme.background,
          body: CustomScrollView(
            slivers: [
              _buildAppBar(context),
              if (entries.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmpty(context),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                  sliver: SliverList.list(
                    children: [
                      _WeeklyChart(appState: appState, stats: stats),
                      const SizedBox(height: 24),
                      _buildStreak(context, stats),
                      const SizedBox(height: 24),
                      _buildTotals(context, stats),
                      const SizedBox(height: 24),
                      _buildMonths(context, stats),
                    ],
                  ),
                ),
            ],
          ),
          bottomNavigationBar: AppBottomNav(appState: appState, current: AppTab.progress),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.white.withValues(alpha: 0.9),
      pinned: true,
      elevation: 0,
      centerTitle: false,
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryContainer],
        ).createShader(bounds),
        child: Text(
          appState.tYourProgress,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.insights, size: 64, color: AppTheme.secondary),
          const SizedBox(height: 16),
          Text(
            appState.tNoStatsYet,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.secondary),
          ),
        ],
      ),
    );
  }

  Widget _buildStreak(BuildContext context, WorkoutStats stats) {
    return _Section(
      icon: Icons.local_fire_department,
      title: appState.tStreak,
      subtitle: appState.tStreakHint,
      child: Row(
        children: [
          Expanded(
            child: _StatTile(
              label: appState.tCurrentStreak,
              value: appState.tWeeks(stats.currentStreak),
              highlight: stats.currentStreak > 0,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatTile(
              label: appState.tBestStreak,
              value: appState.tWeeks(stats.bestStreak),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotals(BuildContext context, WorkoutStats stats) {
    final longest = stats.longest;
    final longestTitle =
        longest == null ? '' : appState.localizedDbField(longest.workout, 'title');
    return _Section(
      icon: Icons.analytics_outlined,
      title: appState.tTotals,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: appState.tTotalDistance,
                  value: appState.formatMeters(stats.total.meters),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  label: appState.tTotalTime,
                  value: appState.formatMinutes(stats.total.minutes),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: appState.tWorkoutsDone,
                  value: '${stats.total.workouts}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  label: appState.tAvgPerWorkout,
                  value: appState.formatMeters(stats.averageMeters),
                ),
              ),
            ],
          ),
          if (longest != null) ...[
            const SizedBox(height: 12),
            _StatTile(
              label: appState.tLongestWorkout,
              value: appState.formatMeters(longest.distanceMeters),
              detail: [
                if (longestTitle.isNotEmpty) longestTitle,
                DateFormat.yMMMd(appState.currentLanguage).format(longest.completedAt),
              ].join(' · '),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMonths(BuildContext context, WorkoutStats stats) {
    Widget column(String label, PeriodStats p, {bool highlight = false}) => _StatTile(
          label: label,
          value: appState.formatMeters(p.meters),
          detail: '${p.workouts} ${appState.tWorkoutsDone.toLowerCase()} · '
              '${appState.formatMinutes(p.minutes)}',
          highlight: highlight,
        );

    return _Section(
      icon: Icons.calendar_month,
      title: appState.tMonthComparison,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: column(appState.tThisMonth, stats.thisMonth, highlight: true)),
          const SizedBox(width: 12),
          Expanded(child: column(appState.tLastMonth, stats.lastMonth)),
        ],
      ),
    );
  }
}

/// Bars for the meters of each of the last weeks, with the weekly goal as a
/// line. Weeks that met the goal are dark; the current week is outlined.
class _WeeklyChart extends StatelessWidget {
  final AppState appState;
  final WorkoutStats stats;

  const _WeeklyChart({required this.appState, required this.stats});

  static const double _chartHeight = 140;

  @override
  Widget build(BuildContext context) {
    final goal = appState.history.weeklyGoalMeters;
    final weeks = stats.lastWeeks;
    final maxValue = weeks.fold(goal, (m, w) => w.meters > m ? w.meters : m).toDouble();
    final goalY = _chartHeight * goal / maxValue;
    final dateFormat = DateFormat.Md(appState.currentLanguage);
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppTheme.secondary,
          fontSize: 10,
        );

    return _Section(
      icon: Icons.bar_chart,
      title: appState.tLastWeeks,
      subtitle: '${appState.tGoalLine}: ${appState.formatMeters(goal)}',
      child: SizedBox(
        height: _chartHeight + 24,
        child: Stack(
          children: [
            // Goal line.
            Positioned(
              left: 0,
              right: 0,
              bottom: 24 + goalY,
              child: Container(height: 2, color: AppTheme.primary.withValues(alpha: 0.35)),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < weeks.length; i++)
                  Expanded(
                    child: Tooltip(
                      message: '${dateFormat.format(weeks[i].start)}: '
                          '${appState.formatMeters(weeks[i].meters)}',
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: (_chartHeight * weeks[i].meters / maxValue)
                                .clamp(weeks[i].meters > 0 ? 4.0 : 0.0, _chartHeight),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: weeks[i].meters >= goal
                                  ? AppTheme.primary
                                  : AppTheme.primaryContainer.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(6),
                              border: i == weeks.length - 1
                                  ? Border.all(color: AppTheme.primary, width: 2)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 18,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(dateFormat.format(weeks[i].start), style: labelStyle),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// White card with an icon + title header.
class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  const _Section({required this.icon, required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.secondary),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// Label + big value (+ optional small detail line).
class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? detail;
  final bool highlight;

  const _StatTile({
    required this.label,
    required this.value,
    this.detail,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? AppTheme.primary.withValues(alpha: 0.06) : AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: textTheme.labelSmall?.copyWith(color: AppTheme.secondary, letterSpacing: 1.2),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: textTheme.titleLarge?.copyWith(
                color: AppTheme.primaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (detail != null) ...[
            const SizedBox(height: 2),
            Text(
              detail!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(color: AppTheme.secondary),
            ),
          ],
        ],
      ),
    );
  }
}
