import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Basic UI Smoke Test', (WidgetTester tester) async {
    // Pump a minimal test widget
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('LankaLink'),
          ),
        ),
      ),
    );

    // Verify the text is rendered
    expect(find.text('LankaLink'), findsOneWidget);
  });
}