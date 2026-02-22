import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/devices_detail_screen.dart';
import 'screens/pairing_start_screen.dart';
import 'screens/pairing_searching_screen.dart';
import 'screens/pairing_device_found_screen.dart';
import 'screens/pairing_success_screen.dart';
import 'screens/scenes_add_action_screen.dart';
import 'screens/scenes_add_trigger_screen.dart';
import 'screens/scenes_detail_screen.dart';
import 'screens/scenes_select_device_screen.dart';
import 'screens/camera_add_nvr_screen.dart';
import 'screens/camera_list_screen.dart';
import 'screens/camera_live_view_screen.dart';
import 'screens/camera_nvr_channels_screen.dart';
import 'screens/camera_playback_screen.dart';
import 'screens/camera_settings_screen.dart';
import 'screens/user_device_detail_screen.dart';
import 'screens/user_home_shell.dart';
import 'services/parse_config.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Parse().initialize(
    AppParseConfig.appId,
    AppParseConfig.serverUrl,
    clientKey: AppParseConfig.clientKey,
    autoSendSessionId: true,
    debug: false,
  );
  runApp(const FiboGatewayApp());
}

class FiboGatewayApp extends StatelessWidget {
  const FiboGatewayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fibo Gateway',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/home': (context) => const HomeShell(),
        '/device-detail': (context) => const DevicesDetailScreen(),
        '/pairing/start': (context) => const PairingStartScreen(),
        '/pairing/searching': (context) => const PairingSearchingScreen(),
        '/pairing/found': (context) => const PairingDeviceFoundScreen(),
        '/pairing/success': (context) => const PairingSuccessScreen(),
        '/scenes/detail': (context) => const ScenesDetailScreen(),
        '/scenes/add-trigger': (context) => const ScenesAddTriggerScreen(),
        '/scenes/add-action': (context) => const ScenesAddActionScreen(),
        '/scenes/select-device': (context) => const ScenesSelectDeviceScreen(),
        '/camera/list': (context) => const CameraListScreen(),
        '/camera/live-view': (context) => const CameraLiveViewScreen(),
        '/camera/add-nvr': (context) => const CameraAddNvrScreen(),
        '/camera/nvr-channels': (context) => const CameraNvrChannelsScreen(),
        '/camera/playback': (context) => const CameraPlaybackScreen(),
        '/camera/settings': (context) => const CameraSettingsScreen(),
        '/user/home': (context) => const UserHomeShell(),
        '/user/device-detail': (context) => const UserDeviceDetailScreen(),
      },
    );
  }
}
