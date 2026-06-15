import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/gateway_binding_screen.dart';
import 'screens/gateway_detail_screen.dart';
import 'screens/gateway_discovery_screen.dart';
import 'screens/gateway_list_screen.dart';
import 'screens/gateway_onboarding_entry_screen.dart';
import 'screens/gateway_status_screen.dart';
import 'screens/home_profile_edit_screen.dart';
import 'screens/home_profile_home_screen.dart';
import 'screens/home_profile_members_screen.dart';
import 'screens/home_profile_menu_screen.dart';
import 'screens/account_password_screen.dart';
import 'screens/legal_terms_screen.dart';
import 'screens/login_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/support_contact_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/pairing_start_screen.dart';
import 'screens/pairing_searching_screen.dart';
import 'screens/pairing_device_found_screen.dart';
import 'screens/pairing_success_screen.dart';
import 'screens/scenes_add_action_screen.dart';
import 'screens/scenes_add_trigger_screen.dart';
import 'screens/scenes_detail_screen.dart';
import 'screens/scenes_editor_screen.dart';
import 'screens/scenes_list_screen.dart';
import 'screens/scenes_new_screen.dart';
import 'screens/scenes_select_device_screen.dart';
import 'screens/camera_add_nvr_screen.dart';
import 'screens/camera_list_screen.dart';
import 'screens/camera_live_view_screen.dart';
import 'screens/camera_nvr_channels_screen.dart';
import 'screens/camera_playback_screen.dart';
import 'screens/camera_settings_screen.dart';
import 'screens/assistant_screen.dart';
import 'screens/spaces_all_devices_screen.dart';
import 'screens/spaces_all_rooms_screen.dart';
import 'screens/spaces_device_control_screen.dart';
import 'screens/spaces_new_room_screen.dart';
import 'screens/spaces_overview_screen.dart';
import 'screens/spaces_room_detail_screen.dart';
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
        '/gateway/onboarding': (context) =>
            const GatewayOnboardingEntryScreen(),
        '/gateway/discovery': (context) => const GatewayDiscoveryScreen(),
        '/gateway/binding': (context) => const GatewayBindingScreen(),
        '/gateway/list': (context) => const GatewayListScreen(),
        '/gateway/detail': (context) => const GatewayDetailScreen(),
        '/gateway/status': (context) => const GatewayStatusScreen(),
        '/home': (context) => const HomeProfileHomeScreen(),
        '/home/profile': (context) => const HomeProfileHomeScreen(),
        '/home/profile/menu': (context) => const HomeProfileMenuScreen(),
        '/home/profile/edit': (context) => const HomeProfileEditScreen(),
        '/home/profile/members': (context) => const HomeProfileMembersScreen(),
        '/home/profile/settings': (context) => const SettingsScreen(),
        '/legal/terms': (context) => const LegalTermsScreen(),
        '/support/contact': (context) => const SupportContactScreen(),
        '/account/password': (context) => const AccountPasswordScreen(),
        '/home/scenes': (context) =>
            const ScenesListScreen(showSpacesBottomTabs: true),
        '/device-detail': (context) => const SpacesDeviceControlScreen(),
        '/pairing/start': (context) => const PairingStartScreen(),
        '/pairing/searching': (context) => const PairingSearchingScreen(),
        '/pairing/found': (context) => const PairingDeviceFoundScreen(),
        '/pairing/success': (context) => const PairingSuccessScreen(),
        '/scenes/new': (context) => const ScenesNewScreen(),
        '/scenes/editor': (context) => const ScenesEditorScreen(),
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
        '/user/home': (context) => const HomeProfileHomeScreen(),
        '/user/device-detail': (context) => const SpacesDeviceControlScreen(),
        '/spaces': (context) => const SpacesOverviewScreen(),
        '/spaces/devices': (context) => const SpacesAllDevicesScreen(),
        '/spaces/device-control': (context) =>
            const SpacesDeviceControlScreen(),
        '/spaces/new-room': (context) => const SpacesNewRoomScreen(),
        '/spaces/rooms': (context) => const SpacesAllRoomsScreen(),
        '/spaces/room-detail': (context) => const SpacesRoomDetailScreen(),
        '/assistant': (context) => const AssistantScreen(),
      },
    );
  }
}
