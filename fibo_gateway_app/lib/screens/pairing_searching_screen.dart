import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class PairingSearchingScreen extends StatelessWidget {
  const PairingSearchingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: 'Searching',
              onClose: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                child: Column(
                  children: [
                    _Radar(),
                    const SizedBox(height: 24),
                    Text(
                      'Searching for devices...',
                      style: AppTextStyles.heading24.copyWith(fontSize: 22),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Make sure your device is in pairing mode and close to the gateway',
                      style: AppTextStyles.body14Muted,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    _ProgressCard(),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/pairing/found'),
                        child: const Text('Simulate Device Found'),
                      ),
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
  const _Header({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(16),
            child: const Icon(
              Icons.close,
              size: 24,
              color: AppColors.foreground,
            ),
          ),
          Text(
            title,
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

class _Radar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 240,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.35),
            const Color(0xFFF97316).withValues(alpha: 0.2),
            Colors.transparent,
          ],
          stops: const [0.0, 0.3, 1.0],
        ),
      ),
      child: Center(
        child: Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.6),
              width: 2,
            ),
          ),
          child: Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
              child: const Icon(
                Icons.radar,
                size: 32,
                color: AppColors.primaryForeground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
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
          Text('Scanning Zigbee network...', style: AppTextStyles.body14Muted),
          const SizedBox(height: 12),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 180,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This may take up to 60 seconds',
            style: AppTextStyles.body13Muted,
          ),
        ],
      ),
    );
  }
}
