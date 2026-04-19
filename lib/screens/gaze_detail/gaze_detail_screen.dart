// Gaze detail screen. Displays patient info as read-only text.
// An 'Update' button in the header opens a bottom sheet that
// allows editing and writes changes back to the DB.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kensa_9gaze/app/theme.dart';
import 'package:kensa_9gaze/db/app_database.dart';
import 'package:kensa_9gaze/db/database_provider.dart';
import 'package:kensa_9gaze/repositories/gazes_repository.dart';
import 'package:kensa_9gaze/screens/gaze_detail/update_gaze_sheet.dart';
import 'package:kensa_9gaze/screens/gaze_detail/widgets/gaze_direction_grid.dart';

/// Detail view for a single [Gaze] entry.
///
/// Displays patient info read-only. The Update button opens
/// [UpdateGazeSheet] which pops back with the refreshed [Gaze]
/// so this screen updates in place without a route push.
class GazeDetailScreen extends StatefulWidget {
  const GazeDetailScreen({super.key, required this.gaze});

  final Gaze gaze;

  @override
  State<GazeDetailScreen> createState() => _GazeDetailScreenState();
}

class _GazeDetailScreenState extends State<GazeDetailScreen> {
  late final GazesRepository _repo;

  /// Mutable local copy; updated when the sheet returns a new row.
  late Gaze _current;

  late bool _compactMode;
  late bool _dualPrimary;

  /// Guard against concurrent flag writes.
  bool _flagsLoading = false;

  @override
  void initState() {
    super.initState();
    _repo = GazesRepository(appDatabase);
    _current = widget.gaze;
    _compactMode = _current.isCompact;
    _dualPrimary = _current.isDoublePrimary;
  }

  /// Persists both flag values to the DB, updating local state
  /// optimistically so the UI responds instantly.
  Future<void> _handleFlagChanged({bool? compact, bool? doublePrimary}) async {
    if (_flagsLoading) return;

    final nextCompact = compact ?? _compactMode;
    final nextDouble = doublePrimary ?? _dualPrimary;

    setState(() {
      _compactMode = nextCompact;
      _dualPrimary = nextDouble;
      _flagsLoading = true;
    });

    await _repo.updateFlags(
      _current.id,
      isCompact: nextCompact,
      isDoublePrimary: nextDouble,
    );

    if (mounted) setState(() => _flagsLoading = false);
  }

  /// Saves the gaze chart to the device gallery.
  ///
  /// Implementation pending: will render the gaze direction grid
  /// to an image and write it via the platform gallery API.
  void _handleSaveToGallery() {
    // TODO: implement render-to-image and gallery save.
  }

  /// Opens the update sheet and refreshes [_current] on save.
  Future<void> _handleOpenUpdateSheet() async {
    final updated = await showModalBottomSheet<Gaze>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => UpdateGazeSheet(gaze: _current),
    );

    if (updated != null && mounted) {
      setState(() => _current = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ).copyWith(bottom: 16),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _handleSaveToGallery,
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccentBlue,
                foregroundColor: kWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.download_for_offline_outlined,
                    color: kWhite,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Save to Gallery',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: kWhite,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top bar ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: kWhite, size: 24),
                    tooltip: 'Back',
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Gaze Details',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: kWhite,
                      letterSpacing: -1.2,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // ── 3×3 gaze direction grid ───────────────────────
            const GazeDirectionGrid(),

            const SizedBox(height: 12),

            // ── Settings island ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ).add(EdgeInsets.only(top: 16)),
                decoration: BoxDecoration(
                  color: kDarkBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    // Compact Mode toggle
                    Expanded(
                      child: _ToggleRow(
                        label: 'Compact Mode?',
                        value: _compactMode,
                        onChanged: (v) => _handleFlagChanged(compact: v),
                      ),
                    ),
                    // Thin divider between the two toggles.
                    Container(
                      width: 1,
                      height: 40,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      color: kWhite.withValues(alpha: 0.08),
                    ),
                    // Dual Primary toggle
                    Expanded(
                      child: _ToggleRow(
                        label: 'Dual Primary?',
                        value: _dualPrimary,
                        onChanged: (v) => _handleFlagChanged(doublePrimary: v),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Patient Info card ─────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: kDarkBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section header row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Opacity(
                          opacity: 0.5,
                          child: Text(
                            'Patient Info',
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 12,
                              color: kWhite,
                            ),
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _handleOpenUpdateSheet,
                          style: TextButton.styleFrom(
                            backgroundColor: kBlack,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Update',
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: kWhite,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Patient name field
                    Text(
                      _current.name,
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: kWhite,
                      ),
                    ),

                    // Notes (only when present)
                    if (_current.notes != null) ...[
                      const SizedBox(height: 4),
                      Opacity(
                        opacity: 0.75,
                        child: Text(
                          _current.notes!,
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 14,
                            color: kWhite,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A label with a No/Yes switch displayed in a compact row.
///
/// Shows the [label] above a row containing the current value
/// text ("No" / "Yes") and a [Switch] aligned to the right.
class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: kWhite.withValues(alpha: 0.4),
          ),
        ),
        Row(
          children: [
            Text(
              value ? 'Yes' : 'No',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kWhite,
              ),
            ),
            const Spacer(),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: kAccentBlue,
              activeTrackColor: kAccentBlue.withValues(alpha: 0.3),
              inactiveThumbColor: kWhite.withValues(alpha: 0.4),
              inactiveTrackColor: kWhite.withValues(alpha: 0.1),
            ),
          ],
        ),
      ],
    );
  }
}
