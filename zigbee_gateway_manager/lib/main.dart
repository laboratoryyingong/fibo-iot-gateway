import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/providers.dart';
import 'features/pairing/pairing_page.dart';
import 'features/devices/device_list_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final box = await Hive.openBox('app');

  runApp(
    ProviderScope(
      overrides: [hiveBoxProvider.overrideWithValue(box)],
      child: const App(),
    ),
  );
}

class App extends ConsumerWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conf = ref.watch(gatewayConfigProvider);
    // 只要有配置就会触发连接/订阅逻辑
    ref.watch(gatewayControllerProvider);

    return MaterialApp(
      title: 'Zigbee Gateway',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: conf == null ? const PairingPage() : const DeviceListPage(),
    );
  }
}
