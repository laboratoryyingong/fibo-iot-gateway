import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fibo_tablet/main.dart';

void main() {
  testWidgets('Control hub shell renders', (WidgetTester tester) async {
    await tester.pumpWidget(const FiboTabletApp());
    expect(find.text('Fibo Control'), findsOneWidget);
    expect(find.byIcon(Icons.hub_outlined), findsOneWidget);
  });
}
