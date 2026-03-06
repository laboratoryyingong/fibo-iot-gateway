import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/auth_tokens.dart';

class AuthUserTypeSelector extends StatelessWidget {
  const AuthUserTypeSelector({
    super.key,
    required this.isInstaller,
    required this.onChanged,
  });

  final bool isInstaller;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AuthTokens.selectorHeight,
      padding: const EdgeInsets.all(AuthTokens.selectorPadding),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.authTabBg,
        borderRadius: BorderRadius.circular(AuthTokens.tabRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RoleTab(
              active: !isInstaller,
              icon: Icons.person_outline_rounded,
              label: 'User',
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _RoleTab(
              active: isInstaller,
              icon: Icons.handyman_outlined,
              label: 'Installer',
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleTab extends StatelessWidget {
  const _RoleTab({
    required this.active,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool active;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AuthTokens.innerTabRadius),
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AuthTokens.innerTabRadius),
          color: active ? null : AppColors.authTabBg,
          gradient: active
              ? const LinearGradient(
                  begin: Alignment(-0.9, -1),
                  end: Alignment(0.9, 1),
                  colors: [AppColors.authButtonStart, AppColors.authButtonEnd],
                )
              : null,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: active
                    ? AppColors.authTextPrimary
                    : AppColors.authTextMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: active
                      ? AppColors.authTextPrimary
                      : AppColors.authTextMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
