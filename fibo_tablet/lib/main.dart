import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fibo_core/theme/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Control panel runs landscape-locked on a wall/desk tablet.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const FiboTabletApp());
}

class FiboTabletApp extends StatelessWidget {
  const FiboTabletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fibo Control',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      ),
      home: const HomeShellScreen(),
    );
  }
}

/// Placeholder shell for the landscape control hub. Phase 1 replaces the body
/// with the persistent sidebar (Home / Scenes / Assistant) + content pane.
class HomeShellScreen extends StatelessWidget {
  const HomeShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hub_outlined, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'Fibo Control',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tablet control hub — foundation ready',
              style: TextStyle(fontSize: 15, color: AppColors.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }
}
