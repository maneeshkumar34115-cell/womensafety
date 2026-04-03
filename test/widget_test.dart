// SafeGuardHer - Widget Test (placeholder)
// This test verifies the app launches without crashing.

import 'package:flutter_test/flutter_test.dart';
import 'package:safeguardher/main.dart';

void main() {
  testWidgets('SafeGuardHer app launches', (WidgetTester tester) async {
    await tester.pumpWidget(const SafeGuardHerApp());
    // Verify splash screen is shown
    expect(find.text('SafeGuardHer'), findsOneWidget);
  });
}
