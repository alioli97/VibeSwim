import 'package:material_ui/material_ui.dart';
import '../theme/app_theme.dart';
import '../core/app_state.dart';
import '../core/workout_picker.dart';
import '../core/workout_repository.dart';
import '../core/workout_share.dart';
import '../widgets/language_sheet.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final AppState appState;
  final SearchMode mode;

  /// Target meters when [mode] is distance, available minutes when it is time.
  final int value;

  /// Source of workouts; Supabase unless a test passes a fake.
  final WorkoutRepository repository;

  /// Opens the share sheet; tests pass a fake.
  final ShareTextFn share;

  /// Only workouts of this difficulty are considered.
  final DifficultyFilter difficulty;

  /// Shows exactly this workout (e.g. a favorite) instead of fetching and
  /// picking one; "Generate another" is hidden then.
  final Map<String, dynamic>? workout;

  const WorkoutDetailScreen({
    super.key,
    required this.appState,
    required this.mode,
    required this.value,
    this.repository = const SupabaseWorkoutRepository(),
    this.share = shareWithSystem,
    this.difficulty = DifficultyFilter.any,
    this.workout,
  });

  /// Opens a specific workout, e.g. from the favorites list.
  WorkoutDetailScreen.fixed({
    Key? key,
    required AppState appState,
    required Map<String, dynamic> workout,
  }) : this(
          key: key,
          appState: appState,
          mode: SearchMode.distance,
          value: (workout['distance_meters'] as num?)?.toInt() ?? 0,
          workout: workout,
        );

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  late Future<Map<String, dynamic>?> _futureWorkout;

  /// The workout on screen once loaded (used by "Finish & Log").
  Map<String, dynamic>? _workout;
  bool _logged = false;

  /// Rows fetched once, reused by "Generate another".
  List<Map<String, dynamic>> _rows = const [];

  /// Ids already shown on this screen, so "Generate another" doesn't repeat.
  final Set<Object?> _seen = {};

  /// Ids logged in the last 14 days: avoided while there are alternatives.
  Set<Object?> _recent = const {};

  /// True when workouts fit the distance/time but none has the difficulty.
  bool _onlyDifficultyMissing = false;

  @override
  void initState() {
    super.initState();
    _futureWorkout = _loadWorkout();
  }

  /// Fetches candidate workouts and picks one by distance or by time
  /// (see `lib/core/workout_picker.dart`).
  Future<Map<String, dynamic>?> _loadWorkout() async {
    final fixed = widget.workout;
    if (fixed != null) {
      _rows = [fixed];
      _workout = fixed;
      return fixed;
    }
    final rows = await widget.repository.fetchWorkouts(
      maxMinutes: widget.mode == SearchMode.time ? widget.value : null,
    );
    _rows = rows.where((w) => matchesDifficulty(w, widget.difficulty)).toList();
    _recent = widget.appState.history.recentWorkoutIds();
    final workout = _pick();
    _onlyDifficultyMissing = workout == null && _pickFrom(rows, const {}) != null;
    if (workout != null) _seen.add(workout['id']);
    if (mounted) setState(() => _workout = workout);
    return workout;
  }

  /// Closest workout to the target that isn't in [exclude], preferring
  /// ones not done recently: those are only picked when nothing else fits.
  Map<String, dynamic>? _pick({Set<Object?> exclude = const {}}) =>
      _pickExcluding({...exclude, ..._recent}) ?? _pickExcluding(exclude);

  Map<String, dynamic>? _pickExcluding(Set<Object?> exclude) => _pickFrom(_rows, exclude);

  Map<String, dynamic>? _pickFrom(List<Map<String, dynamic>> rows, Set<Object?> exclude) =>
      switch (widget.mode) {
        SearchMode.distance =>
          pickByDistance(rows, targetDistance: widget.value, exclude: exclude),
        SearchMode.time =>
          pickByTime(rows, availableMinutes: widget.value, exclude: exclude),
      };

  /// Shows a workout not seen yet on this screen: others with the same
  /// distance/time first, then the next closest. Once all have been shown,
  /// starts over (never repeating the current one).
  void _generateAnother() {
    final current = _workout;
    if (current == null) return;
    var next = _pick(exclude: _seen);
    if (next == null) {
      _seen
        ..clear()
        ..add(current['id']);
      next = _pick(exclude: _seen);
    }
    if (next == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(widget.appState.tNoOtherWorkout)));
      return;
    }
    _seen.add(next['id']);
    setState(() {
      _workout = next;
      _logged = false;
    });
  }

  Future<void> _finishAndLog() async {
    final workout = _workout;
    if (workout == null || _logged) return;
    setState(() => _logged = true);
    await widget.appState.history.add(workout);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.appState.tSavedToHistory)),
    );
  }

  Future<void> _share() async {
    final workout = _workout;
    if (workout == null) return;
    final appState = widget.appState;
    final title = appState.localizedDbField(workout, 'title');
    try {
      await widget.share(
        workoutShareText(appState, workout),
        title.isNotEmpty ? title : appState.tWorkout,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appState.tShareFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pushed routes aren't rebuilt by SwimVibeApp, so listen for language changes here.
    return ListenableBuilder(
      // Language changes and the ⭐ state.
      listenable: Listenable.merge([widget.appState, widget.appState.favorites]),
      builder: (context, _) => _buildScreen(context),
    );
  }

  Widget _buildScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          FutureBuilder<Map<String, dynamic>?>(
            future: _futureWorkout,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryContainer),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    widget.appState.tError(snapshot.error!),
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }
              // _workout, not snapshot.data: "Generate another" replaces it.
              final workout = _workout;
              if (workout == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off, size: 64, color: AppTheme.secondary),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _onlyDifficultyMissing
                              ? widget.appState.tNoWorkoutsForDifficulty(
                                  widget.appState.difficultyName(widget.difficulty).toLowerCase())
                              : widget.mode == SearchMode.time
                                  ? widget.appState.tNoWorkoutFits(widget.value)
                                  : widget.appState.tNoWorkouts,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppTheme.primary,
                              ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(widget.appState.tGoBack),
                      )
                    ],
                  ),
                );
              }

              return CustomScrollView(
                // New workout → new scroll view, back at the top.
                key: ObjectKey(workout),
                slivers: [
                  _buildAppBar(context),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeroCard(context, workout),
                          _buildStatsOverview(context, workout),
                          _buildThePlanSet(context, workout),
                          const SizedBox(height: 120), // fab padding
                        ],
                      ),
                    ),
                  )
                ],
              );
            },
          ),
          _buildFloatingActions(context),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.white.withValues(alpha: 0.8),
      pinned: true,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppTheme.primaryContainer),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryContainer],
        ).createShader(bounds),
        child: Text(
          'SwimVibe',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
        ),
      ),
      actions: [
        _buildFavoriteButton(),
        IconButton(
          icon: const Icon(Icons.settings, color: AppTheme.primaryContainer),
          tooltip: widget.appState.tLanguage,
          onPressed: () => showLanguageSheet(context, widget.appState),
        )
      ],
    );
  }

  Widget _buildFavoriteButton() {
    final workout = _workout;
    final favorites = widget.appState.favorites;
    final starred = workout != null && favorites.isFavorite(workout['id']);
    return IconButton(
      icon: Icon(starred ? Icons.star : Icons.star_border, color: AppTheme.primaryContainer),
      tooltip: starred ? widget.appState.tRemoveFavorite : widget.appState.tAddFavorite,
      onPressed: workout == null
          ? null
          : () async {
              final nowStarred = await favorites.toggle(workout);
              if (!mounted) return;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text(nowStarred
                      ? widget.appState.tAddedToFavorites
                      : widget.appState.tRemovedFromFavorites),
                ));
            },
    );
  }

  Widget _buildHeroCard(BuildContext context, Map<String, dynamic> workout) {
    final title = widget.appState.localizedDbField(workout, 'title').toUpperCase();
    final distance = workout['distance_meters'] ??
        (widget.mode == SearchMode.distance ? widget.value : 0);
    final duration = workout['duration_minutes'] ?? 45;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.only(top: 16, bottom: 24),
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryContainer.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.isNotEmpty ? title : widget.appState.tWorkoutTarget,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Flexible + scaleDown: the big distance shrinks on narrow phones
              // instead of overflowing.
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${distance}m',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    Text(
                      widget.appState.tSwimSession,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(Icons.schedule, color: Colors.white, size: 32),
                  const SizedBox(height: 4),
                  Text(
                    '$duration min',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatsOverview(BuildContext context, Map<String, dynamic> workout) {
    final difficulty = widget.appState.localizedDbField(workout, 'difficulty_level');

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD0E7EA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.waves, color: AppTheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.appState.tIntensity,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.secondary, letterSpacing: 1.5)),
                      Text(difficulty.isNotEmpty ? difficulty : widget.appState.tModerate,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThePlanSet(BuildContext context, Map<String, dynamic> workout) {
    final t = widget.appState;
    final blocks = [
      (t.tWarmUp, t.tWarmUpHint, t.localizedDbField(workout, 'warm_up_text')),
      (t.tMainSet, t.tMainSetHint, t.localizedDbField(workout, 'main_set_text')),
      (t.tCoolDown, t.tCoolDownHint, t.localizedDbField(workout, 'cool_down_text')),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment, color: AppTheme.primary, size: 28),
              const SizedBox(width: 8),
              Text(t.tThePlan,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900, color: AppTheme.onBackground)),
            ],
          ),
          const SizedBox(height: 24),
          for (final (title, hint, text) in blocks)
            if (text.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildPlanBlock(context, title, hint, text),
              ),
        ],
      ),
    );
  }

  /// One section of the plan: title and hint, then one row per line of [text].
  Widget _buildPlanBlock(BuildContext context, String title, String hint, String text) {
    final lines =
        text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: const Border(left: BorderSide(color: AppTheme.primary, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: AppTheme.primary, fontWeight: FontWeight.bold)),
          Text(hint,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.secondary)),
          const SizedBox(height: 8),
          for (var i = 0; i < lines.length; i++) ...[
            if (i > 0) Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
            _buildPlanLine(context, lines[i]),
          ],
        ],
      ),
    );
  }

  /// Leading amount of a plan line ("400", "2x200", "4 x 100"), shown in its own column.
  static final _amount = RegExp(r'^(\d+\s*[x×]\s*\d+|\d+)\s+(.+)$');

  Widget _buildPlanLine(BuildContext context, String line) {
    final match = _amount.firstMatch(line);
    final textStyle = Theme.of(context).textTheme.titleMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (match != null) ...[
            SizedBox(
              width: 72,
              child: Text(match.group(1)!.replaceAll(' ', ''),
                  style: textStyle?.copyWith(
                      color: AppTheme.primary, fontWeight: FontWeight.w900)),
            ),
          ],
          Expanded(
            child: Text(match?.group(2) ?? line,
                style: textStyle?.copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildSquareAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: AppTheme.primary),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildFloatingActions(BuildContext context) {
    return Positioned(
      bottom: 32,
      left: 24,
      right: 24,
      child: Row(
        children: [
          // Both disabled until a workout is shown.
          _buildSquareAction(
            icon: Icons.share,
            tooltip: widget.appState.tShare,
            onPressed: _workout == null ? null : _share,
          ),
          if (widget.workout == null) ...[
            const SizedBox(width: 12),
            _buildSquareAction(
              icon: Icons.refresh,
              tooltip: widget.appState.tGenerateAnother,
              onPressed: _workout == null ? null : _generateAnother,
            ),
          ],
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryContainer]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  disabledBackgroundColor: Colors.transparent,
                ),
                // Disabled until a workout is shown, and after it's logged once.
                onPressed: _workout == null || _logged ? null : _finishAndLog,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_logged ? Icons.done_all : Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _logged ? widget.appState.tLogged : widget.appState.tFinishAndLog,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
