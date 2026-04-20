// Main home screen that composes the top bar, search bar,
// gaze list, and sticky new-gaze button.
//
// Owns the single gazes stream and the search query so both
// the list and the button share state without extra streams.

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
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _gazesStream = _repo.watchAll();
    WidgetsBinding.instance.addPostFrameCallback((_) => removeSplash());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Updates query state on every keystroke.
  void _handleSearchChanged(String value) {
    setState(() => _query = value.trim().toLowerCase());
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

  /// Filters [all] by the current [_query] (case-insensitive
  /// substring match on name). Returns [all] unchanged when
  /// the query is empty.
  List<Gaze> _applyFilter(List<Gaze> all) {
    if (_query.isEmpty) return all;
    return all.where((g) => g.name.toLowerCase().contains(_query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Gaze>>(
      stream: _gazesStream,
      builder: (context, snapshot) {
        final allGazes = snapshot.data ?? [];
        final hasEntries = allGazes.isNotEmpty;
        final filtered = _applyFilter(allGazes);

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(height: 16),
                const HomeTopBar(),
                // Search bar hidden when no entries exist at all.
                if (hasEntries) ...[
                  const SizedBox(height: 20),
                  HomeSearchBar(
                    controller: _searchController,
                    onChanged: _handleSearchChanged,
                  ),
                ],
                Expanded(
                  child: GazeListView(
                    gazes: filtered,
                    isLoading:
                        snapshot.connectionState == ConnectionState.waiting,
                    hasError: snapshot.hasError,
                    isFiltered: _query.isNotEmpty,
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
