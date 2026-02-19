import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ScenesSelectDeviceScreen extends StatelessWidget {
  const ScenesSelectDeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => Navigator.of(context).pop()),
            const _SearchBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                children: const [
                  _RoomLabel('Living Room'),
                  SizedBox(height: 8),
                  _DeviceCard(
                    devices: [
                      _DeviceRow(
                        icon: Icons.thermostat,
                        name: 'Temperature Sensor',
                        status: '24°C • Online',
                        selected: true,
                      ),
                      _DeviceRow(
                        icon: Icons.ac_unit,
                        name: 'Air Conditioner',
                        status: 'Off • Online',
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  _RoomLabel('Bedroom'),
                  SizedBox(height: 8),
                  _DeviceCard(
                    devices: [
                      _DeviceRow(
                        icon: Icons.lightbulb,
                        name: 'Bedroom Light',
                        status: 'On • 80% brightness',
                      ),
                      _DeviceRow(
                        icon: Icons.sensors,
                        name: 'Door Sensor',
                        status: 'Closed • Online',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _Footer(onConfirm: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 22,
                color: AppColors.foreground,
              ),
            ),
          ),
          Text(
            'Select Device',
            style: AppTextStyles.body16.copyWith(fontWeight: FontWeight.w600),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.notifications,
              size: 22,
              color: AppColors.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search,
              size: 20,
              color: AppColors.mutedForeground,
            ),
            const SizedBox(width: 10),
            Text('Search devices...', style: AppTextStyles.body14Muted),
          ],
        ),
      ),
    );
  }
}

class _RoomLabel extends StatelessWidget {
  const _RoomLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.body13Muted.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.devices});

  final List<Widget> devices;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          ...devices.asMap().entries.map((entry) {
            final index = entry.key;
            final widget = entry.value;
            return Column(
              children: [
                widget,
                if (index != devices.length - 1)
                  const Divider(height: 1, color: AppColors.border),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({
    required this.icon,
    required this.name,
    required this.status,
    this.selected = false,
  });

  final IconData icon;
  final String name;
  final String status;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.body14),
                const SizedBox(height: 3),
                Text(status, style: AppTextStyles.body13Muted),
              ],
            ),
          ),
          if (selected)
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.check,
                size: 14,
                color: AppColors.primaryForeground,
              ),
            )
          else
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
            ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.onConfirm});

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      color: AppColors.background,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onConfirm,
          child: const Text('Confirm Selection (1)'),
        ),
      ),
    );
  }
}
