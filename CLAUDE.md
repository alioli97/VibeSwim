# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

SwimVibe (Dart package `swimvibe`, Android application id and iOS bundle id `com.alioli97.swimvibe`, final: never change it): a Flutter app that generates swim workouts based on a target distance and available time. Workouts are read from a **Supabase** backend. Platforms in the repo: `android/`, `ios/` (iPhone only, built on GitHub Actions: there is no Mac), `linux/`, `web/`. Release steps (signing, TestFlight, store setup): `docs/RELEASE.md`. Flutter 3.50 (Dart 3.14). Material widgets come from `package:material_ui/material_ui.dart` (the `package:flutter/material.dart` import is deprecated since Flutter 3.47): always import that one.

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
dart run tool/workouts.dart check|new <m>|sql|pull   # workout files in workouts/ (see workouts/README.md)
```

`flutter run -d linux` needs host packages not bundled with the Flutter snap (`clang cmake ninja-build g++ pkg-config libgtk-3-dev`); use `-d chrome` or an Android device otherwise.

### Testing notes

- Tests must not touch Supabase: pump `SwimVibeApp(appState: ...)` or a screen directly (never `main()`, which calls `initSupabase()`). `WorkoutDetailScreen` defaults to `SupabaseWorkoutRepository`, so tests pass `repository:` a fake (see `test/workout_detail_screen_test.dart`) and don't navigate to it from `HomeScreen`.
- Tap buttons that write to SharedPreferences outside `tester.runAsync` (then `pumpAndSettle`): a snackbar shown from inside `runAsync` finishes its animation after the test and fails it.
- `HistoryScreen` / `ProgressScreen` tests need `initializeDateFormatting()`; write to `WorkoutHistory` inside `tester.runAsync` (SharedPreferences I/O).
- Build `AppState` from `SharedPreferences.setMockInitialValues({})`.
- Fonts: Lexend and Inter (only the weights `AppTheme` uses) are bundled in `assets/google_fonts/` and `main()` sets `GoogleFonts.config.allowRuntimeFetching = false`, so the app never downloads fonts. `test/flutter_test_config.dart` preloads them before every test file (a font finishing loading mid-test leaves a pending frame callback and fails it). If the theme starts using another weight, add its `.ttf` there (named like `Inter-SemiBold.ttf`).
- Test HTTP always returns 400: any `Image.network` must have an `errorBuilder` or the test fails (the app currently has none).
- iOS: `.github/workflows/ios.yml` builds unsigned on PRs touching `ios/`/pubspec and on `master`; "Run workflow" signs and uploads to TestFlight (secrets in docs/RELEASE.md). Claude can't set GitHub secrets or use the App Store Connect key: the user runs those.
- App Store material: listing texts, App Store Connect answers and review notes in `store/app-store/` (README there; `check.py` checks lengths); screenshots in `store/screenshots/ios/{en,es,ca}/`, rendered by `store/screenshots/screenshots_test.dart` (not in CI; real rows in `workouts.json`). The privacy policy and support page are `site/`, published by `.github/workflows/pages.yml` to https://alioli97.github.io/VibeSwim/ (keep the privacy policy in sync with what the app stores and sends).
- CI: `.github/workflows/ci.yml` runs `flutter analyze` and `flutter test` (Flutter 3.50.0; keep it in sync with the local SDK) on pushes and PRs to `master`; keep both green.

## Architecture

- `lib/main.dart` — calls `initSupabase()`, loads `SharedPreferences`, creates `AppState`, and wraps `MaterialApp` in a `ListenableBuilder` so the whole app rebuilds when `AppState` notifies. No router: navigation is `Navigator.push/pop` with `MaterialPageRoute`.
- `lib/core/supabase_keys.dart` — Supabase URL + anon key (public by design; reads depend on RLS), plain Dart so `tool/` can use it; `lib/core/supabase_config.dart` has `initSupabase()`.
- `lib/core/workout_repository.dart` — `WorkoutRepository` (`fetchWorkouts({maxMinutes})`); `SupabaseWorkoutRepository` queries the `workouts` table. Screens never call `Supabase.instance` directly.
- `lib/core/app_state.dart` — `AppState extends ChangeNotifier`, passed explicitly through constructors to every screen (no Provider/Riverpod). Holds the current language (`en` default, `es`, `ca`; persisted under `language_code` in SharedPreferences), the home difficulty filter (`difficulty`, persisted under `difficulty_filter`), `history` and `favorites`.
- `lib/core/workout_history.dart` — `WorkoutHistory` (its own `ChangeNotifier`, exposed as `appState.history`): the user's completed workouts, stored **on the device** as JSON under `workout_history` in SharedPreferences (no user accounts, nothing written to Supabase). Each `LoggedWorkout` keeps a snapshot of the full Supabase row (so titles stay translatable offline) plus `completedAt`. Entries can be removed (`remove`) and put back (`restore`, used by the undo snackbar). Backup: `exportJson()` (format `swimvibe-history`, v1, with the weekly goal) and `importJson()` (merges, skipping entries with the same workout `id` + `completedAt`; restores the goal; `FormatException` if it isn't a backup). Also computes total distance and meters this week (from Monday 00:00 local) against `weeklyGoalMeters`, which the user can change (persisted under `weekly_goal_meters`, default 5000).
- `lib/core/favorites.dart` — `Favorites` (`ChangeNotifier`, exposed as `appState.favorites`): starred workouts as Supabase row snapshots under `favorite_workouts` (newest first; `toggle`, `isFavorite`, `restore` for undo). Not included in the history backup.
- `lib/core/workout_stats.dart` — `WorkoutStats.compute(entries, weeklyGoal:, now:)`: pure stats for the Progress screen (totals, average, longest, this vs last month, last 8 weeks Monday-based, current/best weekly-goal streak; past weeks are judged against the *current* goal). `weekStart()` gives Monday 00:00 local.
- **Localization is hand-rolled**, not `intl`/ARB: UI strings are `t*` getters on `AppState`, one line each via `_tr(en, es, ca)` (methods like `tNoWorkoutFits(minutes)` for interpolated text). Never hardcode user-visible text in screens; only the brand name, the language names (native) and units (`m`, `min`) are literals. Don't branch logic on displayed labels (e.g. the bottom nav takes an `onTap` callback).
- Dates use `intl` `DateFormat` with `appState.currentLanguage` as locale; `main()` calls `initializeDateFormatting()` first.
- **DB content localization**: `AppState.localizedDbField(row, prefix)` reads column `<prefix>_<lang>` and falls back to `<prefix>_en`, then `<prefix>_es`.
- `lib/screens/`:
  - `home_screen.dart` — distance and time pickers (incl. custom-value dialogs), ⭐ opens `FavoritesScreen`, ⚙ opens the language sheet, bottom nav. A "Distance | Time" selector sets `SearchMode` (the inactive card is faded; using a card also activates its mode). Workouts are searched by distance **or** by time, never both. Difficulty chips (Any/Beginner/Intermediate/Advanced) set `appState.difficulty`. "Generate" pushes `WorkoutDetailScreen(mode, value, difficulty)`. The 2500 m default is intentional (the owner keeps adding longer workouts), so matching must not require an exact distance.
  - `workout_detail_screen.dart` — fetches `workouts` through its `repository` and picks one with the pure, unit-tested functions in `lib/core/workout_picker.dart`: `pickByDistance` (closest `distance_meters`, above or below, ties → longer) or `pickByTime` (longest `duration_minutes` that doesn't exceed the time). Random among rows sharing the chosen value. Rows are first filtered with `matchesDifficulty` (on `difficulty_level_en`: combos like "Beginner / Intermediate" match both levels, "Expert" counts as advanced), and workouts logged in the last 14 days (`history.recentWorkoutIds()`) are avoided while anything else fits. "Finish & Log" adds the shown workout to `appState.history` (once per workout shown). "Generate another" (🔄) re-picks from the rows already fetched, passing the ids shown so far as `exclude` to the picker: other workouts with the same value first, then the next closest; when all have been shown it starts over without repeating the current one. The ☆ in the app bar toggles the workout in `appState.favorites`. The share button sends the workout as plain text in the current language (`lib/core/workout_share.dart`: `workoutShareText`, sent via `share_plus`; the screen takes a `share` callback so tests pass a fake). On web, `share_plus` uses the Web Share API and falls back to a `mailto:` link.
  - `history_screen.dart` — rebuilds from `appState.history` (`ListenableBuilder`): real totals, workout count and weekly goal, plus the list of logged workouts, newest first. Swipe left or tap the bin to delete a workout (snackbar with Undo); tap "Weekly Goal" to change the goal. The ⋮ menu exports/imports a backup file via `lib/core/history_backup.dart` (`share_plus` to share/download, `file_picker` to choose); the screen takes `exportBackup`/`pickBackup` callbacks so tests pass fakes.
  - `favorites_screen.dart` — starred workouts; tap opens `WorkoutDetailScreen.fixed(workout:)` (shows that snapshot, no fetch, no "Generate another"); swipe or tap the star to remove (Undo).
  - `progress_screen.dart` — statistics from `appState.history` via `WorkoutStats`: weekly bar chart with the goal line, streak, totals and this month vs last month. Empty state when nothing is logged.
- `lib/widgets/`:
  - `number_dialog.dart` — `showNumberDialog`, the shared dialog for typing a positive whole number (custom distance/time on home, weekly goal on history).
  - `language_sheet.dart` — `showLanguageSheet`, opened by the ⚙ on home and on the workout detail screen (which wraps its build in a `ListenableBuilder` on `appState`, because pushed routes aren't rebuilt by `SwimVibeApp`).
  - `app_bottom_nav.dart` — `AppBottomNav(current: AppTab.x)`, shared by Home, History and Progress. Home stays the first route: from Home, History/Progress are pushed; between them they `pushReplacement`; "Workouts" pops to the first route.
- Number formatting: `appState.formatMeters` (locale thousands separator + `m`) and `appState.formatMinutes`.

### Supabase `workouts` table (columns used by the code)

`id` (uuid), `number_train_by_meters` (e.g. `1500_001`), `distance_meters`, `duration_minutes`, `created_at`, and localized text columns with `_en` / `_es` / `_ca` suffixes: `title_*`, `difficulty_level_*`, `warm_up_text_*`, `main_set_text_*`, `cool_down_text_*`. Rows are returned as `Map<String, dynamic>` (no model classes). Access uses the anon key, so reads depend on the table's RLS policies.

### Adding or editing workouts

`workouts/*.yaml` (one file per row, named after `number_train_by_meters`) are the source of truth for the table's content. `tool/workouts.dart` validates them (`tool/src/workout_file.dart`: all three languages, same line count per language, every line starts with its meters and they add up to `distance_meters`, known difficulty key → the three `difficulty_level_*` labels) and prints an upsert by `id` that the user pastes into the Supabase SQL Editor: the anon key can't write (RLS), and there is no service key on this machine. `test/workout_files_test.dart` checks every file in CI. When the user writes a new workout in one language, fill in the other two in the same style as the existing files (es "suave"/en "relaxed"/ca "suau", "crol"/"crawl"/"crol", "descanso 20seg"/"resting 20sec"/"descans 20seg").
