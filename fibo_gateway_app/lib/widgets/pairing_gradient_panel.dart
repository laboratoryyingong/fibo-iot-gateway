import 'package:flutter/material.dart';

import 'package:fibo_core/theme/pairing_tokens.dart';

class PairingGradientPanel extends StatelessWidget {
  const PairingGradientPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 8),
    this.borderRadius = PairingTokens.radiusLg,
    this.width,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [PairingTokens.bgElevated, PairingTokens.bgSurface],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: child,
    );
  }
}
