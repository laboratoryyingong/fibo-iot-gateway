import 'dart:convert';
import 'dart:typed_data';

import 'hub_models.dart';
import 'hub_transport.dart';
import 'security1.dart';

/// High-level client for the FIBO hub BLE provisioning endpoints.
///
/// All business endpoints exchange UTF-8 JSON, encrypted by the security1
/// session ([establish] must succeed first). See
/// docs/firmware/ble-provisioning-protocol.md for the full contract.
class HubProvisioningSession {
  HubProvisioningSession(this._transport);

  final HubTransport _transport;
  Security1Client? _security;

  bool get isEstablished => _security?.isEstablished ?? false;

  /// Runs the security1 handshake with the QR label's proof-of-possession.
  /// Throws [Security1Exception] on a wrong PoP.
  Future<void> establish(String pop) async {
    final client = Security1Client(pop);
    final resp0 = await _transport.sendReceive(
      HubBleContract.provSession,
      await client.buildSessionCmd0(),
    );
    final resp1 = await _transport.sendReceive(
      HubBleContract.provSession,
      await client.handleSessionResp0(resp0),
    );
    client.handleSessionResp1(resp1);
    _security = client;
  }

  /// Reads `proto-ver` (plaintext endpoint, usable before [establish]).
  Future<String> readProtoVersion() async {
    final response = await _transport.sendReceive(
      HubBleContract.protoVer,
      Uint8List.fromList(utf8.encode('---')),
    );
    return utf8.decode(response, allowMalformed: true);
  }

  Future<HubInfo> readInfo() async {
    return HubInfo.fromJson(await _readJson(HubBleContract.hubInfo));
  }

  /// Stores the claim token (opaque string, ≤ 256 bytes) on the hub.
  Future<void> claim(String token) async {
    final response = await _sendString(HubBleContract.hubClaim, token);
    _checkStatus(HubBleContract.hubClaim, response);
  }

  Future<HubNetConfig> readNetConfig() async {
    return HubNetConfig.fromJson(await _readJson(HubBleContract.hubNet));
  }

  Future<void> writeNetDhcp() async {
    final response = await _sendJson(HubBleContract.hubNet, {'mode': 'dhcp'});
    _checkStatus(HubBleContract.hubNet, response);
  }

  Future<void> writeNetStatic({
    required String ip,
    required String netmask,
    required String gateway,
    String? dns,
  }) async {
    final response = await _sendJson(HubBleContract.hubNet, {
      'mode': 'static',
      'ip': ip,
      'netmask': netmask,
      'gw': gateway,
      if (dns != null && dns.isNotEmpty) 'dns': dns,
    });
    _checkStatus(HubBleContract.hubNet, response);
  }

  Future<HubWifiStatus> readWifiStatus() async {
    return HubWifiStatus.fromJson(await _readJson(HubBleContract.hubWifi));
  }

  /// Stores 2.4 GHz WiFi fallback credentials (empty password = open network).
  Future<void> writeWifiCredentials({
    required String ssid,
    required String password,
  }) async {
    final response = await _sendJson(HubBleContract.hubWifi, {
      'ssid': ssid,
      'password': password,
    });
    _checkStatus(HubBleContract.hubWifi, response);
  }

  Future<void> clearWifiCredentials() async {
    final response = await _sendJson(HubBleContract.hubWifi, {'clear': true});
    _checkStatus(HubBleContract.hubWifi, response);
  }

  /// Factory reset: the hub reboots ~1.5 s later, unclaimed and advertising.
  Future<void> factoryReset() async {
    final response = await _sendJson(HubBleContract.hubReset, {
      'confirm': true,
    });
    _checkStatus(HubBleContract.hubReset, response);
  }

  Future<void> close() => _transport.close();

  Security1Client get _requireSecurity {
    final security = _security;
    if (security == null || !security.isEstablished) {
      throw const Security1Exception('Session not established');
    }
    return security;
  }

  Future<Map<String, dynamic>> _readJson(String endpoint) async {
    final response = await _sendJson(endpoint, const {});
    return response;
  }

  Future<Map<String, dynamic>> _sendJson(
    String endpoint,
    Map<String, dynamic> request,
  ) async {
    return _sendString(endpoint, jsonEncode(request));
  }

  Future<Map<String, dynamic>> _sendString(
    String endpoint,
    String request,
  ) async {
    final security = _requireSecurity;
    final encrypted = security.encrypt(
      Uint8List.fromList(utf8.encode(request)),
    );
    final response = await _transport.sendReceive(endpoint, encrypted);
    final plain = utf8.decode(security.decrypt(response));
    final decoded = jsonDecode(plain);
    if (decoded is! Map) {
      throw HubEndpointException(endpoint, 'malformed_response');
    }
    return decoded.map((key, value) => MapEntry(key.toString(), value));
  }

  void _checkStatus(String endpoint, Map<String, dynamic> response) {
    final status = response['status'] as String? ?? 'missing_status';
    if (status != 'ok') {
      throw HubEndpointException(endpoint, status);
    }
  }
}
