import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Basic test to verify CI test runner works', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Hello')),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Hello'), findsOneWidget);
  });
}
