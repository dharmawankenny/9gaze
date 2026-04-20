// Drift table storing movable text overlays for a gaze grid.

import 'package:drift/drift.dart';

import 'package:kensa_9gaze/db/tables/gazes.dart';

class GazeTextOverlays extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get gazeId =>
      integer().references(Gazes, #id, onDelete: KeyAction.cascade)();

  // Named "text" in SQL; getter must avoid collision with text().
  TextColumn get content =>
      text().named('text').withDefault(const Constant(''))();

  // Normalized 0..1 position within the full grid bounds.
  RealColumn get x => real().withDefault(const Constant(0.5))();
  RealColumn get y => real().withDefault(const Constant(0.5))();

  // Relative scale factor; text size = baseFontPx * scale.
  RealColumn get scale => real().withDefault(const Constant(1.0))();

  // ARGB colors encoded as signed int.
  IntColumn get textColor => integer().withDefault(const Constant(-1))();
  IntColumn get bgColor => integer().nullable()();

  // Draw order within overlay layer.
  IntColumn get zIndex => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
