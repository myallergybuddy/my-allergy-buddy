// Basic smoke test for My Allergy Buddy.

import 'package:flutter_test/flutter_test.dart';

import 'package:my_allergy_buddy/main.dart';

void main() {
  testWidgets('App loads splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('My Allergy Buddy'), findsOneWidget);
    expect(find.text('Your Personal Allergy Assistant'), findsOneWidget);

    // Flush splash timers so the test exits cleanly.
    await tester.pump(const Duration(seconds: 5));
  });
}
