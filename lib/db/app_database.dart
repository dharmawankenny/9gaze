// Root drift database class for 9Gaze.
//
// Registers all tables, declares the schema version, and
// wires up the migration strategy. Generated companion file
// `app_database.g.dart` is produced by `build_runner`.

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'package:kensa_9gaze/db/tables/gazes.dart';

part 'app_database.g.dart';

/// Opens the native SQLite connection used by [AppDatabase].
///
/// Stored in `ApplicationSupportDirectory` to play nicely with
/// sandboxed macOS/iOS builds.
QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'kensa_9gaze',
    native: const DriftNativeOptions(
      databaseDirectory: getApplicationSupportDirectory,
    ),
  );
}

/// Top-level drift database. Owns all tables and controls
/// schema migration between versions.
@DriftDatabase(tables: [Gazes])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // v2: add optional notes column to gazes.
      if (from < 2) {
        await m.addColumn(gazes, gazes.notes);
      }
      // v3: add compact-mode and dual-primary boolean flags.
      if (from < 3) {
        await m.addColumn(gazes, gazes.isCompact);
        await m.addColumn(gazes, gazes.isDoublePrimary);
      }
    },
  );
}
