// Basic smoke test for My Allergy Buddy (replaces default counter template).

import 'package:flutter_test/flutter_test.dart';

import 'package:my_allergy_buddy/main.dart';

void main() {
  testWidgets('App loads home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('My Allergy Buddy'), findsOneWidget);
    expect(find.textContaining('Welcome Back'), findsOneWidget);
  });
}
