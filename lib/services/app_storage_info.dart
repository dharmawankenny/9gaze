// Reports where 9Gaze stores photos, thumbnails, and the database.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// On-disk locations and sizes for the app sandbox.
class AppStorageSnapshot {
  const AppStorageSnapshot({
    required this.imagesPath,
    required this.databasePath,
    required this.imagesBytes,
    required this.databaseBytes,
  });

  /// Absolute path of the `gazes/` photo directory.
  final String imagesPath;

  /// Absolute path of the SQLite database file.
  final String databasePath;

  /// Bytes used by originals and thumbnails.
  final int imagesBytes;

  /// Bytes used by the database, including WAL files.
  final int databaseBytes;

  /// Photos plus database.
  int get totalBytes => imagesBytes + databaseBytes;
}

/// Formats a byte count as B, KB, MB, or GB.
String formatStorageBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  const kb = 1024;
  const mb = 1024 * 1024;
  const gb = 1024 * 1024 * 1024;
  if (bytes < mb) return '${(bytes / kb).toStringAsFixed(1)} KB';
  if (bytes < gb) return '${(bytes / mb).toStringAsFixed(1)} MB';
  return '${(bytes / gb).toStringAsFixed(2)} GB';
}

/// Reads sandbox paths and sums file sizes.
class AppStorageInfo {
  const AppStorageInfo._();

  static const databaseFileName = 'kensa_9gaze.sqlite';

  /// Collects the current storage snapshot.
  static Future<AppStorageSnapshot> load() async {
    final docs = await getApplicationDocumentsDirectory();
    final support = await getApplicationSupportDirectory();
    final imagesDir = Directory(p.join(docs.path, 'gazes'));
    final databaseFile = File(p.join(support.path, databaseFileName));

    return AppStorageSnapshot(
      imagesPath: imagesDir.path,
      databasePath: databaseFile.path,
      imagesBytes: await _directoryBytes(imagesDir),
      databaseBytes: _databaseBytes(databaseFile),
    );
  }

  /// Sums every file under [dir]. Missing directories count as zero.
  static Future<int> _directoryBytes(Directory dir) async {
    if (!dir.existsSync()) return 0;
    var total = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }

  /// Includes the main database and its WAL/SHM sidecars.
  static int _databaseBytes(File databaseFile) {
    var total = 0;
    for (final path in [
      databaseFile.path,
      '${databaseFile.path}-wal',
      '${databaseFile.path}-shm',
    ]) {
      final file = File(path);
      if (file.existsSync()) total += file.lengthSync();
    }
    return total;
  }
}
