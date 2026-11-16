import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/favorites.dart';
import '../theme/app_theme.dart';
import 'workout_detail_screen.dart';

/// Starred workouts. Tap one to open it; swipe or tap the star to remove it.
class FavoritesScreen extends StatelessWidget {
  final AppState appState;

  const FavoritesScreen({super.key, required this.appState});

  Favorites get _favorites => appState.favorites;

  Future<void> _remove(BuildContext context, Map<String, dynamic> workout) async {
    final messenger = ScaffoldMessenger.of(context);
    final index = _favorites.items.indexWhere((w) => w['id'] == workout['id']);
    if (index < 0) return;
    await _favorites.toggle(workout);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(appState.tRemovedFromFavorites),
        action: SnackBarAction(
          label: appState.tUndo,
          onPressed: () => _favorites.restore(workout, index),
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _favorites,
      builder: (context, _) {
        final items = _favorites.items;
        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: Colors.white.withValues(alpha: 0.9),
            elevation: 0,
            iconTheme: const IconThemeData(color: AppTheme.primaryContainer),
            title: Text(
              appState.tFavorites,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          body: items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_border, size: 64, color: AppTheme.secondary),
                        const SizedBox(height: 16),
                        Text(
                          appState.tNoFavoritesYet,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: AppTheme.secondary),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final workout = items[index];
                    return Dismissible(
                      key: ValueKey(workout['id']),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => _remove(context, workout),
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        alignment: Alignment.centerRight,
                        decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.delete_outline, color: Colors.white),
                      ),
                      child: _buildItem(context, workout),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildItem(BuildContext context, Map<String, dynamic> workout) {
    final title = appState.localizedDbField(workout, 'title');
    final difficulty = appState.localizedDbField(workout, 'difficulty_level');
    final details = [
      if (workout['distance_meters'] != null) '${workout['distance_meters']} m',
      if (workout['duration_minutes'] != null) '${workout['duration_minutes']} min',
      if (difficulty.isNotEmpty) difficulty,
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title.isNotEmpty ? title : appState.tWorkout,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.onBackground,
              ),
        ),
        subtitle: Text(
          details,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.secondary),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.star, color: AppTheme.primaryContainer),
          tooltip: appState.tRemoveFavorite,
          onPressed: () => _remove(context, workout),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorkoutDetailScreen.fixed(appState: appState, workout: workout),
          ),
        ),
      ),
    );
  }
}
