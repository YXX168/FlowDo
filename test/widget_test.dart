import 'package:flowdo/widgets/animated_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('filter tab shows its label and count and handles taps',
      (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedFilterTab(
            label: '进行中',
            count: 3,
            isActive: true,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('进行中'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    await tester.tap(find.text('进行中'));
    expect(tapped, isTrue);
  });
}
