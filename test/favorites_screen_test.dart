import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:swimvibe/core/app_state.dart';
import 'package:swimvibe/main.dart';
import 'package:swimvibe/screens/favorites_screen.dart';
import 'package:swimvibe/screens/workout_detail_screen.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<AppState> appStateWith(List<Map<String, dynamic>> favorites) async {
    SharedPreferences.setMockInitialValues({});
    final appState = AppState(await SharedPreferences.getInstance());
    for (final w in favorites.reversed) {
      await appState.favorites.toggle(w);
    }
    return appState;
  }

  final pyramid = {
    'id': 'p',
    'title_en': 'Pyramid',
    'distance_meters': 2000,
    'duration_minutes': 45,
    'difficulty_level_en': 'Intermediate',
  };
  final sprints = {'id': 's', 'title_en': 'Sprints', 'distance_meters': 1200};

  testWidgets('empty state', (tester) async {
    final appState = await appStateWith([]);
    await tester.pumpWidget(MaterialApp(home: FavoritesScreen(appState: appState)));

    expect(find.text('Favorites'), findsOneWidget);
    expect(find.textContaining('No favorites yet'), findsOneWidget);
  });

  testWidgets('lists favorites; removing one can be undone', (tester) async {
    final appState = await appStateWith([pyramid, sprints]);
    await tester.pumpWidget(MaterialApp(home: FavoritesScreen(appState: appState)));

    expect(find.text('Pyramid'), findsOneWidget);
    expect(find.text('2000 m · 45 min · Intermediate'), findsOneWidget);
    expect(find.text('Sprints'), findsOneWidget);

    await tester.tap(find.descendant(
        of: find.ancestor(of: find.text('Pyramid'), matching: find.byType(ListTile)),
        matching: find.byTooltip('Remove from favorites'),
      ));
    await tester.pumpAndSettle();
    expect(find.text('Pyramid'), findsNothing);
    expect(appState.favorites.isFavorite('p'), isFalse);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(appState.favorites.items.map((w) => w['id']), ['p', 's']);

    // Let the snackbar time out so no timers are left pending.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('home ⭐ opens favorites and a favorite opens without fetching', (tester) async {
    final appState = await appStateWith([pyramid]);
    await tester.pumpWidget(SwimVibeApp(appState: appState));
    await tester.pump();

    await tester.tap(find.byTooltip('Favorites'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pyramid'));
    await tester.pumpAndSettle();

    // Shown straight from the saved snapshot (the default Supabase repository
    // would throw in tests if it were used).
    expect(find.byType(WorkoutDetailScreen), findsOneWidget);
    expect(find.text('PYRAMID'), findsOneWidget);
    expect(find.byTooltip('Generate another'), findsNothing);
    expect(find.byTooltip('Remove from favorites'), findsOneWidget); // starred
  });
}
