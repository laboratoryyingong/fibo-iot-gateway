import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fibo_core/theme/space_tokens.dart';

import 'shell/app_shell.dart';

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
        fontFamily: 'Manrope',
        scaffoldBackgroundColor: SpaceColors.bgBase,
        colorScheme: ColorScheme.fromSeed(
          seedColor: SpaceColors.accentStart,
          brightness: Brightness.dark,
        ),
      ),
      home: const AppShell(),
    );
  }
}
