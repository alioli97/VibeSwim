import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../core/app_state.dart';
import '../core/workout_picker.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/language_sheet.dart';
import '../widgets/number_dialog.dart';
import 'workout_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final AppState appState;
  const HomeScreen({super.key, required this.appState});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedDistance = 2500;
  int _selectedTime = 30;
  SearchMode _searchMode = SearchMode.distance;
  late PageController _distancePageController;

  @override
  void initState() {
    super.initState();
    int initialIndex = ((_selectedDistance - 100) / 100).floor();
    _distancePageController = PageController(
      viewportFraction: 0.2,
      initialPage: initialIndex >= 0 ? initialIndex : 0,
    );
  }

  @override
  void dispose() {
    _distancePageController.dispose();
    super.dispose();
  }

  Future<int?> _askNumber({
    required String title,
    required String hint,
    required String suffix,
    int? initialValue,
  }) =>
      showNumberDialog(
        context,
        appState: widget.appState,
        title: title,
        hint: hint,
        suffix: suffix,
        initialValue: initialValue,
      );

  /// True while the distance ruler scrolls to a typed custom distance, so
  /// the intermediate pages don't overwrite it (e.g. 1850 → 1800).
  bool _scrollingToCustomDistance = false;

  Future<void> _showCustomDistanceDialog() async {
    final distance = await _askNumber(
      title: widget.appState.tDistance,
      hint: '1800',
      suffix: 'm',
      initialValue: _selectedDistance % 100 == 0 ? null : _selectedDistance,
    );
    if (distance == null || !mounted) return;

    setState(() {
      _selectedDistance = distance;
      _searchMode = SearchMode.distance;
    });

    // Move the ruler to the closest mark without changing the typed value.
    final index = ((distance - 100) / 100).round().clamp(0, 99);
    _scrollingToCustomDistance = true;
    try {
      await _distancePageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } finally {
      _scrollingToCustomDistance = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Subtle wash of the brand blue behind the content.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  // Both opaque: lerping from a transparent blue would pass
                  // through a much stronger blue halfway.
                  colors: [
                    Color.alphaBlend(
                      AppTheme.primaryContainer.withValues(alpha: 0.05),
                      AppTheme.background,
                    ),
                    AppTheme.background,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildWelcomeSection(),
                    const SizedBox(height: 24),
                    _buildModeSelector(),
                    const SizedBox(height: 24),
                    _dimUnlessActive(SearchMode.distance, _buildDistanceCard()),
                    const SizedBox(height: 24),
                    _dimUnlessActive(SearchMode.time, _buildTimeCard()),
                    const SizedBox(height: 24),
                    _buildDifficultySelector(),
                    const SizedBox(height: 32),
                    _buildGenerateAction(context),
                  ],
                ),
              ),
            ),
          ),
          _buildBottomNavBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.water_drop, color: AppTheme.primaryContainer, size: 28),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryContainer],
              ).createShader(bounds),
              child: Text(
                'SwimVibe',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.grey),
          onPressed: () => showLanguageSheet(context, widget.appState),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.appState.tReadyForASet,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppTheme.secondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.appState.tDefineSession,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: AppTheme.primary,
                height: 1.1,
              ),
        ),
      ],
    );
  }

  /// "Distance | Time" switch: workouts are searched by one or the other.
  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _buildModeOption(SearchMode.distance, Icons.straighten, widget.appState.tDistance),
          _buildModeOption(SearchMode.time, Icons.timer_outlined, widget.appState.tTime),
        ],
      ),
    );
  }

  Widget _buildModeOption(SearchMode mode, IconData icon, String label) {
    final isActive = _searchMode == mode;
    final color = isActive ? Colors.white : AppTheme.primary;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _searchMode = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryContainer])
                : null,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  /// Chips to restrict the generated workout to a difficulty (persisted in
  /// AppState; applies to both search modes).
  Widget _buildDifficultySelector() {
    final appState = widget.appState;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appState.tDifficultyLabel,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final filter in DifficultyFilter.values)
              ChoiceChip(
                label: Text(appState.difficultyName(filter)),
                selected: appState.difficulty == filter,
                onSelected: (_) => appState.setDifficulty(filter),
                selectedColor: AppTheme.primaryContainer,
                backgroundColor: AppTheme.surfaceContainerLow,
                showCheckmark: false,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                labelStyle: TextStyle(
                  color: appState.difficulty == filter ? Colors.white : AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// Fades the card of the inactive search mode. It stays interactive:
  /// using it switches the search mode to it.
  Widget _dimUnlessActive(SearchMode mode, Widget card) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: _searchMode == mode ? 1 : 0.4,
      child: card,
    );
  }

  Widget _buildDistanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.appState.tDistance,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.primary)),
                    Text(widget.appState.tTargetMeters,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.secondary)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _showCustomDistanceDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        color: Colors.transparent,
                        child: Row(
                          children: [
                            const Icon(Icons.edit, size: 16, color: AppTheme.primaryContainer),
                            const SizedBox(width: 4),
                            Text(widget.appState.tSetCustom,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppTheme.primaryContainer,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('$_selectedDistance',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: AppTheme.primaryContainer,
                          fontWeight: FontWeight.w900)),
                  Text('m',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.primaryContainer,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 120,
            child: PageView.builder(
              controller: _distancePageController,
              onPageChanged: (index) {
                if (_scrollingToCustomDistance) return;
                setState(() {
                  _selectedDistance = (index + 1) * 100;
                  _searchMode = SearchMode.distance;
                });
              },
              scrollDirection: Axis.horizontal,
              itemCount: 100,
              itemBuilder: (context, index) {
                int dist = (index + 1) * 100;
                bool isSelected = dist == _selectedDistance;
                return GestureDetector(
                  onTap: () {
                    _distancePageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: SizedBox(
                    width: 64,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: isSelected ? 6 : (index % 2 == 0 ? 2 : 4),
                          height: isSelected ? 80 : (index % 2 == 0 ? 40 : 60),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryContainer
                                : Colors.grey.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('$dist',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: isSelected ? AppTheme.primary : Colors.grey,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTimeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.appState.tAvailableTime,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.primary)),
          Text(widget.appState.tLaneBooked,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.secondary)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.5,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _buildTimeOption(15),
              _buildTimeOption(30),
              _buildTimeOption(45),
              _buildCustomTimeOption(),
            ],
          )
        ],
      ),
    );
  }

  static const List<int> _presetTimes = [15, 30, 45];

  /// "CUSTOM" cell: opens a dialog to type the minutes. When a custom time
  /// is selected it shows that value highlighted; tapping it again edits it.
  Widget _buildCustomTimeOption() {
    final isSelected = !_presetTimes.contains(_selectedTime);
    final color = isSelected ? Colors.white : AppTheme.primary;
    return GestureDetector(
      onTap: _showCustomTimeDialog,
      child: Container(
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryContainer])
              : null,
          color: isSelected ? null : AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected)
              Text('$_selectedTime',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: color, fontWeight: FontWeight.bold))
            else
              Icon(Icons.more_horiz, color: color),
            Text(widget.appState.tCustom,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Future<void> _showCustomTimeDialog() async {
    final minutes = await _askNumber(
      title: widget.appState.tAvailableTime,
      hint: '60',
      suffix: 'min',
      initialValue: _presetTimes.contains(_selectedTime) ? null : _selectedTime,
    );
    if (minutes != null && mounted) {
      setState(() {
        _selectedTime = minutes;
        _searchMode = SearchMode.time;
      });
    }
  }

  Widget _buildTimeOption(int time) {
    bool isSelected = time == _selectedTime;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTime = time;
          _searchMode = SearchMode.time;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryContainer])
              : null,
          color: isSelected ? null : AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$time',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: isSelected ? Colors.white : AppTheme.primary,
                    fontWeight: FontWeight.bold)),
            Text(widget.appState.tMinutes,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.9)
                        : AppTheme.primary.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateAction(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              disabledForegroundColor: Colors.transparent.withValues(alpha: 0.38),
              disabledBackgroundColor: Colors.transparent.withValues(alpha: 0.12),
              shadowColor: Colors.transparent,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WorkoutDetailScreen(
                    appState: widget.appState,
                    mode: _searchMode,
                    value: _searchMode == SearchMode.distance
                        ? _selectedDistance
                        : _selectedTime,
                    difficulty: widget.appState.difficulty,
                  ),
                ),
              );
            },
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryContainer]),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: AppTheme.primary.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 12))
                ],
              ),
              child: Container(
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.appState.tGenerateWorkout,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.auto_awesome, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AppBottomNav(appState: widget.appState, current: AppTab.workouts),
    );
  }
}
