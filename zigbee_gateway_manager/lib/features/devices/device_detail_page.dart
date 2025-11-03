import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers.dart';
import '../../models/device.dart';

class DeviceDetailPage extends ConsumerWidget {
  final String ieee;
  const DeviceDetailPage({super.key, required this.ieee});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dev = ref.watch(deviceStoreProvider.select((m) => m[ieee]));
    if (dev == null) {
      return Scaffold(
        appBar: AppBar(title: Text(ieee)),
        body: const Center(child: Text('设备不存在')),
      );
    }
    final on = (dev.state['on'] ?? false) == true;
    final brightness = (dev.state['brightness'] ?? 0) as int;
    final colorTemp = (dev.state['color_temp'] ?? 0) as int;

    return Scaffold(
      appBar: AppBar(title: Text(dev.friendlyName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Text(
                '电源',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Switch(
                value: on,
                onChanged: (v) => ref
                    .read(gatewayControllerProvider.notifier)
                    .setOnOff(ieee, v),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (dev.supports.contains('brightness') ||
              dev.state.containsKey('brightness')) ...[
            Text(
              '亮度 $brightness',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Slider(
              value: (brightness == 0 ? 1 : brightness).toDouble(),
              min: 1,
              max: 254,
              divisions: 253,
              label: '$brightness',
              onChanged: (v) => ref
                  .read(gatewayControllerProvider.notifier)
                  .setBrightness(ieee, v.toInt()),
            ),
            const SizedBox(height: 12),
          ],

          if (dev.supports.contains('color_temp') ||
              dev.state.containsKey('color_temp')) ...[
            Text(
              '色温（mired） $colorTemp',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Slider(
              value: (colorTemp == 0 ? 350 : colorTemp).toDouble(),
              min: 150,
              max: 500,
              divisions: 350,
              label: '$colorTemp',
              onChanged: (v) => ref
                  .read(gatewayControllerProvider.notifier)
                  .setColorTemp(ieee, v.toInt()),
            ),
            const SizedBox(height: 12),
          ],

          const Divider(),

          const Text(
            '传感器',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _sensorTile('温度', dev.state['temperature'], suffix: '°C'),
          _sensorTile('湿度', dev.state['humidity'], suffix: '%'),
          _sensorTile('电量', dev.state['battery'], suffix: '%'),
          _sensorTile('信号', dev.state['linkquality']),
        ],
      ),
    );
  }

  Widget _sensorTile(String name, Object? v, {String suffix = ''}) {
    return ListTile(
      dense: true,
      title: Text(name),
      trailing: Text(v == null ? '-' : '$v$suffix'),
    );
  }
}
