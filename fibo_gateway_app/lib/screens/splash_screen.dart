import 'dart:async';

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.router,
                size: 64,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: 24),
            Text('Fibo Gateway', style: AppTextStyles.heading32),
            const SizedBox(height: 8),
            Text('Smart Home Control', style: AppTextStyles.body15Muted),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _LoaderDot(active: true),
                SizedBox(width: 8),
                _LoaderDot(),
                SizedBox(width: 8),
                _LoaderDot(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LoaderDot extends StatelessWidget {
  const _LoaderDot({this.active = false});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.mutedForeground,
        shape: BoxShape.circle,
      ),
    );
  }
}
