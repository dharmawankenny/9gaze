// One-file backup of the SQLite database and the gazes/ photo tree.
//
// The live database stays open. Import copies rows into it and then
// swaps the photo folder, so Drift does not have to reopen.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:kensa_9gaze/db/app_database.dart';
import 'package:kensa_9gaze/db/database_provider.dart';
import 'package:kensa_9gaze/services/app_storage_info.dart';

/// Why a backup could not be read or written.
enum BackupFailure { unsupported, unreadable }

/// Thrown when a backup file is not a 9Gaze archive.
class BackupException implements Exception {
  const BackupException(this.failure);

  final BackupFailure failure;
}

/// Exports and imports a `.9gaze` zip (database + photos).
class DataBackup {
  const DataBackup._();

  static const _format = 1;
  static const _manifestName = 'manifest.json';
  static const _databaseName = 'database.sqlite';

  /// Writes a backup zip and returns its bytes.
  ///
  /// Checkpoints SQLite first so the copied file includes recent writes.
  static Future<Uint8List> exportBytes() async {
    final temp = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final work = Directory(p.join(temp.path, '9gaze_export_$stamp'));
    await work.create(recursive: true);
    File? zipFile;

    try {
      await appDatabase.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
      final support = await getApplicationSupportDirectory();
      final liveDb = File(
        p.join(support.path, AppStorageInfo.databaseFileName),
      );
      if (!liveDb.existsSync()) {
        throw const BackupException(BackupFailure.unreadable);
      }

      final dbCopy = File(p.join(work.path, _databaseName));
      await liveDb.copy(dbCopy.path);

      final manifest = File(p.join(work.path, _manifestName));
      await manifest.writeAsString(
        jsonEncode({
          'format': _format,
          'schemaVersion': appDatabase.schemaVersion,
        }),
      );

      zipFile = File(p.join(temp.path, '9gaze-backup-$stamp.9gaze'));
      final encoder = ZipFileEncoder();
      encoder.create(zipFile.path);
      encoder.addFileSync(manifest, _manifestName);
      encoder.addFileSync(dbCopy, _databaseName);

      final docs = await getApplicationDocumentsDirectory();
      final gazes = Directory(p.join(docs.path, 'gazes'));
      if (gazes.existsSync()) {
        await for (final entity in gazes.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is! File) continue;
          final rel = p.relative(entity.path, from: docs.path);
          encoder.addFileSync(entity, rel.replaceAll('\\', '/'));
        }
      }
      await encoder.close();
      return zipFile.readAsBytes();
    } finally {
      if (work.existsSync()) {
        await work.delete(recursive: true);
      }
      if (zipFile != null && zipFile.existsSync()) {
        await zipFile.delete();
      }
    }
  }

  /// Replaces gazes, slots, overlays, and photo files from [zipFile].
  static Future<void> importFile(File zipFile) async {
    final temp = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final extracted = Directory(p.join(temp.path, '9gaze_import_$stamp'));
    await extracted.create(recursive: true);

    AppDatabase? backupDb;
    File? zipCopy;
    Directory? incoming;
    var committed = false;
    try {
      // extractFileToDisk only accepts a .zip extension.
      zipCopy = File(p.join(temp.path, '9gaze_import_$stamp.zip'));
      await zipFile.copy(zipCopy.path);
      await extractFileToDisk(zipCopy.path, extracted.path);
      final manifestFile = File(p.join(extracted.path, _manifestName));
      final dbFile = File(p.join(extracted.path, _databaseName));
      if (!manifestFile.existsSync() || !dbFile.existsSync()) {
        throw const BackupException(BackupFailure.unsupported);
      }

      final manifest =
          jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
      final format = manifest['format'];
      if (format != _format) {
        throw const BackupException(BackupFailure.unsupported);
      }

      backupDb = AppDatabase(NativeDatabase(dbFile));
      final gazes = await backupDb.select(backupDb.gazes).get();
      final slots = await backupDb.select(backupDb.gazeSlots).get();
      final overlays = await backupDb.select(backupDb.gazeTextOverlays).get();
      await backupDb.close();
      backupDb = null;

      final docs = await getApplicationDocumentsDirectory();
      incoming = Directory(p.join(docs.path, 'gazes_incoming'));
      if (incoming.existsSync()) {
        await incoming.delete(recursive: true);
      }
      final extractedGazes = Directory(p.join(extracted.path, 'gazes'));
      if (extractedGazes.existsSync()) {
        await _copyDirectory(extractedGazes, incoming);
      }

      await appDatabase.transaction(() async {
        await appDatabase.delete(appDatabase.gazeTextOverlays).go();
        await appDatabase.delete(appDatabase.gazeSlots).go();
        await appDatabase.delete(appDatabase.gazes).go();

        for (final gaze in gazes) {
          await appDatabase
              .into(appDatabase.gazes)
              .insert(
                GazesCompanion(
                  id: Value(gaze.id),
                  name: Value(gaze.name),
                  notes: Value(gaze.notes),
                  isCompact: Value(gaze.isCompact),
                  isDoublePrimary: Value(gaze.isDoublePrimary),
                  createdAt: Value(gaze.createdAt),
                  updatedAt: Value(gaze.updatedAt),
                ),
              );
        }
        for (final slot in slots) {
          await appDatabase
              .into(appDatabase.gazeSlots)
              .insert(
                GazeSlotsCompanion(
                  id: Value(slot.id),
                  gazeId: Value(slot.gazeId),
                  slotKey: Value(slot.slotKey),
                  imagePath: Value(slot.imagePath),
                  translateX: Value(slot.translateX),
                  translateY: Value(slot.translateY),
                  scale: Value(slot.scale),
                  rotation: Value(slot.rotation),
                  eyeLeftX: Value(slot.eyeLeftX),
                  eyeLeftY: Value(slot.eyeLeftY),
                  eyeRightX: Value(slot.eyeRightX),
                  eyeRightY: Value(slot.eyeRightY),
                  sourceWidth: Value(slot.sourceWidth),
                  sourceHeight: Value(slot.sourceHeight),
                  createdAt: Value(slot.createdAt),
                  updatedAt: Value(slot.updatedAt),
                ),
              );
        }
        for (final overlay in overlays) {
          await appDatabase
              .into(appDatabase.gazeTextOverlays)
              .insert(
                GazeTextOverlaysCompanion(
                  id: Value(overlay.id),
                  gazeId: Value(overlay.gazeId),
                  content: Value(overlay.content),
                  x: Value(overlay.x),
                  y: Value(overlay.y),
                  scale: Value(overlay.scale),
                  textColor: Value(overlay.textColor),
                  bgColor: Value(overlay.bgColor),
                  zIndex: Value(overlay.zIndex),
                  createdAt: Value(overlay.createdAt),
                  updatedAt: Value(overlay.updatedAt),
                ),
              );
        }
        await _resetSequence('gazes');
        await _resetSequence('gaze_slots');
        await _resetSequence('gaze_text_overlays');
      });
      committed = true;

      await _replaceGazesDirectory(
        docs,
        incoming.existsSync() ? incoming : null,
      );
    } on BackupException {
      rethrow;
    } catch (error) {
      final message = error.toString().toLowerCase();
      if (message.contains('schema') || message.contains('version')) {
        throw const BackupException(BackupFailure.unsupported);
      }
      throw const BackupException(BackupFailure.unreadable);
    } finally {
      await backupDb?.close();
      if (zipCopy != null && zipCopy.existsSync()) {
        await zipCopy.delete();
      }
      if (extracted.existsSync()) {
        await extracted.delete(recursive: true);
      }
      if (!committed && incoming != null && incoming.existsSync()) {
        await incoming.delete(recursive: true);
      }
    }
  }

  /// Points the autoincrement counter at the highest restored id.
  ///
  /// sqlite_sequence has no unique constraint, so this inserts a
  /// missing row and then updates it.
  static Future<void> _resetSequence(String table) async {
    await appDatabase.customStatement(
      "INSERT INTO sqlite_sequence(name, seq) "
      "SELECT '$table', IFNULL(MAX(id), 0) FROM $table "
      "WHERE NOT EXISTS ("
      "SELECT 1 FROM sqlite_sequence WHERE name = '$table')",
    );
    await appDatabase.customStatement(
      "UPDATE sqlite_sequence SET seq = "
      "(SELECT IFNULL(MAX(id), 0) FROM $table) WHERE name = '$table'",
    );
  }

  /// Copies [from] into [to], creating parent folders as needed.
  static Future<void> _copyDirectory(Directory from, Directory to) async {
    await to.create(recursive: true);
    await for (final entity in from.list(recursive: true, followLinks: false)) {
      final rel = p.relative(entity.path, from: from.path);
      final destPath = p.join(to.path, rel);
      if (entity is Directory) {
        await Directory(destPath).create(recursive: true);
      } else if (entity is File) {
        await Directory(p.dirname(destPath)).create(recursive: true);
        await entity.copy(destPath);
      }
    }
  }

  /// Swaps the live `gazes/` folder for [incoming] after the DB commit.
  static Future<void> _replaceGazesDirectory(
    Directory docs,
    Directory? incoming,
  ) async {
    final live = Directory(p.join(docs.path, 'gazes'));
    final previous = Directory(p.join(docs.path, 'gazes_previous'));
    if (previous.existsSync()) {
      await previous.delete(recursive: true);
    }
    if (live.existsSync()) {
      await live.rename(previous.path);
    }
    if (incoming != null && incoming.existsSync()) {
      await incoming.rename(live.path);
    }
    if (previous.existsSync()) {
      await previous.delete(recursive: true);
    }
  }
}
