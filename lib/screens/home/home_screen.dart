// Main home screen that composes the top bar, search bar,
// gaze list, and sticky new-gaze button.
//
// Owns the single gazes stream subscription so both the list
// and the button can react to empty/non-empty state without
// duplicating DB connections.

import 'package:flutter/material.dart';

import 'package:kensa_9gaze/db/app_database.dart';
import 'package:kensa_9gaze/db/database_provider.dart';
import 'package:kensa_9gaze/main.dart';
import 'package:kensa_9gaze/repositories/gazes_repository.dart';
import 'package:kensa_9gaze/screens/home/widgets/gaze_list_view.dart';
import 'package:kensa_9gaze/screens/home/widgets/home_search_bar.dart';
import 'package:kensa_9gaze/screens/home/widgets/home_top_bar.dart';
import 'package:kensa_9gaze/screens/home/widgets/new_gaze_button.dart';
import 'package:kensa_9gaze/screens/home/widgets/new_gaze_sheet.dart';

/// Root screen for the home tab. Holds the gazes stream so the
/// list and the bottom button share one subscription.
///
/// Also owns the native splash dismissal: the splash is held
/// until the first frame renders so the user never sees a
/// blank black frame between splash and content.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repo = GazesRepository(appDatabase);
  late final Stream<List<Gaze>> _gazesStream;

  @override
  void initState() {
    super.initState();
    _gazesStream = _repo.watchAll();
    WidgetsBinding.instance.addPostFrameCallback((_) => removeSplash());
  }

  /// Opens the new-gaze bottom sheet.
  void _handleNewGaze() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const NewGazeSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Gaze>>(
      stream: _gazesStream,
      builder: (context, snapshot) {
        final gazes = snapshot.data ?? [];
        final hasEntries = gazes.isNotEmpty;

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(height: 16),
                const HomeTopBar(),
                const SizedBox(height: 20),
                const HomeSearchBar(),
                Expanded(
                  child: GazeListView(
                    gazes: gazes,
                    isLoading: snapshot.connectionState ==
                        ConnectionState.waiting,
                    hasError: snapshot.hasError,
                    onDelete: (gaze) => _repo.delete(gaze.id),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: NewGazeButton(
            onPressed: _handleNewGaze,
            showFace: hasEntries,
          ),
        );
      },
    );
  }
}
