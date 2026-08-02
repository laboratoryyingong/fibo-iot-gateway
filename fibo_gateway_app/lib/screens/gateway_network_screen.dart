import 'package:flutter/material.dart';

import 'package:fibo_core/services/hub_provisioning/hub_provisioning.dart';
import 'package:fibo_core/theme/pairing_tokens.dart';
import '../widgets/gateway_dark_header.dart';
import '../widgets/pairing_action_button.dart';
import 'gateway_provisioning_flow.dart';

/// Network step of hub provisioning: shows the active uplink, configures
/// Ethernet (DHCP/static, `hub-net`) and the 2.4 GHz WiFi fallback
/// (`hub-wifi`), and — when reconfiguring — offers factory reset.
class GatewayNetworkScreen extends StatefulWidget {
  const GatewayNetworkScreen({super.key});

  @override
  State<GatewayNetworkScreen> createState() => _GatewayNetworkScreenState();
}

class _GatewayNetworkScreenState extends State<GatewayNetworkScreen> {
  HubProvisioningFlow? _flow;
  HubNetConfig? _netConfig;
  HubWifiStatus? _wifiStatus;
  bool _refreshing = false;
  bool _busy = false;

  HubProvisioningSession get _session => _flow!.session!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_flow != null) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is HubProvisioningFlow) {
      _flow = args;
      _refresh();
    }
  }

  @override
  void dispose() {
    final flow = _flow;
    if (flow != null && !flow.completed) {
      // Leaving the flow without finishing: drop the BLE session.
      flow.close();
    }
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      final info = await _session.readInfo();
      final net = await _session.readNetConfig();
      final wifi = await _session.readWifiStatus();
      if (!mounted) return;
      setState(() {
        _flow!.info = info;
        _netConfig = net;
        _wifiStatus = wifi;
      });
    } catch (e) {
      if (!mounted) return;
      _showError('Could not read hub status: $e');
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _runHubAction(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) await _refresh();
    } on HubEndpointException catch (e) {
      if (mounted) _showError('Hub rejected the change (${e.status})');
    } catch (e) {
      if (mounted) _showError('Failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _editStaticIp() async {
    final config = await showModalBottomSheet<_StaticIpConfig>(
      context: context,
      isScrollControlled: true,
      backgroundColor: PairingTokens.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _StaticIpSheet(initial: _netConfig),
    );
    if (config == null) return;
    await _runHubAction(
      () => _session.writeNetStatic(
        ip: config.ip,
        netmask: config.netmask,
        gateway: config.gateway,
        dns: config.dns,
      ),
    );
  }

  Future<void> _editWifi() async {
    final credentials = await showModalBottomSheet<_WifiCredentials>(
      context: context,
      isScrollControlled: true,
      backgroundColor: PairingTokens.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _WifiSheet(initialSsid: _wifiStatus?.ssid),
    );
    if (credentials == null) return;
    await _runHubAction(
      () => _session.writeWifiCredentials(
        ssid: credentials.ssid,
        password: credentials.password,
      ),
    );
  }

  Future<void> _factoryReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PairingTokens.bgSurface,
        title: Text(
          'Factory Reset?',
          style: PairingTextStyles.headline.copyWith(fontSize: 18),
        ),
        content: Text(
          'This clears the account binding, network settings, and WiFi '
          'credentials. The hub reboots and can be set up again with the '
          'same QR label.',
          style: PairingTextStyles.caption.copyWith(
            color: PairingTokens.textMuted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Reset',
              style: TextStyle(color: Color(0xFFFF6B6B)),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final flow = _flow!;
    setState(() => _busy = true);
    try {
      await _session.factoryReset();
      flow.completed = true;
      await flow.close();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hub is rebooting — it can now be set up again.'),
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showError('Factory reset failed: $e');
    }
  }

  Future<void> _finishReconfigure() async {
    final flow = _flow!;
    flow.completed = true;
    await flow.close();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _continueToBinding() {
    final info = _flow!.info;
    if (info == null || !info.isOnline) {
      _showError(
        'The hub has no network link yet — connect the cable or set up WiFi '
        'first.',
      );
      return;
    }
    Navigator.of(context).pushNamed('/gateway/binding', arguments: _flow);
  }

  @override
  Widget build(BuildContext context) {
    final flow = _flow;
    final info = flow?.info;

    return Scaffold(
      backgroundColor: PairingTokens.bgBase,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            GatewayDarkHeader(
              title: 'Hub Network',
              onLeadingTap: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                color: PairingTokens.accentPrimary,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  children: [
                    if (info != null) _UplinkCard(info: info),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Ethernet',
                      subtitle: _netConfig == null
                          ? 'Reading...'
                          : _netConfig!.isStatic
                          ? 'Static · ${_netConfig!.ip ?? '-'}'
                          : 'DHCP (automatic) · ${_netConfig!.activeIp}',
                      children: [
                        _InlineAction(
                          label: 'Set Static IP',
                          icon: Icons.lan_outlined,
                          onTap: _busy ? null : _editStaticIp,
                        ),
                        if (_netConfig?.isStatic ?? false)
                          _InlineAction(
                            label: 'Switch to DHCP',
                            icon: Icons.autorenew,
                            onTap: _busy
                                ? null
                                : () =>
                                      _runHubAction(_session.writeNetDhcp),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Backup WiFi',
                      subtitle: _wifiStatus == null
                          ? 'Reading...'
                          : _wifiStatus!.configured
                          ? '${_wifiStatus!.ssid} · used if the cable is '
                                'unplugged'
                          : 'Not set — the hub goes offline if the cable is '
                                'unplugged',
                      children: [
                        _InlineAction(
                          label: _wifiStatus?.configured ?? false
                              ? 'Change Network'
                              : 'Add WiFi Network',
                          icon: Icons.wifi,
                          onTap: _busy ? null : _editWifi,
                        ),
                        if (_wifiStatus?.configured ?? false)
                          _InlineAction(
                            label: 'Forget Network',
                            icon: Icons.wifi_off_outlined,
                            onTap: _busy
                                ? null
                                : () => _runHubAction(
                                      _session.clearWifiCredentials,
                                    ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '2.4 GHz networks only. The hub always prefers the '
                        'network cable and falls back to WiFi automatically.',
                        style: PairingTextStyles.small.copyWith(
                          color: PairingTokens.textMuted,
                        ),
                      ),
                    ),
                    if (flow?.reconfigure ?? false) ...[
                      const SizedBox(height: 24),
                      _InlineAction(
                        label: 'Factory Reset Hub',
                        icon: Icons.restart_alt,
                        destructive: true,
                        onTap: _busy ? null : _factoryReset,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: PairingActionButton(
                text: flow?.reconfigure ?? false
                    ? 'Done'
                    : _busy || _refreshing
                    ? 'Working...'
                    : 'Continue',
                onPressed: flow == null
                    ? () {}
                    : flow.reconfigure
                    ? _finishReconfigure
                    : _continueToBinding,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UplinkCard extends StatelessWidget {
  const _UplinkCard({required this.info});

  final HubInfo info;

  @override
  Widget build(BuildContext context) {
    final (icon, label, detail) = switch (info.uplink) {
      HubUplink.eth => (
        Icons.cloud_done_outlined,
        'Online via Ethernet',
        info.ethIp,
      ),
      HubUplink.wifi => (
        Icons.cloud_done_outlined,
        'Online via WiFi fallback',
        'Ethernet is down',
      ),
      HubUplink.none when info.ethLinkWithoutIp => (
        Icons.cloud_off_outlined,
        'Cable OK, no IP address',
        'Router gave no address — set a static IP below',
      ),
      HubUplink.none => (
        Icons.cloud_off_outlined,
        'No network link',
        'Connect the cable or add WiFi below',
      ),
    };
    final window = info.provWindowSeconds;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [PairingTokens.bgElevated, PairingTokens.bgSurface],
        ),
        borderRadius: BorderRadius.circular(PairingTokens.radiusLg),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 32,
            color: info.isOnline
                ? PairingTokens.accentPrimary
                : const Color(0xFFFFB74D),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: PairingTextStyles.bodyBold),
                const SizedBox(height: 4),
                Text(
                  '$detail · fw ${info.firmwareVersion}',
                  style: PairingTextStyles.small.copyWith(
                    color: PairingTokens.textMuted,
                  ),
                ),
                if (window != null && window >= 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Setup window closes in '
                    '${window ~/ 60}:${(window % 60).toString().padLeft(2, '0')}',
                    style: PairingTextStyles.small.copyWith(
                      color: const Color(0xFFFFB74D),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PairingTokens.bgSurface,
        borderRadius: BorderRadius.circular(PairingTokens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: PairingTextStyles.bodyBold),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: PairingTextStyles.small.copyWith(
              color: PairingTokens.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InlineAction extends StatelessWidget {
  const _InlineAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? const Color(0xFFFF6B6B)
        : PairingTokens.accentPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(PairingTokens.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Text(
              label,
              style: PairingTextStyles.caption.copyWith(
                color: onTap == null ? PairingTokens.textMuted : color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaticIpConfig {
  const _StaticIpConfig(this.ip, this.netmask, this.gateway, this.dns);

  final String ip;
  final String netmask;
  final String gateway;
  final String? dns;
}

class _StaticIpSheet extends StatefulWidget {
  const _StaticIpSheet({this.initial});

  final HubNetConfig? initial;

  @override
  State<_StaticIpSheet> createState() => _StaticIpSheetState();
}

class _StaticIpSheetState extends State<_StaticIpSheet> {
  late final _ip = TextEditingController(text: widget.initial?.ip ?? '');
  late final _netmask = TextEditingController(
    text: widget.initial?.netmask ?? '255.255.255.0',
  );
  late final _gateway = TextEditingController(
    text: widget.initial?.gateway ?? '',
  );
  late final _dns = TextEditingController(text: widget.initial?.dns ?? '');
  String? _error;

  @override
  void dispose() {
    _ip.dispose();
    _netmask.dispose();
    _gateway.dispose();
    _dns.dispose();
    super.dispose();
  }

  void _submit() {
    final dns = _dns.text.trim();
    final fields = {
      'IP address': _ip.text.trim(),
      'Netmask': _netmask.text.trim(),
      'Gateway': _gateway.text.trim(),
      if (dns.isNotEmpty) 'DNS': dns,
    };
    for (final entry in fields.entries) {
      if (!isValidIpv4(entry.value)) {
        setState(() => _error = '${entry.key} is not a valid IPv4 address');
        return;
      }
    }
    Navigator.of(context).pop(
      _StaticIpConfig(
        _ip.text.trim(),
        _netmask.text.trim(),
        _gateway.text.trim(),
        dns.isEmpty ? null : dns,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Static IP',
      error: _error,
      onSubmit: _submit,
      submitLabel: 'Apply',
      fields: [
        _SheetField(label: 'IP Address', hint: '192.168.1.50', controller: _ip),
        _SheetField(
          label: 'Netmask',
          hint: '255.255.255.0',
          controller: _netmask,
        ),
        _SheetField(
          label: 'Gateway',
          hint: '192.168.1.1',
          controller: _gateway,
        ),
        _SheetField(
          label: 'DNS (optional)',
          hint: 'defaults to gateway',
          controller: _dns,
        ),
      ],
    );
  }
}

class _WifiCredentials {
  const _WifiCredentials(this.ssid, this.password);

  final String ssid;
  final String password;
}

class _WifiSheet extends StatefulWidget {
  const _WifiSheet({this.initialSsid});

  final String? initialSsid;

  @override
  State<_WifiSheet> createState() => _WifiSheetState();
}

class _WifiSheetState extends State<_WifiSheet> {
  late final _ssid = TextEditingController(text: widget.initialSsid ?? '');
  final _password = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _ssid.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    final ssid = _ssid.text.trim();
    final password = _password.text;
    if (ssid.isEmpty || ssid.length > 32) {
      setState(() => _error = 'Network name must be 1–32 characters');
      return;
    }
    if (password.isNotEmpty && (password.length < 8 || password.length > 64)) {
      setState(
        () => _error = 'Password must be 8–64 characters (or empty for open '
            'networks)',
      );
      return;
    }
    Navigator.of(context).pop(_WifiCredentials(ssid, password));
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Backup WiFi (2.4 GHz)',
      error: _error,
      onSubmit: _submit,
      submitLabel: 'Save',
      fields: [
        _SheetField(label: 'Network Name', hint: 'MyHomeWiFi', controller: _ssid),
        _SheetField(
          label: 'Password',
          hint: 'Leave empty for open networks',
          controller: _password,
          obscure: true,
        ),
      ],
    );
  }
}

class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({
    required this.title,
    required this.fields,
    required this.onSubmit,
    required this.submitLabel,
    this.error,
  });

  final String title;
  final List<Widget> fields;
  final VoidCallback onSubmit;
  final String submitLabel;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: PairingTextStyles.headline.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 18),
          for (final field in fields) ...[field, const SizedBox(height: 14)],
          if (error != null) ...[
            Text(
              error!,
              style: PairingTextStyles.small.copyWith(
                color: const Color(0xFFFFB74D),
              ),
            ),
            const SizedBox(height: 14),
          ],
          PairingActionButton(text: submitLabel, onPressed: onSubmit),
        ],
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.label,
    required this.hint,
    required this.controller,
    this.obscure = false,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: PairingTextStyles.small.copyWith(
            color: PairingTokens.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          autocorrect: false,
          enableSuggestions: false,
          style: PairingTextStyles.body,
          keyboardType: obscure ? null : TextInputType.text,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.08),
            hintText: hint,
            hintStyle: PairingTextStyles.body.copyWith(
              color: PairingTokens.textMuted,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PairingTokens.radiusMd),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
