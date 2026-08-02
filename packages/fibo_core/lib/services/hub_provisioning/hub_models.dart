/// JSON payload models for the FIBO hub BLE endpoints
/// (docs/firmware/ble-provisioning-protocol.md §6).
library;

/// Active uplink reported by `hub-info.net`.
enum HubUplink { eth, wifi, none }

/// Thrown when an endpoint returns a non-ok `status` field.
class HubEndpointException implements Exception {
  const HubEndpointException(this.endpoint, this.status);

  final String endpoint;

  /// Raw status string, e.g. `invalid_args`, `store_failed`, `apply_failed`.
  final String status;

  @override
  String toString() => 'HubEndpointException($endpoint: $status)';
}

/// `hub-info` response — hub identity and status.
class HubInfo {
  const HubInfo({
    required this.firmwareVersion,
    required this.serial,
    required this.mac,
    required this.ethLink,
    required this.ethIp,
    required this.wifiConfigured,
    required this.wifiConnected,
    required this.uplink,
    required this.claimed,
    this.provWindowSeconds,
    this.uptimeSeconds,
    this.heapFreeBytes,
  });

  final String firmwareVersion;
  final String serial;
  final String mac;

  /// True when the Ethernet PHY reports a physical link (cable plugged in).
  /// Firmware < proto v1.1 reported the got-IP state here instead.
  final bool ethLink;
  final String ethIp;
  final bool wifiConfigured;
  final bool wifiConnected;
  final HubUplink uplink;
  final bool claimed;

  /// Remaining provisioning-window seconds: -1 while the unclaimed
  /// always-open window has no deadline; null on older firmware.
  final int? provWindowSeconds;
  final int? uptimeSeconds;
  final int? heapFreeBytes;

  /// The hub is cloud-reachable whenever an uplink is active.
  bool get isOnline => uplink != HubUplink.none;

  /// Cable is plugged in but no IPv4 was obtained (router/DHCP problem —
  /// suggest a static IP, not a cable check).
  bool get ethLinkWithoutIp => ethLink && ethIp == '0.0.0.0';

  factory HubInfo.fromJson(Map<String, dynamic> json) {
    return HubInfo(
      firmwareVersion: json['fw'] as String? ?? '',
      serial: json['serial'] as String? ?? '',
      mac: json['mac'] as String? ?? '',
      ethLink: json['eth_link'] as bool? ?? false,
      ethIp: json['eth_ip'] as String? ?? '0.0.0.0',
      wifiConfigured: json['wifi_configured'] as bool? ?? false,
      wifiConnected: json['wifi_connected'] as bool? ?? false,
      uplink: switch (json['net']) {
        'eth' => HubUplink.eth,
        'wifi' => HubUplink.wifi,
        _ => HubUplink.none,
      },
      claimed: json['claimed'] as bool? ?? false,
      provWindowSeconds: (json['prov_win_s'] as num?)?.toInt(),
      uptimeSeconds: (json['uptime_s'] as num?)?.toInt(),
      heapFreeBytes: (json['heap_free'] as num?)?.toInt(),
    );
  }
}

/// `hub-net` read response — Ethernet configuration.
class HubNetConfig {
  const HubNetConfig({
    required this.isStatic,
    required this.link,
    required this.activeIp,
    this.ip,
    this.netmask,
    this.gateway,
    this.dns,
  });

  final bool isStatic;
  final bool link;
  final String activeIp;
  final String? ip;
  final String? netmask;
  final String? gateway;
  final String? dns;

  factory HubNetConfig.fromJson(Map<String, dynamic> json) {
    return HubNetConfig(
      isStatic: json['mode'] == 'static',
      link: json['link'] as bool? ?? false,
      activeIp: json['active_ip'] as String? ?? '0.0.0.0',
      ip: json['ip'] as String?,
      netmask: json['netmask'] as String?,
      gateway: json['gw'] as String?,
      dns: json['dns'] as String?,
    );
  }
}

/// `hub-wifi` read response — stored WiFi fallback credentials state.
class HubWifiStatus {
  const HubWifiStatus({
    required this.configured,
    required this.ssid,
    required this.connected,
    required this.ip,
  });

  final bool configured;
  final String ssid;
  final bool connected;
  final String ip;

  factory HubWifiStatus.fromJson(Map<String, dynamic> json) {
    return HubWifiStatus(
      configured: json['configured'] as bool? ?? false,
      ssid: json['ssid'] as String? ?? '',
      connected: json['connected'] as bool? ?? false,
      ip: json['ip'] as String? ?? '0.0.0.0',
    );
  }
}

/// Client-side IPv4 validation, so bad input is caught before an
/// `invalid_args` round trip (protocol doc §6.4).
bool isValidIpv4(String value) {
  final parts = value.trim().split('.');
  if (parts.length != 4) return false;
  for (final part in parts) {
    if (part.isEmpty || part.length > 3) return false;
    if (part.length > 1 && part.startsWith('0')) return false;
    final n = int.tryParse(part);
    if (n == null || n < 0 || n > 255) return false;
  }
  return true;
}
