import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cfcs_mobile/main.dart';

void main() {
  testWidgets(
    'App launches successfully',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MyApp(isLoggedIn: false),
      );

      await tester.pumpAndSettle();

      expect(
        find.byType(MaterialApp),
        findsOneWidget,
      );
    },
  );
}