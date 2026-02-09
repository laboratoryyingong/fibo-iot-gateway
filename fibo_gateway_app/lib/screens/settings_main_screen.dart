import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_menu_button.dart';

class SettingsMainScreen extends StatelessWidget {
  const SettingsMainScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final user = await ParseUser.currentUser() as ParseUser?;
    await user?.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onLogout: () => _handleLogout(context)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  children: const [
                    _SectionLabel('Gateway Configuration'),
                    _Card(
                      children: [
                        _RowItem(label: 'Gateway Name', value: 'Zigbee Hub', showDivider: true),
                        _RowItem(label: 'Channel', value: '15', showDivider: true),
                        _RowToggle(label: 'Permit Join', enabled: false),
                      ],
                    ),
                    SizedBox(height: 20),
                    _SectionLabel('Network Settings'),
                    _Card(
                      children: [
                        _RowItem(label: 'Power', value: 'High', showDivider: true),
                        _RowItem(label: 'LED Indicator', value: 'On', showDivider: true),
                        _RowItem(label: 'Firmware Update', value: 'Up to date'),
                      ],
                    ),
                    SizedBox(height: 20),
                    _SectionLabel('System Information'),
                    _Card(
                      children: [
                        _RowItem(label: 'Firmware', value: 'v1.2.4', showDivider: true),
                        _RowItem(label: 'MAC Address', value: '84:A2:3B:9C:11', showDivider: true),
                        _RowItem(label: 'Uptime', value: '14 days 6 hours'),
                      ],
                    ),
                    SizedBox(height: 20),
                    _SectionLabel('Danger Zone', color: Color(0xFFEF4444)),
                    _DangerCard(
                      children: [
                        _RowItem(
                          label: 'Restart Gateway',
                          value: 'Reboot now',
                          showDivider: true,
                          valueColor: Color(0xFFEF4444),
                        ),
                        _RowItem(
                          label: 'Factory Reset',
                          value: 'Erase all data',
                          valueColor: Color(0xFFEF4444),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              AppMenuButton(onLogout: onLogout),
              const SizedBox(width: 16),
              Text('Settings', style: AppTextStyles.heading20),
            ],
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.notifications, size: 22, color: AppColors.foreground),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.color = AppColors.mutedForeground});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: AppTextStyles.body13Muted.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(children: children),
    );
  }
}

class _DangerCard extends StatelessWidget {
  const _DangerCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEF4444), width: 1),
      ),
      child: Column(children: children),
    );
  }
}

class _RowItem extends StatelessWidget {
  const _RowItem({
    required this.label,
    required this.value,
    this.showDivider = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool showDivider;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTextStyles.body14),
              Text(
                value,
                style: AppTextStyles.body14.copyWith(color: valueColor ?? AppColors.mutedForeground),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}

class _RowToggle extends StatelessWidget {
  const _RowToggle({required this.label, required this.enabled});

  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body14),
          Container(
            width: 48,
            height: 28,
            decoration: BoxDecoration(
              color: enabled ? AppColors.primary : AppColors.secondary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Align(
              alignment: enabled ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: const BoxDecoration(
                  color: AppColors.card,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
