import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class CameraNvrChannelsScreen extends StatelessWidget {
  const CameraNvrChannelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => Navigator.of(context).pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                children: [
                  const _NvrInfo(),
                  const SizedBox(height: 12),
                  _ChannelCard(
                    title: 'CH1 - Front Gate',
                    subtitle: '1080p · 30fps',
                    live: true,
                    dark: true,
                    cardColor: AppColors.cameraDarkSurface,
                    onTap: () =>
                        Navigator.of(context).pushNamed('/camera/live-view'),
                  ),
                  const SizedBox(height: 10),
                  _ChannelCard(
                    title: 'CH2 - Backyard',
                    subtitle: '1080p · 30fps',
                    live: true,
                    dark: true,
                    cardColor: AppColors.cameraDarkPanel,
                    onTap: () =>
                        Navigator.of(context).pushNamed('/camera/live-view'),
                  ),
                  const SizedBox(height: 10),
                  _ChannelCard(
                    title: 'CH3 - Garage',
                    subtitle: '1080p · 30fps',
                    live: true,
                    dark: true,
                    cardColor: AppColors.cameraDarkSoft,
                    onTap: () =>
                        Navigator.of(context).pushNamed('/camera/live-view'),
                  ),
                  const SizedBox(height: 10),
                  const _ChannelCard(
                    title: 'CH4 - Side Door',
                    subtitle: 'Connection lost',
                    live: false,
                    dark: false,
                    cardColor: AppColors.secondary,
                  ),
                  const SizedBox(height: 16),
                  _RecordingStatusSection(
                    onViewAll: () =>
                        Navigator.of(context).pushNamed('/camera/playback'),
                  ),
                ],
              ),
            ),
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
        children: [
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.arrow_back, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Zigbee NVR-1', style: AppTextStyles.heading20),
                const SizedBox(height: 2),
                Text('4 channels available', style: AppTextStyles.body13Muted),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed('/camera/settings'),
              icon: const Icon(Icons.settings, size: 20),
              splashRadius: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _NvrInfo extends StatelessWidget {
  const _NvrInfo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.successStrong,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Connected · Zigbee Ch.15 · 0x00158D0001A2B3C4',
            style: AppTextStyles.body13Muted,
          ),
        ],
      ),
    );
  }
}

class _ChannelCard extends StatelessWidget {
  const _ChannelCard({
    required this.title,
    required this.subtitle,
    required this.live,
    this.dark = false,
    this.cardColor = AppColors.card,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final bool live;
  final bool dark;
  final Color cardColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final titleColor = dark ? AppColors.white : AppColors.foreground;
    final subtitleColor = dark
        ? AppColors.cameraTextFaint
        : AppColors.mutedForeground;
    final borderColor = dark
        ? AppColors.cameraOverlayWhite20
        : AppColors.border;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: dark ? AppColors.cameraOverlayWhite20 : AppColors.card,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                live ? Icons.videocam : Icons.videocam_off,
                color: dark ? AppColors.white : AppColors.mutedForeground,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body14.copyWith(color: titleColor),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppTextStyles.body13Muted.copyWith(
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            dark
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.dangerStrong,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'LIVE',
                      style: AppTextStyles.body13Muted.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.chevron_right,
                    color: AppColors.mutedForeground,
                  ),
          ],
        ),
      ),
    );
  }
}

class _RecordingStatusSection extends StatelessWidget {
  const _RecordingStatusSection({required this.onViewAll});

  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recording Status',
              style: AppTextStyles.body14.copyWith(fontWeight: FontWeight.w600),
            ),
            TextButton(onPressed: onViewAll, child: const Text('View All')),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: const [
              _InfoRow(label: 'Storage Used', value: '1.2 TB / 4 TB'),
              Divider(height: 1, color: AppColors.border),
              _ProgressRow(progress: 0.3),
              Divider(height: 1, color: AppColors.border),
              _InfoRow(label: 'Recording Mode', value: 'Continuous'),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body13Muted),
          Text(value, style: AppTextStyles.body14),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 8,
          backgroundColor: AppColors.secondary,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }
}
