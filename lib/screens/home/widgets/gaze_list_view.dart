// Reactive list of all Gaze entries. Receives pre-fetched data
// from HomeScreen so the stream is shared with the button bar.
// Renders an animated face placeholder when empty.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kensa_9gaze/app/theme.dart';
import 'package:kensa_9gaze/db/app_database.dart';
import 'package:kensa_9gaze/screens/home/widgets/gaze_list_item.dart';
import 'package:kensa_9gaze/widgets/animated_gaze_face.dart';

/// Renders the gaze list or an appropriate empty/error/loading
/// state. Data is supplied by the parent so the stream is not
/// duplicated.
///
/// [isFiltered] distinguishes a search-driven empty result from
/// a truly empty table, so the correct message is shown.
class GazeListView extends StatelessWidget {
  const GazeListView({
    super.key,
    required this.gazes,
    required this.isLoading,
    required this.hasError,
    required this.isFiltered,
    required this.onDelete,
  });

  final List<Gaze> gazes;
  final bool isLoading;
  final bool hasError;

  /// True when the list is empty due to an active search query
  /// rather than the table itself being empty.
  final bool isFiltered;

  /// Called after the user confirms deletion of [gaze].
  final Future<void> Function(Gaze gaze) onDelete;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(kAccentBlue),
        ),
      );
    }

    if (hasError) {
      return Center(
        child: Text(
          'Failed to load gazes.',
          style: GoogleFonts.bricolageGrotesque(
            color: kWhite.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    if (gazes.isEmpty) {
      return _EmptyState(isFiltered: isFiltered);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      itemCount: gazes.length,
      itemBuilder: (context, index) {
        final gaze = gazes[index];
        return GazeListItem(
          key: ValueKey(gaze.id),
          gaze: gaze,
          onDeleteConfirmed: () => onDelete(gaze),
        );
      },
    );
  }
}

/// Centred placeholder shown when the visible list is empty.
///
/// The animated face is sized to half the screen width so it
/// fills the space proportionally on any device while keeping
/// the 1:1 aspect ratio locked via [SizedBox.square].
/// A context-sensitive message sits 16 px below the face.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isFiltered});

  /// Whether the empty state is caused by an active search
  /// filter rather than the table truly having no rows.
  final bool isFiltered;

  @override
  Widget build(BuildContext context) {
    final faceSize = MediaQuery.sizeOf(context).width / 2;
    final message = isFiltered
        ? 'No gaze found, try searching for another name'
        : 'No gaze yet, make one by clicking the blue button below';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(opacity: 0.5, child: AnimatedGazeFace(size: faceSize)),
          Container(
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.bricolageGrotesque(
                color: kWhite.withValues(alpha: 0.3),
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
