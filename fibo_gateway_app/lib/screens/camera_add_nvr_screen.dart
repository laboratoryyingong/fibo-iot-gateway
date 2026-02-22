import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class CameraAddNvrScreen extends StatelessWidget {
  const CameraAddNvrScreen({super.key});

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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  Text(
                    'Discover Zigbee NVR devices on your network',
                    style: AppTextStyles.body14Muted,
                  ),
                  const SizedBox(height: 20),
                  const _Label('Device Name'),
                  const SizedBox(height: 8),
                  const _InputField(hint: 'e.g. Living Room NVR'),
                  const SizedBox(height: 16),
                  const _Label('Zigbee Channel'),
                  const SizedBox(height: 8),
                  const _InputField(hint: 'Auto Detect'),
                  const SizedBox(height: 16),
                  const _Label('Device IEEE Address'),
                  const SizedBox(height: 8),
                  const _InputField(hint: 'Auto-discovered'),
                  const SizedBox(height: 16),
                  const _Label('Security Key (Optional)'),
                  const SizedBox(height: 8),
                  const _InputField(hint: '••••••••', obscureText: true),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/camera/nvr-channels'),
                    child: const Text('Scan & Connect'),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        'Manual pairing guide',
                        style: AppTextStyles.link14,
                      ),
                    ),
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
          Text('Add Zigbee NVR', style: AppTextStyles.heading20),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.body14.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({required this.hint, this.obscureText = false});

  final String hint;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscureText,
      decoration: InputDecoration(hintText: hint),
    );
  }
}
