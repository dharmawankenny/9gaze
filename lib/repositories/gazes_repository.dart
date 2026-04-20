// Typed CRUD facade over the `gazes` drift table.
//
// Keeps drift-specific types out of the UI layer so screens
// can depend on plain [Gaze] data classes and simple futures
// / streams. `updatedAt` is refreshed here (not via SQL
// triggers) to keep the schema portable and migration-safe.
//
// Deleting a gaze also cleans up all associated slot image files
// from the app documents directory before the DB cascade fires.

import 'package:drift/drift.dart';

import 'package:kensa_9gaze/db/app_database.dart';
import 'package:kensa_9gaze/repositories/gaze_slots_repository.dart';
import 'package:kensa_9gaze/services/image_storage.dart';

/// Repository exposing high-level operations on the `gazes`
/// table. Holds a reference to the shared [AppDatabase] and
/// translates application intents into drift statements.
class GazesRepository {
  const GazesRepository(this._db);

  final AppDatabase _db;

  /// Inserts a new gaze with the given [name] and optional
  /// [notes], returning its auto-generated row id.
  Future<int> create(String name, {String? notes}) {
    return _db
        .into(_db.gazes)
        .insert(GazesCompanion.insert(name: name, notes: Value(notes)));
  }

  /// Fetches a single gaze by [id], or throws if not found.
  Future<Gaze> getById(int id) {
    return (_db.select(_db.gazes)..where((g) => g.id.equals(id))).getSingle();
  }

  /// Returns all gazes ordered by most recently updated first.
  Future<List<Gaze>> getAll() {
    return (_db.select(
      _db.gazes,
    )..orderBy([(g) => OrderingTerm.desc(g.updatedAt)])).get();
  }

  /// Reactive variant of [getAll] that emits a new list on
  /// every change to the `gazes` table.
  Stream<List<Gaze>> watchAll() {
    return (_db.select(
      _db.gazes,
    )..orderBy([(g) => OrderingTerm.desc(g.updatedAt)])).watch();
  }

  /// Updates the [name] and optional [notes] of the gaze
  /// identified by [id], refreshing `updatedAt`. Returns
  /// `true` if a row was actually modified.
  ///
  /// Pass [notes] as `null` to clear the field, or omit the
  /// argument to leave it unchanged by passing a sentinel —
  /// use [updateName] if only the name needs updating.
  Future<bool> updateGaze(int id, String name, {String? notes}) async {
    final affected =
        await (_db.update(_db.gazes)..where((g) => g.id.equals(id))).write(
          GazesCompanion(
            name: Value(name),
            notes: Value(notes),
            updatedAt: Value(DateTime.now()),
          ),
        );
    return affected > 0;
  }

  /// Updates [isCompact] and [isDoublePrimary] flags for the
  /// gaze identified by [id]. Does not refresh [updatedAt]
  /// because these are UI preferences, not patient data edits.
  Future<void> updateFlags(
    int id, {
    required bool isCompact,
    required bool isDoublePrimary,
  }) {
    return (_db.update(_db.gazes)..where((g) => g.id.equals(id))).write(
      GazesCompanion(
        isCompact: Value(isCompact),
        isDoublePrimary: Value(isDoublePrimary),
      ),
    );
  }

  /// Deletes the gaze identified by [id] and returns the number
  /// of rows removed (0 or 1).
  ///
  /// Before removing the DB row, all associated slot image files
  /// are deleted from the app sandbox. The drift `onDelete: cascade`
  /// on [GazeSlots.gazeId] then removes the slot rows automatically.
  Future<int> delete(int id) async {
    // Clean up image files before the cascade removes slot rows.
    final slotsRepo = GazeSlotsRepository(_db);
    final slots = await slotsRepo.getAllForGazeOnce(id);
    for (final slot in slots) {
      await ImageStorage.deleteSlotFile(slot.imagePath);
    }
    // Also remove the directory in case any orphaned files remain.
    await ImageStorage.deleteGazeDirectory(id);

    return (_db.delete(_db.gazes)..where((g) => g.id.equals(id))).go();
  }
}
