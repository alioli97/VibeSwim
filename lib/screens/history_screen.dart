import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../core/app_state.dart';
import '../core/workout_history.dart';
import '../widgets/number_dialog.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  final AppState appState;
  const HistoryScreen({Key? key, required this.appState}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  WorkoutHistory get _history => widget.appState.history;

  /// Meters with the language's thousands separator (12,450 / 12.450).
  String _meters(int meters) =>
      '${NumberFormat.decimalPattern(widget.appState.currentLanguage).format(meters)}m';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _history,
      builder: (context, _) => _buildScreen(context),
    );
  }

  Widget _buildScreen(BuildContext context) {
    final entries = _history.entries;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildProgressSection(context),
                  const SizedBox(height: 32),
                  Text(
                    widget.appState.tWorkoutHistory,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          if (entries.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  widget.appState.tNoWorkoutsYet,
                  style: const TextStyle(color: AppTheme.secondary),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
              ).copyWith(bottom: 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final entry = entries[index];
                  final lang = widget.appState.currentLanguage;
                  final date = entry.completedAt;
                  final title = widget.appState.localizedDbField(
                    entry.workout,
                    'title',
                  );

                  // Swipe left (or tap the bin) to delete; the snackbar can undo it.
                  return Dismissible(
                    key: ObjectKey(entry),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => _delete(entry),
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      alignment: Alignment.centerRight,
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                      ),
                    ),
                    child: _buildHistoryItem(
                      context: context,
                      title: title.isNotEmpty
                          ? title
                          : widget.appState.tWorkout,
                      date:
                          '${DateFormat.yMMMd(lang).format(date)} • ${DateFormat.jm(lang).format(date)}',
                      distance: _meters(entry.distanceMeters),
                      onDelete: () => _delete(entry),
                    ),
                  );
                }, childCount: entries.length),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.white.withOpacity(0.9),
      pinned: true,
      elevation: 0,
      centerTitle: false,
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryContainer],
        ).createShader(bounds),
        child: Text(
          widget.appState.tHistoryProgress,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Future<void> _delete(LoggedWorkout entry) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!await _history.remove(entry)) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(widget.appState.tWorkoutDeleted),
          action: SnackBarAction(
            label: widget.appState.tUndo,
            onPressed: () => _history.restore(entry),
          ),
        ),
      );
  }

  Future<void> _editWeeklyGoal() async {
    final meters = await showNumberDialog(
      context,
      appState: widget.appState,
      title: widget.appState.tWeeklyGoal,
      hint: '${WorkoutHistory.defaultWeeklyGoalMeters}',
      suffix: 'm',
      initialValue: _history.weeklyGoalMeters,
    );
    if (meters != null) await _history.setWeeklyGoal(meters);
  }

  Widget _buildProgressSection(BuildContext context) {
    final weekMeters = _history.distanceThisWeek();
    final goal = _history.weeklyGoalMeters;
    final weekProgress = (weekMeters / goal).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.analytics_outlined,
              color: AppTheme.primaryContainer,
            ),
            const SizedBox(width: 8),
            Text(
              widget.appState.tProgress,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.04),
                blurRadius: 24,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.appState.tTotalDistance,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.secondary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        _meters(_history.totalDistance),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppTheme.primaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.appState.tWorkoutsDone,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.secondary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        '${_history.entries.length}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.primaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Tap the label (or the pencil) to change the goal.
                  InkWell(
                    onTap: _editWeeklyGoal,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Text(
                            widget.appState.tWeeklyGoal,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppTheme.secondary,
                                  letterSpacing: 1.5,
                                ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: AppTheme.secondary,
                            semanticLabel: widget.appState.tEditWeeklyGoal,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    '${(weekProgress * 100).round()}%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: weekProgress,
                  minHeight: 8,
                  backgroundColor: AppTheme.surfaceContainerLow,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  widget.appState.tCompletedOf(
                    _meters(weekMeters),
                    _meters(goal),
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppTheme.secondary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem({
    required BuildContext context,
    required String title,
    required String date,
    required String distance,
    required VoidCallback onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onBackground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppTheme.secondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                distance,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.primaryContainer,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                widget.appState.tDistance,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.secondary,
                  fontSize: 9,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.secondary),
            tooltip: widget.appState.tDelete,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 24, top: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.08),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            context,
            Icons.pool,
            widget.appState.tNavWorkouts,
            false,
            onTap: () => Navigator.pop(context),
          ),
          _buildNavItem(
            context,
            Icons.history,
            widget.appState.tNavHistory,
            true,
          ),
          _buildNavItem(
            context,
            Icons.insights,
            widget.appState.tNavProgress,
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    bool isActive, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryContainer],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(icon, color: Colors.white),
                  const SizedBox(height: 4),
                  Text(
                    label.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  Icon(icon, color: Colors.grey),
                  const SizedBox(height: 4),
                  Text(
                    label.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.grey,
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
