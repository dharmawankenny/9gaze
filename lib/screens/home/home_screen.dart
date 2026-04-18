// Main home screen that composes the top bar, search bar,
// and sticky new-gaze button.

import 'package:flutter/material.dart';

import 'package:kensa_9gaze/screens/home/widgets/home_top_bar.dart';
import 'package:kensa_9gaze/screens/home/widgets/home_search_bar.dart';
import 'package:kensa_9gaze/screens/home/widgets/new_gaze_button.dart';

/// Root screen for the home tab. Displays the title bar,
/// a search bar, an empty content area placeholder, and a
/// sticky action button at the bottom.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 16),
            const HomeTopBar(),
            const SizedBox(height: 20),
            const HomeSearchBar(),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ),
      bottomNavigationBar: const NewGazeButton(),
    );
  }
}
