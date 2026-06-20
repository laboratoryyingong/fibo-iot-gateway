import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fibo_tablet/main.dart';

void main() {
  testWidgets('Shell shows Home by default and switches panes on nav tap',
      (WidgetTester tester) async {
    // Landscape tablet surface — the control hub is designed for large screens.
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const FiboTabletApp());

    // Brand + default (Home) pane.
    expect(find.text('Fibo'), findsOneWidget);
    expect(
      find.text('Live rooms & devices arrive in the next phase.'),
      findsOneWidget,
    );

    // Tapping a sidebar destination swaps the visible content pane.
    await tester.tap(find.byKey(const ValueKey('nav-Scenes')));
    await tester.pumpAndSettle();
    expect(
      find.text('Tap-to-run scenes arrive in a later phase.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('nav-Assistant')));
    await tester.pumpAndSettle();
    expect(
      find.text('The AI control assistant arrives in a later phase.'),
      findsOneWidget,
    );
  });
}
