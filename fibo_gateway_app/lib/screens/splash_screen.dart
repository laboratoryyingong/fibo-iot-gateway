import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../services/user_role_resolver.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_background_image.dart';

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
            return Stack(
              children: [
                Container(color: AppColors.authBgBase),
                const AuthBackgroundImage(),
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
