# Workouts

One YAML file per row of the Supabase `workouts` table, named after `number_train_by_meters`
(`1500_004.yaml`). These files are the source of truth: edit them here, then upload with the SQL
the tool prints. The app still reads Supabase, so a new workout appears without an app update.

```bash
dart run tool/workouts.dart new 1500    # creates the next free 1500_00N.yaml with a new id
dart run tool/workouts.dart check       # validates every file (also run by `flutter test` in CI)
dart run tool/workouts.dart sql         # SQL for the files that differ from Supabase
dart run tool/workouts.dart sql 1500_004 1500_005   # SQL for those files only
dart run tool/workouts.dart pull        # overwrites the files with what Supabase has now
```

To upload: copy the SQL (also saved in `build/workouts.sql`), open Supabase → **SQL Editor** →
**New query**, paste and **Run**. It inserts new workouts and updates existing ones by `id`
("Success. No rows returned" is the expected answer). Then `sql` again should say nothing is left.

`pull` is for changes made directly in the dashboard; it overwrites local edits not uploaded yet.

## Format

```yaml
id: 3f0c…                 # uuid, never change it (`new` creates it)
distance_meters: 1500     # must match the file name and the sum of the lines
duration_minutes: 35
difficulty: intermediate  # beginner, beginner_intermediate, intermediate,
                          # intermediate_advanced, advanced, advanced_expert, expert
title:
  en: "Freestyle Pyramid"
  es: "Pirámide de crol"
  ca: "Piràmide de crol"
warm_up:                  # optional, like cool_down
  en: |-
    300 easy
    4x50 drills resting 15sec
  es: |-
    …
main_set:
  …
cool_down:
  …
```

Rules checked by `check`:

- `en`, `es` and `ca` for the title and every section present, with the same number of lines.
- Every line starts with its meters (`200 …` or `4x50 …`), and each language adds up to
  `distance_meters`.
- One line per app row: the app shows each line as a row, with the meters in a column.
