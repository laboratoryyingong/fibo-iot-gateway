import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import '../services/gateway_linking_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_background_image.dart';

/// Decides where to send the user on launch (login vs. home). No branded
/// landing page — it routes immediately, showing only a brief loading state
/// while the auth check resolves.
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
      child: const Scaffold(
        body: Stack(
          children: [
            AuthBackgroundImage(
              showImage: false,
              showGlowBlobs: true,
              overlayOpacity: 0,
            ),
            Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
