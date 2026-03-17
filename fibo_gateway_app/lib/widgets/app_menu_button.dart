import 'package:flutter/material.dart';

import '../services/gateway_linking_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_decorations.dart';

class AppMenuButton extends StatefulWidget {
  const AppMenuButton({
    super.key,
    this.userName = 'Admin',
    this.gatewayName,
    this.onLogout,
    this.onOpenGatewayCenter,
    this.onOpenCameraCenter,
    this.onOpenUserPortal,
  });

  final String userName;
  final String? gatewayName;
  final VoidCallback? onLogout;
  final VoidCallback? onOpenGatewayCenter;
  final VoidCallback? onOpenCameraCenter;
  final VoidCallback? onOpenUserPortal;

  @override
  State<AppMenuButton> createState() => _AppMenuButtonState();
}

class _AppMenuButtonState extends State<AppMenuButton> {
  String _gatewayName = 'Loading...';

  @override
  void initState() {
    super.initState();
    _hydrateGatewayName();
  }

  @override
  void didUpdateWidget(covariant AppMenuButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gatewayName != widget.gatewayName) {
      _hydrateGatewayName();
    }
  }

  Future<void> _hydrateGatewayName() async {
    if (widget.gatewayName != null) {
      _gatewayName = widget.gatewayName!;
      return;
    }

    final gateway = await GatewayLinkingService.getSelectedGateway();
    if (!mounted) return;
    setState(() => _gatewayName = gateway?.name ?? 'No Gateway');
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: 'Menu',
      offset: const Offset(0, 48),
      color: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) => [
        PopupMenuItem<int>(
          value: 0,
          enabled: false,
          child: Row(
            children: [
              const Icon(Icons.person, size: 18, color: AppColors.foreground),
              const SizedBox(width: 10),
              Text('User: ${widget.userName}', style: AppTextStyles.body14),
            ],
          ),
        ),
        PopupMenuItem<int>(
          value: 1,
          enabled: false,
          child: Row(
            children: [
              const Icon(Icons.hub, size: 18, color: AppColors.foreground),
              const SizedBox(width: 10),
              Text('Gateway: $_gatewayName', style: AppTextStyles.body14),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<int>(
          value: 2,
          child: Row(
            children: const [
              Icon(Icons.router, size: 18, color: AppColors.foreground),
              SizedBox(width: 10),
              Text('Gateway Center'),
            ],
          ),
        ),
        PopupMenuItem<int>(
          value: 3,
          child: Row(
            children: const [
              Icon(Icons.videocam, size: 18, color: AppColors.foreground),
              SizedBox(width: 10),
              Text('Camera Center'),
            ],
          ),
        ),
        PopupMenuItem<int>(
          value: 4,
          child: Row(
            children: const [
              Icon(Icons.person, size: 18, color: AppColors.foreground),
              SizedBox(width: 10),
              Text('User Portal'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<int>(
          value: 5,
          child: Row(
            children: const [
              Icon(Icons.logout, size: 18, color: AppColors.foreground),
              SizedBox(width: 10),
              Text('Logout'),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 2) {
          if (widget.onOpenGatewayCenter != null) {
            widget.onOpenGatewayCenter!.call();
          } else {
            Navigator.of(context).pushNamed(GatewayLinkingService.listRoute);
          }
          return;
        }
        if (value == 3) {
          if (widget.onOpenCameraCenter != null) {
            widget.onOpenCameraCenter!.call();
          } else {
            Navigator.of(context).pushNamed('/camera/list');
          }
          return;
        }
        if (value == 4) {
          if (widget.onOpenUserPortal != null) {
            widget.onOpenUserPortal!.call();
          } else {
            Navigator.of(context).pushNamed('/home');
          }
          return;
        }
        if (value == 5) {
          widget.onLogout?.call();
        }
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppDecorations.iconButtonShadow,
        ),
        child: const Icon(Icons.menu, size: 22, color: AppColors.foreground),
      ),
    );
  }
}
