import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppMenuButton extends StatelessWidget {
  const AppMenuButton({
    super.key,
    this.userName = 'Admin',
    this.gatewayName = 'Zigbee Hub',
    this.onLogout,
  });

  final String userName;
  final String gatewayName;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: 'Menu',
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        PopupMenuItem<int>(
          value: 0,
          enabled: false,
          child: Row(
            children: [
              const Icon(Icons.person, size: 18, color: AppColors.foreground),
              const SizedBox(width: 10),
              Text('User: $userName', style: AppTextStyles.body14),
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
              Text('Gateway: $gatewayName', style: AppTextStyles.body14),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<int>(
          value: 2,
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
          onLogout?.call();
        }
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.menu, size: 22, color: AppColors.foreground),
      ),
    );
  }
}
