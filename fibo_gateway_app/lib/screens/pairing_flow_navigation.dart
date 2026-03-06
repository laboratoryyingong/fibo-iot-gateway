import 'package:flutter/widgets.dart';

void dismissPairingFlow(
  BuildContext context, {
  String fallbackRoute = '/home',
}) {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.pop();
    return;
  }
  navigator.pushNamedAndRemoveUntil(fallbackRoute, (route) => false);
}
