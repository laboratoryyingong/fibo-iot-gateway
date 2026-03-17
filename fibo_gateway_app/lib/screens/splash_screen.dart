import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import '../services/gateway_linking_service.dart';
import '../theme/app_theme.dart';
import '../theme/auth_tokens.dart';
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
      final nextRoute = await GatewayLinkingService.resolvePostAuthRoute(
        currentUser,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(nextRoute);
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
            final widthScale = constraints.maxWidth / AuthTokens.designWidth;
            final heightScale = constraints.maxHeight / AuthTokens.designHeight;
            final iconScale = widthScale < heightScale
                ? widthScale
                : heightScale;

            return Stack(
              children: [
                const AuthBackgroundImage(
                  showImage: false,
                  showGlowBlobs: true,
                  overlayOpacity: 0,
                ),
                Positioned(
                  left: 123 * widthScale,
                  top: 342 * heightScale,
                  width: 129 * widthScale,
                  height: 129 * heightScale,
                  child: Center(
                    child: Icon(
                      Icons.cell_tower_rounded,
                      size: 72 * iconScale,
                      color: Colors.white,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 487 * heightScale,
                  child: const Center(
                    child: Text('Fibo Gateway', style: AuthTextStyles.title),
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
