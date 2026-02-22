import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class CameraPlaybackScreen extends StatelessWidget {
  const CameraPlaybackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cameraDark,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => Navigator.of(context).pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                children: const [
                  _PlaybackVideo(),
                  SizedBox(height: 12),
                  _PlaybackControls(),
                  SizedBox(height: 12),
                  _TimelineCard(),
                  SizedBox(height: 12),
                  _DatePickerCard(),
                  SizedBox(height: 12),
                  _RecordingsCard(),
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
                color: AppColors.cameraOverlayWhite20,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 22,
                color: AppColors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Playback',
                  style: AppTextStyles.heading20.copyWith(
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Front Gate Camera',
                  style: AppTextStyles.body13Muted.copyWith(
                    color: AppColors.cameraTextFaint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaybackVideo extends StatelessWidget {
  const _PlaybackVideo();

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
                Icons.play_circle_fill,
                size: 62,
                color: AppColors.cameraTextFaint,
              ),
            ),
            Positioned(
              left: 12,
              top: 12,
              child: _Chip(
                text: 'PLAYBACK',
                color: AppColors.cameraOverlayBlack80,
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: _Chip(text: '1x', color: AppColors.cameraOverlayBlack80),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Text(
                '2024-01-15 09:30:00',
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

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
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

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _IconButton(icon: Icons.replay_10),
        const SizedBox(width: 14),
        _IconButton(icon: Icons.pause_circle_filled, active: true),
        const SizedBox(width: 14),
        _IconButton(icon: Icons.forward_10),
      ],
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, this.active = false});

  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: active ? 54 : 46,
      height: active ? 54 : 46,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.cameraOverlayWhite20,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: active ? 30 : 24, color: AppColors.white),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cameraDarkSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cameraOverlayWhite20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                '09:30:00',
                style: TextStyle(
                  color: AppColors.cameraTextFaint,
                  fontSize: 13,
                ),
              ),
              Text(
                '09:45:00',
                style: TextStyle(
                  color: AppColors.cameraTextFaint,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.55,
              minHeight: 8,
              backgroundColor: AppColors.cameraOverlayWhite30,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DatePickerCard extends StatelessWidget {
  const _DatePickerCard();

  @override
  Widget build(BuildContext context) {
    const labels = ['14', '15', '16', '17', '18', '19', '20'];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cameraDarkSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cameraOverlayWhite20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'January 2024',
            style: AppTextStyles.body14.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels.map((text) {
              final active = text == '15';
              return Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  border: active
                      ? null
                      : Border.all(color: AppColors.cameraOverlayWhite20),
                ),
                child: Text(
                  text,
                  style: AppTextStyles.body13Muted.copyWith(
                    color: active
                        ? AppColors.primaryForeground
                        : AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _RecordingsCard extends StatelessWidget {
  const _RecordingsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cameraDarkSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cameraOverlayWhite20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recordings on Jan 15',
            style: AppTextStyles.body14.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.cameraDarkPanel,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.motion_photos_on,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '09:30:00 - 09:45:00',
                      style: TextStyle(color: AppColors.white, fontSize: 14),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '15 min · Motion detected',
                      style: TextStyle(
                        color: AppColors.cameraTextHint,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
