// Basic smoke test for the 9Gaze app.

import 'package:flutter_test/flutter_test.dart';

import 'package:kensa_9gaze/main.dart';

void main() {
  testWidgets('Home screen renders title', (WidgetTester tester) async {
    await tester.pumpWidget(const NineGazeApp());

    expect(find.text('9Gaze'), findsOneWidget);
    expect(find.text('New Gaze'), findsOneWidget);
  });
}
