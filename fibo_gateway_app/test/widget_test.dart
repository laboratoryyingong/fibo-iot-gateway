import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fibo_gateway_app/screens/forgot_password_screen.dart';
import 'package:fibo_gateway_app/screens/login_screen.dart';
import 'package:fibo_gateway_app/screens/signup_screen.dart';

void main() {
  testWidgets('Auth route smoke test: login -> signup', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
        },
      ),
    );

    expect(find.text('Welcome Back'), findsOneWidget);

    final signUpCta = find.widgetWithText(TextButton, 'Sign Up');
    await tester.ensureVisible(signUpCta);
    await tester.tap(signUpCta, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byType(SignUpScreen), findsOneWidget);
  });
}
