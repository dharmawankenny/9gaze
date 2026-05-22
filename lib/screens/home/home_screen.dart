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
import 'package:kensa_9gaze/services/onboarding/onboarding_controller.dart';
import 'package:kensa_9gaze/services/onboarding/onboarding_step.dart';
import 'package:kensa_9gaze/services/thumbnail_backfill.dart';
import 'package:kensa_9gaze/widgets/onboarding/onboarding_scope.dart';
import 'package:kensa_9gaze/widgets/onboarding/welcome_onboarding_page.dart';

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
  bool _onboardingBootstrapDone = false;

  @override
  void initState() {
    super.initState();
    _gazesStream = _repo.watchAll();
    // Background one-time migration for legacy slots created before
    // thumbnail support existed. Non-blocking and safe to rerun.
    Future<void>.microtask(() => ThumbnailBackfill.runOnce(appDatabase));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      removeSplash();
      _bootstrapOnboarding();
    });
  }

  /// Starts the welcome tour when first-run eligibility passes.
  Future<void> _bootstrapOnboarding() async {
    if (_onboardingBootstrapDone || !mounted) return;
    _onboardingBootstrapDone = true;

    final onboarding = OnboardingScope.of(context);
    final eligible = await onboarding.startIfEligible();
    if (!eligible || !mounted) return;
    if (onboarding.currentStep != OnboardingStep.welcome) return;

    await _showWelcomeDialog(onboarding);
  }

  /// Presents step 1; on Next advances to home list showcase (Phase 2).
  Future<void> _showWelcomeDialog(OnboardingController onboarding) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      useSafeArea: true,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: Dialog.fullscreen(
            backgroundColor: Colors.black,
            child: WelcomeOnboardingPage(
              onNext: () => Navigator.of(dialogContext).pop(),
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    onboarding.advance(step: OnboardingStep.homeEmptyList);
    onboarding.startShowcaseForCurrentStep();
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
