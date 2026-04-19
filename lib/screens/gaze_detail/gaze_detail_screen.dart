// Gaze detail screen. Shows the patient name field pre-filled
// with the current gaze data and an update button that persists
// changes to the DB.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kensa_9gaze/app/theme.dart';
import 'package:kensa_9gaze/db/app_database.dart';
import 'package:kensa_9gaze/db/database_provider.dart';
import 'package:kensa_9gaze/repositories/gazes_repository.dart';

/// Detail view for a single [Gaze] entry.
///
/// Accepts the [gaze] as a constructor argument so it works
/// for both the post-create navigation and list-item taps.
/// The back button uses [Navigator.pop] to return to the
/// previous route.
class GazeDetailScreen extends StatefulWidget {
  const GazeDetailScreen({super.key, required this.gaze});

  final Gaze gaze;

  @override
  State<GazeDetailScreen> createState() => _GazeDetailScreenState();
}

class _GazeDetailScreenState extends State<GazeDetailScreen> {
  late final GazesRepository _repo;
  late final TextEditingController _nameController;

  /// True while the async update is in-flight.
  bool _loading = false;

  /// True after a successful update, triggers confirmation UI.
  bool _updated = false;

  @override
  void initState() {
    super.initState();
    _repo = GazesRepository(appDatabase);
    _nameController = TextEditingController(text: widget.gaze.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Persists the edited name to the DB.
  Future<void> _handleUpdate() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _loading || _updated) return;

    setState(() => _loading = true);

    await _repo.updateName(widget.gaze.id, name);

    if (!mounted) return;
    setState(() {
      _loading = false;
      _updated = true;
    });

    // Reset confirmation state after a short delay so the
    // button returns to idle if the user edits again.
    await Future<void>.delayed(const Duration(milliseconds: 1500));

    if (mounted) setState(() => _updated = false);
  }

  @override
  Widget build(BuildContext context) {
    final hintColor = kWhite.withValues(alpha: 0.5);

    return Scaffold(
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

            const SizedBox(height: 16),

            // ── Patient name field ────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: kDarkBlue,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: TextField(
                  controller: _nameController,
                  enabled: !_loading,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleUpdate(),
                  // Reset confirmation badge when user edits.
                  onChanged: (_) {
                    if (_updated) setState(() => _updated = false);
                  },
                  style: GoogleFonts.bricolageGrotesque(
                    color: kWhite,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Patient name',
                    hintStyle: GoogleFonts.bricolageGrotesque(
                      color: hintColor,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Update button ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _handleUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _updated
                        ? kAccentBlue.withValues(alpha: 0.6)
                        : kAccentBlue,
                    foregroundColor: kWhite,
                    disabledBackgroundColor: null,
                    disabledForegroundColor: kWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: _updated
                      ? _buildUpdatedContent()
                      : _buildIdleContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Button content after a successful update.
  Widget _buildUpdatedContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check, color: kWhite, size: 20),
        const SizedBox(width: 8),
        Text(
          'Updated',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: kWhite,
          ),
        ),
      ],
    );
  }

  /// Default idle button content.
  Widget _buildIdleContent() {
    return Text(
      'Update',
      style: GoogleFonts.bricolageGrotesque(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: kWhite,
      ),
    );
  }
}
