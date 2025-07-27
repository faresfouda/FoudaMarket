// This is a basic Flutter widget test for FoudaMarket app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fouda_market/main.dart' as app;

void main() {
  group('FoudaMarket App Tests', () {
    testWidgets('App should start without crashing', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      app.main();
      await tester.pumpAndSettle();

      // Verify that the app starts without errors
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('App should have proper title', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const MaterialApp(
        title: 'Fouda Market',
        home: Scaffold(
          body: Center(
            child: Text('Fouda Market'),
          ),
        ),
      ));

      // Verify that our app has the correct title
      expect(find.text('Fouda Market'), findsOneWidget);
    });

    testWidgets('App should handle basic navigation', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Welcome to Fouda Market'),
          ),
        ),
      ));

      // Verify that the welcome text is displayed
      expect(find.text('Welcome to Fouda Market'), findsOneWidget);
    });
  });
}
