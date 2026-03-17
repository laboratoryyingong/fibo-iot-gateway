import 'package:flutter/material.dart';

import '../services/gateway_linking_service.dart';
import '../theme/app_colors.dart';
import '../theme/pairing_tokens.dart';

class GatewayInfoCard extends StatelessWidget {
  const GatewayInfoCard({
    super.key,
    required this.gateway,
    this.highlighted = false,
    this.trailing,
    this.onTap,
    this.padding = const EdgeInsets.fromLTRB(14, 12, 14, 12),
    this.showLocation = false,
  });

  final GatewayProfile gateway;
  final bool highlighted;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool showLocation;

  @override
  Widget build(BuildContext context) {
    final background = highlighted
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [PairingTokens.accentPrimary, PairingTokens.accentEnd],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [PairingTokens.bgElevated, PairingTokens.bgSurface],
          );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: background,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: highlighted
                    ? const Color(0x22FFFFFF)
                    : const Color(0xFF7773FA).withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.router_outlined,
                size: 22,
                color: highlighted
                    ? PairingTokens.textPrimary
                    : PairingTokens.accentPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gateway.name,
                    style: PairingTextStyles.captionBold.copyWith(
                      fontSize: 13,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle(),
                    style: PairingTextStyles.small.copyWith(
                      color: highlighted
                          ? AppColors.authTextPrimary.withValues(alpha: 0.72)
                          : PairingTokens.textMuted,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing ??
                GatewayStatusBadge(gateway: gateway, highlighted: highlighted),
          ],
        ),
      ),
    );
  }

  String _subtitle() {
    if (showLocation &&
        gateway.location != null &&
        gateway.location!.isNotEmpty) {
      return '${gateway.serialNumber} · ${gateway.location}';
    }
    return 'SN: ${gateway.serialNumber}';
  }
}

class GatewayStatusBadge extends StatelessWidget {
  const GatewayStatusBadge({
    super.key,
    required this.gateway,
    this.highlighted = false,
  });

  final GatewayProfile gateway;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final color = switch (gateway.connectionState) {
      GatewayConnectionState.online => const Color(0xFF59D08A),
      GatewayConnectionState.offline => PairingTokens.textMuted,
      GatewayConnectionState.updating => const Color(0xFFF4B740),
      GatewayConnectionState.error => const Color(0xFFF56A6A),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlighted
            ? const Color(0x22FFFFFF)
            : color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 4),
          Text(
            gateway.statusLabel,
            style: PairingTextStyles.small.copyWith(
              color: highlighted ? PairingTokens.textPrimary : color,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
