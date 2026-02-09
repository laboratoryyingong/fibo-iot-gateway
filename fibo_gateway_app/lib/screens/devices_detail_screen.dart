import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class DevicesDetailScreen extends StatelessWidget {
  const DevicesDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  children: const [
                    _PowerCard(),
                    SizedBox(height: 20),
                    _BrightnessCard(),
                    SizedBox(height: 20),
                    _ColorTemperatureCard(),
                    SizedBox(height: 20),
                    _DeviceInfoCard(),
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
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.arrow_back, size: 22, color: AppColors.foreground),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Living Room Light', style: AppTextStyles.heading20),
                  const SizedBox(height: 2),
                  Text('Living Room', style: AppTextStyles.body13Muted),
                ],
              ),
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

class _PowerCard extends StatelessWidget {
  const _PowerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(Icons.lightbulb, size: 40, color: AppColors.primaryForeground),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              Text('On', style: AppTextStyles.heading24),
              const SizedBox(height: 4),
              Text('80% brightness', style: AppTextStyles.body14Muted),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: 64,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 2),
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

class _BrightnessCard extends StatelessWidget {
  const _BrightnessCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.light_mode, size: 22, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text('Brightness', style: AppTextStyles.body14),
                ],
              ),
              Text('80%', style: AppTextStyles.body14.copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final fillWidth = constraints.maxWidth * 0.8;
              return Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    height: 8,
                    width: fillWidth,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ColorTemperatureCard extends StatelessWidget {
  const _ColorTemperatureCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.palette, size: 22, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text('Color Temperature', style: AppTextStyles.body14),
                ],
              ),
              Text('Warm White', style: AppTextStyles.body13Muted),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ColorSwatch(
                color: const Color(0xFFFFE4C4),
                selected: true,
              ),
              const SizedBox(width: 12),
              const _ColorSwatch(color: Color(0xFFFFFAF0)),
              const SizedBox(width: 12),
              const _ColorSwatch(color: Color(0xFFF0F8FF)),
              const SizedBox(width: 12),
              const _ColorSwatch(color: Color(0xFFE6F3FF)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.color, this.selected = false});

  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 2 : 1,
        ),
      ),
    );
  }
}

class _DeviceInfoCard extends StatelessWidget {
  const _DeviceInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.info, size: 22, color: AppColors.primary),
              const SizedBox(width: 10),
              Text('Device Information', style: AppTextStyles.body14),
            ],
          ),
          const SizedBox(height: 14),
          _InfoRow(label: 'Device ID', value: '0x00158d00...'),
          const SizedBox(height: 10),
          _InfoRow(label: 'Manufacturer', value: 'Philips'),
          const SizedBox(height: 10),
          _InfoRow(
            label: 'Signal',
            value: 'Strong',
            valueStyle: AppTextStyles.body14.copyWith(color: const Color(0xFF16A34A)),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.body13Muted),
        Text(value, style: valueStyle ?? AppTextStyles.body13Muted.copyWith(color: AppColors.foreground)),
      ],
    );
  }
}
