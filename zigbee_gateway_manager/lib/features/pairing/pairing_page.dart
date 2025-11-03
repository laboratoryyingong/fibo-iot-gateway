import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/mdns_discovery.dart';
import '../../data/providers.dart';
import '../../models/gateway_config.dart';

class PairingPage extends ConsumerStatefulWidget {
  const PairingPage({super.key});
  @override
  ConsumerState<PairingPage> createState() => _PairingPageState();
}

class _PairingPageState extends ConsumerState<PairingPage> {
  bool scanning = false;
  List<GatewayDiscoveryResult> found = [];

  Future<void> _discover() async {
    final items = await MdnsDiscovery().discover();
    setState(() => found = items);
  }

  void _applyConfig(GatewayConfig conf) {
    ref.read(gatewayConfigProvider.notifier).setConfig(conf);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _onQr(String raw) {
    try {
      if (raw.startsWith('zigbee://')) {
        final uri = Uri.parse(raw);
        final gwId = uri.queryParameters['gwId'] ?? 'gw-0001';
        final host = uri.queryParameters['host']!;
        final port = int.tryParse(uri.queryParameters['port'] ?? '') ?? 9001;
        final secure = (uri.queryParameters['secure'] ?? 'false') == 'true';
        final wsPath = uri.queryParameters['wsPath'] ?? '/mqtt';
        final user = uri.queryParameters['user'];
        final pass = uri.queryParameters['pass'];
        _applyConfig(
          GatewayConfig(
            gwId: gwId,
            host: host,
            port: port,
            secure: secure,
            useWebSocket: true,
            wsPath: wsPath,
            username: user,
            password: pass,
          ),
        );
        return;
      }
      final j = jsonDecode(raw);
      final conf = GatewayConfig.fromJson(Map<String, dynamic>.from(j));
      _applyConfig(conf);
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('无法解析二维码')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('连接网关')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '方式 A：mDNS 本地发现',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _discover,
            icon: const Icon(Icons.search),
            label: const Text('扫描局域网'),
          ),
          if (found.isNotEmpty) const SizedBox(height: 8),
          ...found.map(
            (e) => ListTile(
              title: Text('${e.host}:${e.port == 0 ? 9001 : e.port}'),
              subtitle: Text(e.service),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _applyConfig(
                  GatewayConfig(
                    gwId: 'gw-0001',
                    host: e.host,
                    port: e.port == 0 ? 9001 : e.port,
                    secure: false,
                    useWebSocket: true,
                    wsPath: '/mqtt',
                  ),
                );
              },
            ),
          ),

          const Divider(height: 32),

          const Text(
            '方式 B：二维码',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (!scanning)
            ElevatedButton.icon(
              onPressed: () => setState(() => scanning = true),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('开始扫描'),
            ),
          if (scanning)
            AspectRatio(
              aspectRatio: 1,
              child: MobileScanner(
                onDetect: (capture) {
                  final code = capture.barcodes.first.rawValue;
                  if (code != null) {
                    setState(() => scanning = false);
                    _onQr(code);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}
