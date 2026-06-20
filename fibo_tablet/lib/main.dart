import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:fibo_core/services/parse_config.dart';
import 'package:fibo_core/theme/space_tokens.dart';

import 'screens/login_screen.dart';
import 'shell/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Control panel runs landscape-locked on a wall/desk tablet.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await Parse().initialize(
    AppParseConfig.appId,
    AppParseConfig.serverUrl,
    clientKey: AppParseConfig.clientKey,
    autoSendSessionId: true,
    debug: false,
  );
  runApp(const FiboTabletApp());
}

class FiboTabletApp extends StatelessWidget {
  const FiboTabletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FIBO Control',
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
      home: const AuthGate(),
    );
  }
}

/// Sends the user to the control hub if a Parse session is already persisted,
/// otherwise to the login screen.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ParseUser?>(
      future: ParseUser.currentUser().then((u) => u as ParseUser?),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: SpaceColors.accentStart),
            ),
          );
        }
        return snapshot.data != null ? const AppShell() : const LoginScreen();
      },
    );
  }
}
