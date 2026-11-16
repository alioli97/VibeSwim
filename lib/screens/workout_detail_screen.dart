import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../core/app_state.dart';
import '../core/workout_picker.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final AppState appState;
  final SearchMode mode;

  /// Target meters when [mode] is distance, available minutes when it is time.
  final int value;

  const WorkoutDetailScreen({
    Key? key,
    required this.appState,
    required this.mode,
    required this.value,
  }) : super(key: key);

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  late Future<Map<String, dynamic>?> _futureWorkout;

  /// The workout on screen once loaded (used by "Finish & Log").
  Map<String, dynamic>? _workout;
  bool _logged = false;

  @override
  void initState() {
    super.initState();
    _futureWorkout = _loadWorkout();
  }

  /// Fetches candidate workouts and picks one by distance or by time
  /// (see `lib/core/workout_picker.dart`).
  Future<Map<String, dynamic>?> _loadWorkout() async {
    final query = Supabase.instance.client.from('workouts').select();
    final workout = switch (widget.mode) {
      SearchMode.distance => pickByDistance(await query, targetDistance: widget.value),
      SearchMode.time => pickByTime(
          await query.lte('duration_minutes', widget.value),
          availableMinutes: widget.value,
        ),
    };
    if (mounted) setState(() => _workout = workout);
    return workout;
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

  @override
  Widget build(BuildContext context) {
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
              final workout = snapshot.data;
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
                          widget.mode == SearchMode.time
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
      backgroundColor: Colors.white.withOpacity(0.8),
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
        IconButton(
          icon: const Icon(Icons.settings, color: AppTheme.primaryContainer),
          onPressed: () {},
        )
      ],
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
            color: AppTheme.primaryContainer.withOpacity(0.3),
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
                  color: Colors.white.withOpacity(0.8),
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${distance}m',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  Text(
                    widget.appState.tSwimSession,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                  ),
                ],
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
    final warmUpText = widget.appState.localizedDbField(workout, 'warm_up_text');
    final mainSetText = widget.appState.localizedDbField(workout, 'main_set_text');
    final coolDownText = widget.appState.localizedDbField(workout, 'cool_down_text');

    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment, color: AppTheme.primary, size: 28),
              const SizedBox(width: 8),
              Text(widget.appState.tThePlan,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900, color: AppTheme.onBackground)),
            ],
          ),
          const SizedBox(height: 24),
          if (warmUpText.isNotEmpty) ...[
            _buildPlanBlock(
              context,
              widget.appState.tWarmUp,
              widget.appState.tWarmUpHint,
              '', // Could parse from string if wanted
              const Color(0xFFD0E7EA),
              AppTheme.secondary,
              [
                _buildSetRow(context, '•', warmUpText,
                    '', Colors.white, AppTheme.primary)
              ]
            ),
            const SizedBox(height: 16),
          ],
          
          if (mainSetText.isNotEmpty) ...[
            _buildPlanBlock(
                context,
                widget.appState.tMainSet,
                widget.appState.tMainSetHint,
                '',
                AppTheme.primaryContainer,
                Colors.white,
                [
                  _buildSetRow(context, '•', mainSetText,
                      widget.appState.tPushYourPace, AppTheme.primaryContainer, Colors.white,
                      highlight: true),
                ],
                hasLeftBorder: true),
            const SizedBox(height: 16),
          ],
          
          if (coolDownText.isNotEmpty) ...[
            _buildPlanBlock(
              context,
              widget.appState.tCoolDown,
              widget.appState.tCoolDownHint,
              '',
              const Color(0xFFD0E7EA),
              AppTheme.secondary,
              [
                _buildSetRow(context, '•', coolDownText,
                    widget.appState.tVeryRelaxed, Colors.white, AppTheme.primary)
              ]
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanBlock(BuildContext context, String title, String subtitle, String length,
      Color badgeBgColor, Color badgeTextColor, List<Widget> items,
      {bool hasLeftBorder = false}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: hasLeftBorder
            ? const Border(left: BorderSide(color: AppTheme.primary, width: 4))
            : Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppTheme.secondary)),
                ],
              ),
              if (length.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    length,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: badgeTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                )
            ],
          ),
          const SizedBox(height: 16),
          ...items,
        ],
      ),
    );
  }

  Widget _buildSetRow(BuildContext context, String reps, String title, String subtitle,
      Color iconBg, Color iconColor,
      {bool highlight = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? AppTheme.surfaceContainerLow.withOpacity(0.5) : AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        // Allow text to wrap if it's too long
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(reps,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: iconColor, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                if (subtitle.isNotEmpty)
                  Text(subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.secondary)),
              ],
            ),
          )
        ],
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
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.share, color: AppTheme.primary),
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryContainer]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
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
                    Text(
                      _logged ? widget.appState.tLogged : widget.appState.tFinishAndLog,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
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
