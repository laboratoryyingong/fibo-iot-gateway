import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers.dart';
import '../../models/device.dart';
import '../pairing/pairing_page.dart';
import 'device_detail_page.dart';

class DeviceListPage extends ConsumerWidget {
  const DeviceListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(deviceStoreProvider);
    final status = ref.watch(gatewayStatusProvider);

    final list = devices.values.toList()
      ..sort((a, b) => a.friendlyName.compareTo(b.friendlyName));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zigbee 设备'),
        actions: [
          IconButton(
            tooltip: '连接状态',
            icon: Icon(switch (status) {
              GatewayStatus.connected => Icons.cloud_done,
              GatewayStatus.connecting => Icons.cloud_upload,
              GatewayStatus.reconnecting => Icons.cloud_sync,
              GatewayStatus.disconnected => Icons.cloud_off,
            }),
            onPressed: () {},
          ),
          IconButton(
            tooltip: '重新选择网关',
            icon: const Icon(Icons.hub),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const PairingPage()));
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final c = ref.read(gatewayControllerProvider.notifier);
          c.setPermitJoin(true, timeout: 120);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已开启 Permit-Join，120 秒后自动关闭')),
          );
        },
        icon: const Icon(Icons.add_link),
        label: const Text('Permit-Join'),
      ),
      body: list.isEmpty
          ? const Center(child: Text('暂无设备（可点击右下角 Permit-Join 入网）'))
          : ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, i) => _DeviceTile(list[i]),
            ),
    );
  }
}

class _DeviceTile extends ConsumerWidget {
  final Device d;
  const _DeviceTile(this.d);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = (d.state['on'] ?? false) == true;
    return ListTile(
      title: Text(d.friendlyName),
      subtitle: Text('${d.type} • ${d.ieeeAddr} • ${d.online ? "在线" : "离线"}'),
      trailing: Switch(
        value: on,
        onChanged: (v) => ref
            .read(gatewayControllerProvider.notifier)
            .setOnOff(d.ieeeAddr, v),
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DeviceDetailPage(ieee: d.ieeeAddr)),
      ),
    );
  }
}
