// Main home screen that composes the top bar, search bar,
// and sticky new-gaze button.

import 'package:flutter/material.dart';

import 'package:kensa_9gaze/main.dart';
import 'package:kensa_9gaze/screens/home/widgets/home_search_bar.dart';
import 'package:kensa_9gaze/screens/home/widgets/home_top_bar.dart';
import 'package:kensa_9gaze/screens/home/widgets/new_gaze_button.dart';

/// Root screen for the home tab. Displays the title bar,
/// a search bar, an empty content area placeholder, and a
/// sticky action button at the bottom.
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
  @override
  void initState() {
    super.initState();
    // Dismiss the native splash on the first rendered frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => removeSplash());
  }

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
