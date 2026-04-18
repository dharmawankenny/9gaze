// Process-wide access point for the app's drift database.
//
// Exposes a single lazily-opened [AppDatabase] instance so
// the rest of the app does not juggle multiple connections.
// Can be swapped for a proper DI/state-management solution
// later (e.g. Riverpod) without changing call sites that only
// rely on [appDatabase].

import 'package:kensa_9gaze/db/app_database.dart';

/// Shared [AppDatabase] instance. Drift uses a lazy executor
/// internally, so the underlying SQLite file is only opened
/// on first query.
final AppDatabase appDatabase = AppDatabase();
