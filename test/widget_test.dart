// Basic widget test for app bootstrap.

import 'package:flutter_test/flutter_test.dart';

import 'package:summary_global/app/app.dart';

void main() {
  testWidgets('app renders login flow', (WidgetTester tester) async {
    await tester.pumpWidget(const SummaryApp(initialLocation: '/login'));
    expect(find.text('Summary Report Cafe'), findsOneWidget);
  });
}
