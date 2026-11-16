import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../core/app_state.dart';
import 'workout_detail_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  final AppState appState;
  const HomeScreen({Key? key, required this.appState}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedDistance = 2500;
  int _selectedTime = 30;
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

  void _showLanguageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
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
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Language',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.primary, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.secondary),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const SizedBox(height: 16),
              _buildLangOption('es', 'Español', '🇪🇸'),
              _buildLangOption('en', 'English', '🇬🇧'),
              _buildLangOption('ca', 'Català', '🇦🇩'),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCustomDistanceDialog() async {
    final TextEditingController controller = TextEditingController();
    
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(widget.appState.tDistance, style: TextStyle(color: AppTheme.primary)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'e.g. 1800',
              suffixText: 'meters',
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryContainer, width: 2))
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryContainer,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  final parsed = int.tryParse(controller.text);
                  if (parsed != null && parsed > 0) {
                    setState(() {
                      _selectedDistance = parsed;
                    });
                    int newIndex = ((parsed - 100) / 100).floor();
                    if (newIndex >= 0 && newIndex < 100) {
                      _distancePageController.animateToPage(
                        newIndex,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  }
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            )
          ],
        );
      }
    );
  }

  Widget _buildLangOption(String code, String name, String emoji) {
    bool isSelected = widget.appState.currentLanguage == code;
    return GestureDetector(
      onTap: () {
        widget.appState.setLanguage(code);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.05) : AppTheme.surfaceContainerLow,
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
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Image.network(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuCKlCGq72IZf7upBXD3GTraHOd7Qj7kAq-fW_nzDyqWd-9SS7hnnCYh1x2nXxzjrPFBWKsikKcN87fw_E2WUGgFuXrb6WhroUtFQDhlu5T_Yos0oBj0l1SIqN1l1T2S43b7JwBS8pBM4FJen-TDeuEJx6j9_Q3kdLhOrSYVpow2bSiBEOchQG601TtTqclzdMhDGsxleZpiCDLLLY0yD_C8S8xH23BlICcRNG5ecxEz52iPZU6x0thAZ-HnHsuVaWA8cKUdlS5NCSPY',
                fit: BoxFit.cover,
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
                    _buildDistanceCard(),
                    const SizedBox(height: 24),
                    _buildTimeCard(),
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
          onPressed: _showLanguageSheet,
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

  Widget _buildDistanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.04),
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
                setState(() => _selectedDistance = (index + 1) * 100);
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
                                : Colors.grey.withOpacity(0.3),
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
            color: AppTheme.primary.withOpacity(0.04),
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
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.more_horiz, color: AppTheme.primary),
                    Text(widget.appState.tCustom,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTimeOption(int time) {
    bool isSelected = time == _selectedTime;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTime = time);
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
            Text('MINUTES',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isSelected
                        ? Colors.white.withOpacity(0.9)
                        : AppTheme.primary.withOpacity(0.7))),
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
              disabledForegroundColor: Colors.transparent.withOpacity(0.38),
              disabledBackgroundColor: Colors.transparent.withOpacity(0.12),
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
                    targetDistance: _selectedDistance,
                  ),
                ),
              );
            },
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryContainer]),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: AppTheme.primary.withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 12))
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
      child: Container(
        padding: const EdgeInsets.only(bottom: 24, top: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.08),
              blurRadius: 32,
              offset: const Offset(0, -8),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.pool, 'Workouts', true),
            _buildNavItem(Icons.history, 'History', false),
            _buildNavItem(Icons.insights, 'Progress', false),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return GestureDetector(
      onTap: () {
        if (!isActive && label == 'History') {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => HistoryScreen(appState: widget.appState),
              transitionDuration: Duration.zero,
            ),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryContainer]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(icon, color: Colors.white),
                  const SizedBox(height: 4),
                  Text(label.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
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
                  Text(label.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.grey, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                ],
              ),
            )
        ],
      ),
    );
  }
}
