// CRUD facade for gaze_text_overlays.

import 'package:drift/drift.dart';

import 'package:kensa_9gaze/db/app_database.dart';

class GazeTextOverlaysRepository {
  const GazeTextOverlaysRepository(this._db);

  final AppDatabase _db;

  Stream<List<GazeTextOverlay>> watchForGaze(int gazeId) {
    return (_db.select(_db.gazeTextOverlays)
          ..where((t) => t.gazeId.equals(gazeId))
          ..orderBy([(t) => OrderingTerm.asc(t.zIndex), (t) => OrderingTerm.asc(t.id)]))
        .watch();
  }

  Future<List<GazeTextOverlay>> getForGaze(int gazeId) {
    return (_db.select(_db.gazeTextOverlays)
          ..where((t) => t.gazeId.equals(gazeId))
          ..orderBy([(t) => OrderingTerm.asc(t.zIndex), (t) => OrderingTerm.asc(t.id)]))
        .get();
  }

  Future<void> replaceAllForGaze(
    int gazeId,
    List<GazeTextOverlaysCompanion> rows,
  ) {
    return _db.transaction(() async {
      await (_db.delete(_db.gazeTextOverlays)
            ..where((t) => t.gazeId.equals(gazeId)))
          .go();
      if (rows.isEmpty) return;
      await _db.batch((b) {
        b.insertAll(_db.gazeTextOverlays, rows);
      });
    });
  }
}
