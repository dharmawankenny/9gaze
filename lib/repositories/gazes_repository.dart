// Typed CRUD facade over the `gazes` drift table.
//
// Keeps drift-specific types out of the UI layer so screens
// can depend on plain [Gaze] data classes and simple futures
// / streams. `updatedAt` is refreshed here (not via SQL
// triggers) to keep the schema portable and migration-safe.

import 'package:drift/drift.dart';

import 'package:kensa_9gaze/db/app_database.dart';

/// Repository exposing high-level operations on the `gazes`
/// table. Holds a reference to the shared [AppDatabase] and
/// translates application intents into drift statements.
class GazesRepository {
  const GazesRepository(this._db);

  final AppDatabase _db;

  /// Inserts a new gaze with the given [name] and returns
  /// its auto-generated row id.
  Future<int> create(String name) {
    return _db.into(_db.gazes).insert(GazesCompanion.insert(name: name));
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

  /// Updates the [name] of the gaze identified by [id] and
  /// refreshes its `updatedAt` timestamp. Returns `true` if a
  /// row was actually modified.
  Future<bool> updateName(int id, String name) async {
    final affected =
        await (_db.update(_db.gazes)..where((g) => g.id.equals(id))).write(
          GazesCompanion(name: Value(name), updatedAt: Value(DateTime.now())),
        );
    return affected > 0;
  }

  /// Deletes the gaze identified by [id] and returns the
  /// number of rows removed (0 or 1).
  Future<int> delete(int id) {
    return (_db.delete(_db.gazes)..where((g) => g.id.equals(id))).go();
  }
}
