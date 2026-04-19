// Drift table definition for the `gazes` table.

import 'package:drift/drift.dart';

/// Represents a single gaze session created by the user.
///
/// Columns:
/// - [id] auto-incremented primary key.
/// - [name] human-readable label, required.
/// - [notes] optional free-text field, added in schema v2.
/// - [isCompact] compact-mode flag, added in schema v3,
///   defaults to false.
/// - [isDoublePrimary] dual-primary flag, added in schema v3,
///   defaults to false.
/// - [createdAt] set to `CURRENT_TIMESTAMP` on insert.
/// - [updatedAt] set to `CURRENT_TIMESTAMP` on insert and
///   refreshed by the repository on every update.
class Gazes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isCompact =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isDoublePrimary =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
