import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fibo_tablet/screens/login_screen.dart';

void main() {
  testWidgets('Login screen renders the brand, fields and sign-in action',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('Fibo Control'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));

    // Submitting empty fields surfaces a validation message (no backend call).
    await tester.tap(find.text('Sign In'));
    await tester.pump();
    expect(find.text('Enter your email and password.'), findsOneWidget);
  });
}
