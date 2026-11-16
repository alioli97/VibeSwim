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
```

`flutter run -d linux` needs host packages not bundled with the Flutter snap (`clang cmake ninja-build g++ pkg-config libgtk-3-dev`); use `-d chrome` or an Android device otherwise.

### Testing notes

- Tests must not touch Supabase: `WorkoutDetailScreen` and `HistoryScreen` call `Supabase.instance` on construction, so widget tests pump `SwimVibeApp(appState: ...)` / `HomeScreen` directly (never `main()`) and don't navigate to those screens.
- Build `AppState` from `SharedPreferences.setMockInitialValues({})`.
- Test HTTP always returns 400: `test/widget_test.dart` sets `GoogleFonts.config.allowRuntimeFetching = false`, and any `Image.network` must have an `errorBuilder` or the test fails.

## Architecture

- `lib/main.dart` — initializes Supabase (URL + anon key hardcoded here), loads `SharedPreferences`, creates `AppState`, and wraps `MaterialApp` in a `ListenableBuilder` so the whole app rebuilds when `AppState` notifies. No router: navigation is `Navigator.push/pop` with `MaterialPageRoute`.
- `lib/core/app_state.dart` — `AppState extends ChangeNotifier`, passed explicitly through constructors to every screen (no Provider/Riverpod). Holds the current language (`en` default, `es`, `ca`; persisted under `language_code` in SharedPreferences).
- **Localization is hand-rolled**, not `intl`/ARB: UI strings are `t*` getters on `AppState` with a `switch` per language. Add new UI text there, in all three languages.
- **DB content localization**: `AppState.localizedDbField(row, prefix)` reads column `<prefix>_<lang>` and falls back to `<prefix>_en`, then `<prefix>_es`.
- `lib/screens/`:
  - `home_screen.dart` — distance and time pickers (incl. custom-value dialogs), language selector, bottom nav. A "Distance | Time" selector sets `SearchMode` (the inactive card is faded; using a card also activates its mode). Workouts are searched by distance **or** by time, never both. "Generate" pushes `WorkoutDetailScreen(mode, value)`. The 2500 m default is intentional (the owner keeps adding longer workouts), so matching must not require an exact distance.
  - `workout_detail_screen.dart` — fetches `workouts` and picks one with the pure, unit-tested functions in `lib/core/workout_picker.dart`: `pickByDistance` (closest `distance_meters`, above or below, ties → longer) or `pickByTime` (longest `duration_minutes` that doesn't exceed the time). Random among rows sharing the chosen value. `share_plus` for sharing.
  - `history_screen.dart` — lists all rows of `workouts` ordered by `created_at` desc (it is the workout catalog, not a per-user history).

### Supabase `workouts` table (columns used by the code)

`id` (uuid), `number_train_by_meters` (e.g. `1500_001`), `distance_meters`, `duration_minutes`, `created_at`, and localized text columns with `_en` / `_es` / `_ca` suffixes: `title_*`, `difficulty_level_*`, `warm_up_text_*`, `main_set_text_*`, `cool_down_text_*`. Rows are returned as `Map<String, dynamic>` (no model classes). Access uses the anon key, so reads depend on the table's RLS policies.
