// Bottom sheet form for editing an existing Gaze entry.
// Pre-fills name and notes from the supplied [gaze], writes
// changes to the DB on submit, then closes via pop with the
// updated [Gaze] row so the detail screen can refresh in place.

import 'package:flutter/material.dart';
import 'package:kensa_9gaze/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kensa_9gaze/app/theme.dart';
import 'package:kensa_9gaze/db/app_database.dart';
import 'package:kensa_9gaze/db/database_provider.dart';
import 'package:kensa_9gaze/repositories/gazes_repository.dart';
import 'package:kensa_9gaze/widgets/animated_gaze_face.dart';

/// Modal bottom sheet for updating an existing [Gaze].
///
/// On success it pops with the refreshed [Gaze] row so the
/// caller can update its local state without an extra DB read.
class UpdateGazeSheet extends StatefulWidget {
  const UpdateGazeSheet({super.key, required this.gaze});

  final Gaze gaze;

  @override
  State<UpdateGazeSheet> createState() => _UpdateGazeSheetState();
}

class _UpdateGazeSheetState extends State<UpdateGazeSheet> {
  late final GazesRepository _repo;
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;

  /// True while the async update is in-flight.
  bool _loading = false;

  /// True after a successful update, triggers confirmation UI.
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _repo = GazesRepository(appDatabase);
    _nameController = TextEditingController(text: widget.gaze.name);
    _notesController = TextEditingController(text: widget.gaze.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Validates, writes to DB, shows confirmation, then pops
  /// with the refreshed [Gaze] so the parent can update itself.
  Future<void> _handleSubmit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _loading || _submitted) return;

    setState(() => _loading = true);

    final notes = _notesController.text.trim();
    await _repo.updateGaze(
      widget.gaze.id,
      name,
      notes: notes.isEmpty ? null : notes,
    );
    final updated = await _repo.getById(widget.gaze.id);

    if (!mounted) return;
    setState(() {
      _loading = false;
      _submitted = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (mounted) Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final hintColor = kWhite.withValues(alpha: 0.5);
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 32 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Drag handle ──────────────────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: kWhite.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Sheet title ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l10n.gazeDetail,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: kWhite,
              ),
            ),
          ),

          // ── Gaze detail name field ───────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            decoration: BoxDecoration(
              color: kDarkBlue,
              borderRadius: BorderRadius.circular(50),
            ),
            child: TextField(
              controller: _nameController,
              autofocus: true,
              enabled: !_submitted,
              textInputAction: TextInputAction.next,
              style: GoogleFonts.bricolageGrotesque(
                color: kWhite,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: l10n.gazeDetailName,
                hintStyle: GoogleFonts.bricolageGrotesque(
                  color: hintColor,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Notes textarea ───────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: kDarkBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _notesController,
              enabled: !_submitted,
              maxLines: 4,
              minLines: 3,
              textInputAction: TextInputAction.newline,
              style: GoogleFonts.bricolageGrotesque(
                color: kWhite,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: l10n.notesOptional,
                hintStyle: GoogleFonts.bricolageGrotesque(
                  color: hintColor,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Submit button ────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _submitted ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _submitted
                    ? kAccentBlue.withValues(alpha: 0.6)
                    : kAccentBlue,
                foregroundColor: kWhite,
                disabledBackgroundColor: _submitted
                    ? kAccentBlue.withValues(alpha: 0.6)
                    : null,
                disabledForegroundColor: kWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: _submitted
                  ? _buildSubmittedContent(l10n)
                  : _buildIdleContent(l10n),
            ),
          ),
        ],
      ),
    );
  }

  /// Button content after a successful update.
  Widget _buildSubmittedContent(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        AnimatedGazeFace.static(
          direction: GazeDirection.levoelevation,
          size: 28,
          eyeColor: kAccentBlue.withValues(alpha: 0.6),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              l10n.updated,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: kWhite,
              ),
              textAlign: TextAlign.start,
            ),
          ),
        ),
        const Icon(Icons.check, color: kWhite, size: 24),
      ],
    );
  }

  /// Default idle button content.
  Widget _buildIdleContent(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              l10n.updateGaze,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: kWhite,
              ),
              textAlign: TextAlign.start,
            ),
          ),
        ),
        const Icon(Icons.arrow_forward, color: kWhite, size: 24),
      ],
    );
  }
}
