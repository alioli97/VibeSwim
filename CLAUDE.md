# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

SwimVibe (Dart package `swimvibe`, Android id `com.aalio.swimvibe`): a Flutter app that generates swim workouts based on a target distance and available time. Workouts are read from a **Supabase** backend. Platforms in the repo: `android/`, `linux/`, `web/` (no iOS folder). Dart SDK `^3.11.4`.

`home.html` and `workout_detail.html` in the repo root are static Tailwind design mockups the Flutter screens were built from (colors in `lib/theme/app_theme.dart` mirror their palette). They are not used by the app.

## Commands

```bash
flutter pub get
flutter run                     # pick device; -d linux / -d chrome / -d <android-id>
flutter analyze                 # lints: package:flutter_lints (analysis_options.yaml)
flutter test                    # all tests
flutter test test/widget_test.dart          # single file
flutter test --plain-name "<test name>"     # single test by name
flutter build apk --debug
flutter build web
dart run flutter_launcher_icons   # regenerate app icons from assets/icon/ (config in pubspec.yaml)
```

`flutter run -d linux` needs host packages not bundled with the Flutter snap (`clang cmake ninja-build g++ pkg-config libgtk-3-dev`); use `-d chrome` or an Android device otherwise.

### Testing notes

- Tests must not touch Supabase: pump `SwimVibeApp(appState: ...)` or a screen directly (never `main()`, which calls `initSupabase()`). `WorkoutDetailScreen` defaults to `SupabaseWorkoutRepository`, so tests pass `repository:` a fake (see `test/workout_detail_screen_test.dart`) and don't navigate to it from `HomeScreen`.
- `HistoryScreen` / `ProgressScreen` tests need `initializeDateFormatting()`; write to `WorkoutHistory` inside `tester.runAsync` (SharedPreferences I/O).
- Build `AppState` from `SharedPreferences.setMockInitialValues({})`.
- Test HTTP always returns 400: tests set `GoogleFonts.config.allowRuntimeFetching = false`, and any `Image.network` must have an `errorBuilder` or the test fails (the app currently has none).
- CI: `.github/workflows/ci.yml` runs `flutter analyze` and `flutter test` (Flutter 3.41.6) on pushes and PRs to `master`; keep both green.

## Architecture

- `lib/main.dart` — calls `initSupabase()`, loads `SharedPreferences`, creates `AppState`, and wraps `MaterialApp` in a `ListenableBuilder` so the whole app rebuilds when `AppState` notifies. No router: navigation is `Navigator.push/pop` with `MaterialPageRoute`.
- `lib/core/supabase_config.dart` — Supabase URL + anon key (public by design; reads depend on RLS) and `initSupabase()`.
- `lib/core/workout_repository.dart` — `WorkoutRepository` (`fetchWorkouts({maxMinutes})`); `SupabaseWorkoutRepository` queries the `workouts` table. Screens never call `Supabase.instance` directly.
- `lib/core/app_state.dart` — `AppState extends ChangeNotifier`, passed explicitly through constructors to every screen (no Provider/Riverpod). Holds the current language (`en` default, `es`, `ca`; persisted under `language_code` in SharedPreferences) and `history`.
- `lib/core/workout_history.dart` — `WorkoutHistory` (its own `ChangeNotifier`, exposed as `appState.history`): the user's completed workouts, stored **on the device** as JSON under `workout_history` in SharedPreferences (no user accounts, nothing written to Supabase). Each `LoggedWorkout` keeps a snapshot of the full Supabase row (so titles stay translatable offline) plus `completedAt`. Entries can be removed (`remove`) and put back (`restore`, used by the undo snackbar). Also computes total distance and meters this week (from Monday 00:00 local) against `weeklyGoalMeters`, which the user can change (persisted under `weekly_goal_meters`, default 5000).
- `lib/core/workout_stats.dart` — `WorkoutStats.compute(entries, weeklyGoal:, now:)`: pure stats for the Progress screen (totals, average, longest, this vs last month, last 8 weeks Monday-based, current/best weekly-goal streak; past weeks are judged against the *current* goal). `weekStart()` gives Monday 00:00 local.
- **Localization is hand-rolled**, not `intl`/ARB: UI strings are `t*` getters on `AppState`, one line each via `_tr(en, es, ca)` (methods like `tNoWorkoutFits(minutes)` for interpolated text). Never hardcode user-visible text in screens; only the brand name, the language names (native) and units (`m`, `min`) are literals. Don't branch logic on displayed labels (e.g. the bottom nav takes an `onTap` callback).
- Dates use `intl` `DateFormat` with `appState.currentLanguage` as locale; `main()` calls `initializeDateFormatting()` first.
- **DB content localization**: `AppState.localizedDbField(row, prefix)` reads column `<prefix>_<lang>` and falls back to `<prefix>_en`, then `<prefix>_es`.
- `lib/screens/`:
  - `home_screen.dart` — distance and time pickers (incl. custom-value dialogs), ⚙ opens the language sheet, bottom nav. A "Distance | Time" selector sets `SearchMode` (the inactive card is faded; using a card also activates its mode). Workouts are searched by distance **or** by time, never both. "Generate" pushes `WorkoutDetailScreen(mode, value)`. The 2500 m default is intentional (the owner keeps adding longer workouts), so matching must not require an exact distance.
  - `workout_detail_screen.dart` — fetches `workouts` through its `repository` and picks one with the pure, unit-tested functions in `lib/core/workout_picker.dart`: `pickByDistance` (closest `distance_meters`, above or below, ties → longer) or `pickByTime` (longest `duration_minutes` that doesn't exceed the time). Random among rows sharing the chosen value. "Finish & Log" adds the shown workout to `appState.history` (once per workout shown). "Generate another" (🔄) re-picks from the rows already fetched, passing the ids shown so far as `exclude` to the picker: other workouts with the same value first, then the next closest; when all have been shown it starts over without repeating the current one. The share button sends the workout as plain text in the current language (`lib/core/workout_share.dart`: `workoutShareText`, sent via `share_plus`; the screen takes a `share` callback so tests pass a fake). On web, `share_plus` uses the Web Share API and falls back to a `mailto:` link.
  - `history_screen.dart` — rebuilds from `appState.history` (`ListenableBuilder`): real totals, workout count and weekly goal, plus the list of logged workouts, newest first. Swipe left or tap the bin to delete a workout (snackbar with Undo); tap "Weekly Goal" to change the goal.
  - `progress_screen.dart` — statistics from `appState.history` via `WorkoutStats`: weekly bar chart with the goal line, streak, totals and this month vs last month. Empty state when nothing is logged.
- `lib/widgets/`:
  - `number_dialog.dart` — `showNumberDialog`, the shared dialog for typing a positive whole number (custom distance/time on home, weekly goal on history).
  - `language_sheet.dart` — `showLanguageSheet`, opened by the ⚙ on home and on the workout detail screen (which wraps its build in a `ListenableBuilder` on `appState`, because pushed routes aren't rebuilt by `SwimVibeApp`).
  - `app_bottom_nav.dart` — `AppBottomNav(current: AppTab.x)`, shared by Home, History and Progress. Home stays the first route: from Home, History/Progress are pushed; between them they `pushReplacement`; "Workouts" pops to the first route.
- Number formatting: `appState.formatMeters` (locale thousands separator + `m`) and `appState.formatMinutes`.

### Supabase `workouts` table (columns used by the code)

`id` (uuid), `number_train_by_meters` (e.g. `1500_001`), `distance_meters`, `duration_minutes`, `created_at`, and localized text columns with `_en` / `_es` / `_ca` suffixes: `title_*`, `difficulty_level_*`, `warm_up_text_*`, `main_set_text_*`, `cool_down_text_*`. Rows are returned as `Map<String, dynamic>` (no model classes). Access uses the anon key, so reads depend on the table's RLS policies.
