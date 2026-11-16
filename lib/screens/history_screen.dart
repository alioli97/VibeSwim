import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../core/app_state.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  final AppState appState;
  const HistoryScreen({Key? key, required this.appState}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _futureWorkouts = Supabase.instance.client
      .from('workouts')
      .select()
      .order('created_at', ascending: false);

  @override
  Widget build(BuildContext context) {
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
                    'Workout History',
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
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _futureWorkouts,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: AppTheme.primaryContainer)),
                );
              }
              if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Text('Error loading workouts:\n${snapshot.error}'),
                  ),
                );
              }

              final workouts = snapshot.data ?? [];
              if (workouts.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No workouts yet. Go swim!',
                      style: TextStyle(color: AppTheme.secondary),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0).copyWith(bottom: 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = workouts[index];
                      final dateStr = item['created_at'] as String?;
                      final parsedDate = dateStr != null ? DateTime.tryParse(dateStr) : DateTime.now();
                      final formattedDate = parsedDate != null 
                          ? DateFormat('MMM dd, yyyy • hh:mm a').format(parsedDate)
                          : 'Unknown Date';
                      
                      // Using the localized helper based on AppState
                      final localizedTitle = widget.appState.localizedDbField(item, 'title');
                          
                      return _buildHistoryItem(
                        context: context,
                        title: localizedTitle.isNotEmpty ? localizedTitle : 'Workout',
                        date: formattedDate,
                        distance: '${item['distance_meters'] ?? 0}m',
                      );
                    },
                    childCount: workouts.length,
                  ),
                ),
              );
            },
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

  Widget _buildProgressSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.analytics_outlined, color: AppTheme.primaryContainer),
            const SizedBox(width: 8),
            Text('Progress',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
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
              )
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
                      Text('Total Distance',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.secondary, letterSpacing: 1.5)),
                      Text('12,450m',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppTheme.primaryContainer, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Avg. Pace',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.secondary, letterSpacing: 1.5)),
                      Text('1:42/100m',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.primaryContainer, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Weekly Goal',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.secondary, letterSpacing: 1.5)),
                  Text('85%',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.primary, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: 0.85,
                  minHeight: 8,
                  backgroundColor: AppTheme.surfaceContainerLow,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text('4,250m of 5,000m completed',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.secondary)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(
      {required BuildContext context,
      required String title,
      required String date,
      required String distance}) {
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
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
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
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.secondary,
                    ),
              ),
            ],
          ),
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
                'Distance',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.secondary,
                      fontSize: 9,
                    ),
              ),
            ],
          )
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
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(context, Icons.pool, 'Workouts', false),
          _buildNavItem(context, Icons.history, 'History', true),
          _buildNavItem(context, Icons.insights, 'Progress', false),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, bool isActive) {
    return GestureDetector(
      onTap: () {
        if (!isActive && label == 'Workouts') {
          Navigator.pop(context);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryContainer]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(icon, color: Colors.white),
                  const SizedBox(height: 4),
                  Text(label.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold)),
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
                          color: Colors.grey,
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            )
        ],
      ),
    );
  }
}
