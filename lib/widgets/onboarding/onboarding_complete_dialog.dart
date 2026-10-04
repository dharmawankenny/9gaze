// Closing dialog for the last step of the onboarding tour.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kensa_9gaze/app/theme.dart';
import 'package:kensa_9gaze/l10n/app_localizations.dart';
import 'package:kensa_9gaze/widgets/animated_gaze_face.dart';

/// Thanks the user and ends the tour when they tap Done.
class OnboardingCompleteDialog {
  OnboardingCompleteDialog._();

  /// Shows the ready dialog above the tour. Returns when Done is tapped.
  static Future<void> show(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final overlay = context.findRootAncestorStateOfType<OverlayState>();
    if (overlay == null) return Future<void>.value();

    final completer = Completer<void>();
    late OverlayEntry entry;

    /// Removes the alert and finishes [show].
    void finish() {
      if (completer.isCompleted) return;
      entry.remove();
      completer.complete();
    }

    entry = OverlayEntry(
      builder: (_) => _CompleteLayer(
        title: l10n.onboardingCompleteTitle,
        body: l10n.onboardingCompleteBody,
        doneLabel: l10n.done,
        onDone: finish,
      ),
    );
    overlay.insert(entry);
    return completer.future;
  }
}

/// Full-screen dimmer and the finished alert.
class _CompleteLayer extends StatefulWidget {
  const _CompleteLayer({
    required this.title,
    required this.body,
    required this.doneLabel,
    required this.onDone,
  });

  final String title;
  final String body;
  final String doneLabel;
  final VoidCallback onDone;

  @override
  State<_CompleteLayer> createState() => _CompleteLayerState();
}

class _CompleteLayerState extends State<_CompleteLayer>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Keeps the page underneath from closing while this alert is up.
  @override
  Future<bool> didPopRoute() async {
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          const ModalBarrier(dismissible: false, color: Color(0xBF000000)),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Material(
                  color: kBlack,
                  elevation: 12,
                  borderRadius: BorderRadius.circular(20),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.bricolageGrotesque(
                            color: kWhite,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Center(
                          child: AnimatedGazeFace(size: 56, eyeColor: kBlack),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          widget.body,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.bricolageGrotesque(
                            color: kWhite.withValues(alpha: 0.75),
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: widget.onDone,
                          style: TextButton.styleFrom(
                            backgroundColor: kAccentBlue,
                            foregroundColor: kWhite,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            widget.doneLabel,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.bricolageGrotesque(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
