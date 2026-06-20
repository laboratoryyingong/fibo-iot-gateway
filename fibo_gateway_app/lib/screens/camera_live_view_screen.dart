import 'package:flutter/material.dart';
import 'package:fibo_core/theme/app_colors.dart';
import 'package:fibo_core/theme/app_text_styles.dart';

class CameraLiveViewScreen extends StatelessWidget {
  const CameraLiveViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cameraDark,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onBack: () => Navigator.of(context).pop(),
              onSettings: () =>
                  Navigator.of(context).pushNamed('/camera/settings'),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                children: [
                  const _VideoArea(),
                  const SizedBox(height: 12),
                  _Controls(
                    onPlayback: () =>
                        Navigator.of(context).pushNamed('/camera/playback'),
                  ),
                  const SizedBox(height: 16),
                  const _InfoCard(),
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
  const _Header({required this.onBack, required this.onSettings});

  final VoidCallback onBack;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        children: [
          _RoundIcon(icon: Icons.arrow_back, onTap: onBack),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Front Gate Camera',
                  style: AppTextStyles.heading20.copyWith(
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'NVR-1 · Channel 1',
                  style: AppTextStyles.body13Muted.copyWith(
                    color: AppColors.cameraTextFaint,
                  ),
                ),
              ],
            ),
          ),
          _RoundIcon(icon: Icons.settings, onTap: onSettings),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.cameraOverlayWhite20,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, size: 22, color: AppColors.white),
      ),
    );
  }
}

class _VideoArea extends StatelessWidget {
  const _VideoArea();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cameraDarkSurface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            const Center(
              child: Icon(
                Icons.videocam,
                size: 64,
                color: AppColors.cameraTextFaint,
              ),
            ),
            Positioned(
              left: 12,
              top: 12,
              child: _Badge(text: 'LIVE', color: AppColors.dangerStrong),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: _Badge(
                text: '1080p',
                color: AppColors.cameraOverlayBlack80,
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Text(
                '2024-01-15 14:32:45',
                style: AppTextStyles.body13Muted.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: AppTextStyles.body13Muted.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.onPlayback});

  final VoidCallback onPlayback;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ControlButton(
            icon: Icons.photo_camera,
            text: 'Snapshot',
            backgroundColor: AppColors.cameraOverlayWhite20,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ControlButton(
            icon: Icons.fiber_manual_record,
            text: 'Record',
            backgroundColor: AppColors.dangerStrong,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ControlButton(
            icon: Icons.play_arrow,
            text: 'Playback',
            backgroundColor: AppColors.cameraOverlayWhite20,
            onTap: onPlayback,
          ),
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.text,
    required this.onTap,
    required this.backgroundColor,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppColors.white),
            const SizedBox(height: 6),
            Text(
              text,
              style: AppTextStyles.body13Muted.copyWith(
                color: AppColors.cameraTextFaint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cameraDarkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cameraOverlayWhite20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _CardTitle('Camera Information'),
          _InfoRow(label: 'Device ID', value: 'DS-2CD2T47G2P...'),
          Divider(height: 1, color: AppColors.cameraOverlayWhite20),
          _InfoRow(label: 'Resolution', value: '1920 × 1080'),
          Divider(height: 1, color: AppColors.cameraOverlayWhite20),
          _InfoRow(label: 'Bitrate', value: '4096 Kbps'),
        ],
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Text(
        text,
        style: AppTextStyles.body14.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
      ),
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
          Text(
            label,
            style: AppTextStyles.body14.copyWith(
              color: AppColors.cameraTextHint,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.body14.copyWith(color: AppColors.white),
          ),
        ],
      ),
    );
  }
}
