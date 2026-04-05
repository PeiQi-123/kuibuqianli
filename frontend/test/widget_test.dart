// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_exercise_frontend/widgets/custom_button.dart';

import 'package:micro_exercise_frontend/app/app.dart'; // 修改导入路径

void main() {
  testWidgets('CustomButton triggers callback when enabled', (WidgetTester tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(
            text: 'Start',
            onPressed: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Start'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('CustomButton shows loading indicator and disables tap', (WidgetTester tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(
            text: 'Submit',
            isLoading: true,
            onPressed: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Submit'), findsNothing);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(tapped, isFalse);
  });
}
