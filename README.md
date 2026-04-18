# 9Gaze

Flutter app for managing 9Gaze collations, a 3x3 image grid showing ophthalmology patient eye gazes on all 9 directions.

Offline-first, SQLite-backed via drift ORM.

---

## Prerequisites

- Flutter SDK (`sdk: ^3.11.4`)
- Dart bundled with Flutter
- VS Code/Cursor/Flutter-compatible IDE with the **Flutter** extension installed

---

## Running the App (VS Code/Cursor)

1. Open the repo folder in VS Code/Cursor.
2. Open the Command Palette (`Cmd+Shift+P`) → **Flutter: Select Device** → pick your target (emulator or physical device).
3. Press **F5** or run **Flutter: Run** from the Command Palette.

Hot reload is bound to `r` in the debug console, hot restart to `R`.

---

## Project Structure

```
lib/
├── app/
│   └── theme.dart                  # ThemeData, color constants
├── db/
│   ├── tables/
│   │   └── gazes.dart              # `gazes` table definition
│   ├── app_database.dart           # AppDatabase, schemaVersion, migrations
│   ├── app_database.g.dart         # GENERATED — do not edit
│   └── database_provider.dart      # appDatabase singleton
├── repositories/
│   └── gazes_repository.dart       # Typed CRUD over gazes table
├── screens/
│   └── home/
│       ├── home_screen.dart
│       └── widgets/
│           ├── home_top_bar.dart
│           ├── home_search_bar.dart
│           └── new_gaze_button.dart
└── main.dart
assets/
├── fonts/                          # Bundled Bricolage Grotesque TTFs
└── icons/                          # SVG icon assets
```

---

## Database — drift + SQLite

The app uses [drift](https://drift.simonbinder.eu/) as the SQLite ORM.
The database file lives in the device's `ApplicationSupportDirectory`.

### Current schema (v1)

**Table: `gazes`**

| Column | Type | Notes |
|---|---|---|
| `id` | INTEGER | Primary key, auto-increment |
| `name` | TEXT | Required |
| `created_at` | DATETIME | Defaults to `CURRENT_TIMESTAMP` |
| `updated_at` | DATETIME | Defaults to `CURRENT_TIMESTAMP`, refreshed by repo on update |

### Repository API (`GazesRepository`)

```dart
final repo = GazesRepository(appDatabase);

await repo.create('Alice');                 // insert, returns new id
await repo.getById(1);                      // single row by id
await repo.getAll();                        // all rows, newest-updated first
repo.watchAll();                            // Stream that re-emits on change
await repo.updateName(1, 'Bob');            // update name + updatedAt
await repo.delete(1);                       // delete by id
```

---

## Code Generation

Drift uses `build_runner` to generate `*.g.dart` files from table definitions.
**Run after every change to a table or the `AppDatabase` class.**

```bash
dart run build_runner build --delete-conflicting-outputs
```

For watch mode during active development:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

---

## Database Migrations

### How versioning works

`AppDatabase.schemaVersion` in `lib/db/app_database.dart` is the single source of truth.
Drift runs `onCreate` on a fresh install and `onUpgrade` when the installed version is lower than `schemaVersion`.

### Adding a new migration

1. **Edit the table** in `lib/db/tables/gazes.dart` (or add a new table file and register it in `@DriftDatabase(tables: [...])`).

2. **Bump `schemaVersion`** in `lib/db/app_database.dart`:
   ```dart
   @override
   int get schemaVersion => 2; // was 1
   ```

3. **Dump the new schema snapshot:**
   ```bash
   dart run drift_dev schema dump lib/db/app_database.dart lib/db/schemas/
   ```
   This writes `lib/db/schemas/drift_schema_v2.json`.

4. **Generate the step-by-step migration helper:**
   ```bash
   dart run drift_dev schema steps lib/db/schemas/ lib/db/schema_versions.dart
   ```

5. **Wire the migration** in `AppDatabase.migration`:
   ```dart
   import 'schema_versions.dart';

   @override
   MigrationStrategy get migration => MigrationStrategy(
     onCreate: (m) => m.createAll(),
     onUpgrade: stepByStep(
       from1To2: (m, schema) async {
         await m.addColumn(schema.gazes, schema.gazes.someNewColumn);
       },
     ),
   );
   ```

6. **Re-run code generation:**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

7. Ship. Existing installs will migrate automatically on next launch without data loss.

> **First-time setup (v1):** steps 3–5 are not needed — there is no prior version to migrate from.

### Common migration operations

```dart
// Add a column (nullable or with a default)
await m.addColumn(schema.gazes, schema.gazes.newColumn);

// Create a brand-new table
await m.createTable(schema.newTable);

// Drop a table
await m.deleteTable('old_table');

// Rename a table (recreate + copy + drop)
await m.renameTable(schema.gazes, 'old_name');
```

Full reference: https://drift.simonbinder.eu/migrations

---

## Fonts

Bricolage Grotesque is bundled as static TTF weight files in `assets/fonts/`.
Runtime HTTP fetching is disabled (`GoogleFonts.config.allowRuntimeFetching = false`)
so the font always loads from the bundle, with no network dependency.

To update the bundled fonts, download the new static TTF files from
[Google Fonts CDN](https://fonts.gstatic.com/s/a/{sha256hash}.ttf) using the
hashes listed in `google_fonts` package source
(`~/.pub-cache/hosted/pub.dev/google_fonts-*/lib/src/google_fonts_parts/part_b.dart`)
and replace the files in `assets/fonts/`.
