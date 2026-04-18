// Drift table definition for the `gazes` table.

import 'package:drift/drift.dart';

/// Represents a single gaze session created by the user.
///
/// Columns:
/// - [id] auto-incremented primary key.
/// - [name] human-readable label, required.
/// - [createdAt] set to `CURRENT_TIMESTAMP` on insert.
/// - [updatedAt] set to `CURRENT_TIMESTAMP` on insert and
///   refreshed by the repository on every update.
class Gazes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
