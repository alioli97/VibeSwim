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
flutter build apk
```

`test/widget_test.dart` is the unmodified template counter test: it references `MyApp` (the app class is `SwimVibeApp`, which needs an `AppState`) and does not compile — it must be rewritten before `flutter test` passes.

## Architecture

- `lib/main.dart` — initializes Supabase (URL + anon key hardcoded here), loads `SharedPreferences`, creates `AppState`, and wraps `MaterialApp` in a `ListenableBuilder` so the whole app rebuilds when `AppState` notifies. No router: navigation is `Navigator.push/pop` with `MaterialPageRoute`.
- `lib/core/app_state.dart` — `AppState extends ChangeNotifier`, passed explicitly through constructors to every screen (no Provider/Riverpod). Holds the current language (`en` default, `es`, `ca`; persisted under `language_code` in SharedPreferences).
- **Localization is hand-rolled**, not `intl`/ARB: UI strings are `t*` getters on `AppState` with a `switch` per language. Add new UI text there, in all three languages.
- **DB content localization**: `AppState.localizedDbField(row, prefix)` reads column `<prefix>_<lang>` and falls back to `<prefix>_en`, then `<prefix>_es`.
- `lib/screens/`:
  - `home_screen.dart` — distance and time pickers (incl. custom-value dialogs), language selector, bottom nav. "Generate" pushes `WorkoutDetailScreen` with `targetDistance` only — the selected time is not currently used in the query.
  - `workout_detail_screen.dart` — queries `workouts` with `.eq('distance_meters', targetDistance).limit(1).maybeSingle()` (exact match, always the first row, not random); `share_plus` for sharing.
  - `history_screen.dart` — lists all rows of `workouts` ordered by `created_at` desc (it is the workout catalog, not a per-user history).

### Supabase `workouts` table (columns used by the code)

`distance_meters`, `duration_minutes`, `created_at`, and localized text columns with `_en` / `_es` / `_ca` suffixes: `title_*`, `difficulty_level_*`, `warm_up_text_*`, `main_set_text_*`, `cool_down_text_*`. Rows are returned as `Map<String, dynamic>` (no model classes). Access uses the anon key, so reads depend on the table's RLS policies.
