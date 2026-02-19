import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class PairingSuccessScreen extends StatelessWidget {
  const PairingSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 64,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Device Paired Successfully!',
                  style: AppTextStyles.heading24,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your device is now connected to the Zigbee network and ready to use',
                  style: AppTextStyles.body15Muted,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.lightbulb,
                          size: 28,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Living Room Light',
                              style: AppTextStyles.body16,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Living Room',
                              style: AppTextStyles.body14Muted,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Online',
                                  style: AppTextStyles.body13Muted,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/device-detail'),
                    icon: const Icon(Icons.tune, size: 20),
                    label: const Text('Control Device'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/home', (route) => false),
                    child: const Text('Back to Home'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
