// InheritedWidget that exposes [OnboardingController] to the widget tree.

import 'package:flutter/material.dart';

import 'package:kensa_9gaze/services/onboarding/onboarding_controller.dart';

/// Provides [OnboardingController] below [MaterialApp].
class OnboardingScope extends InheritedNotifier<OnboardingController> {
  const OnboardingScope({
    super.key,
    required OnboardingController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Returns the scoped controller or throws if missing.
  static OnboardingController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<OnboardingScope>();
    assert(scope != null, 'OnboardingScope not found above context');
    return scope!.notifier!;
  }

  /// Returns the scoped controller when present.
  static OnboardingController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<OnboardingScope>()
        ?.notifier;
  }
}
