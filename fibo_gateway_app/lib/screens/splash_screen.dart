import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../services/user_role_resolver.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    final currentUser = await ParseUser.currentUser() as ParseUser?;
    if (!mounted) return;

    if (currentUser != null) {
      final emailVerified = currentUser.get<bool>('emailVerified') ?? true;
      if (!emailVerified) {
        await currentUser.logout();
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }
      Navigator.of(context).pushReplacementNamed(resolveHomeRoute(currentUser));
      return;
    }

    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.authDark,
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            return Stack(
              children: [
                Container(color: AppColors.authBgBase),
                Positioned(
                  left: -width * 3.54,
                  top: height * 0.256,
                  child: Container(
                    width: width * 4.05,
                    height: height * 1.245,
                    decoration: const BoxDecoration(
                      color: AppColors.authAccentRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  left: width * 0.195,
                  top: height * 0.209,
                  child: Container(
                    width: width * 4.34,
                    height: height * 1.336,
                    decoration: const BoxDecoration(
                      color: AppColors.authAccentBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Align(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      const SizedBox(
                        width: 129,
                        height: 129,
                        child: Center(
                          child: Icon(
                            Icons.cell_tower_rounded,
                            size: 72,
                            color: AppColors.authTextPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Fibo Gateway',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
