import 'package:flutter/material.dart';
import 'package:fibo_core/theme/space_tokens.dart';

/// Connection state as a wifi glyph — green when the IoT shadow stream is up,
/// muted wifi-off otherwise. Shared across the header and the standby page.
class ConnectionIcon extends StatelessWidget {
  const ConnectionIcon({super.key, required this.connected, this.size = 24});

  final bool connected;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      connected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
      size: size,
      color: connected ? const Color(0xFF34D399) : SpaceColors.textMuted,
    );
  }
}
