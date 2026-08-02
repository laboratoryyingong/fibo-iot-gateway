import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'hub_transport.dart';
import 'protocomm_proto.dart';
import 'security1.dart';

/// In-process simulation of a FIBO hub: device-side security1 handshake plus
/// the business endpoints, following the protocol doc. Used by unit tests and
/// available for UI development without hardware.
class FakeHubTransport implements HubTransport {
  FakeHubTransport({
    this.pop = 'fibo1234',
    this.serial = 'FIBO-A1B2C3D4E5F6',
    this.mac = 'a1:b2:c3:d4:e5:f6',
    this.firmwareVersion = '0.1.0',
    this.ethLink = true,
    Random? random,
  }) : _random = random ?? Random.secure();

  final String pop;
  final String serial;
  final String mac;
  final String firmwareVersion;
  final Random _random;

  bool ethLink;

  /// Mirrors the firmware: cable can be up while DHCP still has no address.
  bool ethHasIp = true;
  int provWindowSeconds = -1;
  bool claimed = false;
  String? claimToken;
  String netMode = 'dhcp';
  String? staticIp;
  String? staticNetmask;
  String? staticGateway;
  String? staticDns;
  String? wifiSsid;
  String? wifiPassword;
  bool closed = false;

  final X25519 _x25519 = X25519();
  Uint8List? _clientPubKey;
  Uint8List? _devicePubKey;
  Security1Cipher? _cipher;

  String get _activeIp => ethLink && ethHasIp
      ? (netMode == 'static' ? staticIp ?? '0.0.0.0' : '192.168.1.23')
      : '0.0.0.0';

  bool get _ethOnline => ethLink && ethHasIp;

  @override
  Future<Uint8List> sendReceive(String endpoint, Uint8List data) async {
    switch (endpoint) {
      case HubBleContract.provSession:
        return _handleSession(data);
      case HubBleContract.protoVer:
        return _utf8Bytes('{"prov":{"ver":"v1.1","sec_ver":1}}');
      default:
        return _handleSecured(endpoint, data);
    }
  }

  @override
  Future<void> close() async {
    closed = true;
  }

  Future<Uint8List> _handleSession(Uint8List data) async {
    final payload = ProtoMessage.parse(data).message(Sec1Fields.sec1Payload);
    final cmd0 = payload?.message(Sec1Fields.sc0);
    if (cmd0 != null) {
      _clientPubKey = cmd0.bytes(Sec1Fields.clientPubKey);
      final keyPair = await _x25519.newKeyPair();
      _devicePubKey = Uint8List.fromList(
        (await keyPair.extractPublicKey()).bytes,
      );
      final deviceRandom = Uint8List.fromList(
        List.generate(16, (_) => _random.nextInt(256)),
      );
      final sharedSecret = await _x25519.sharedSecretKey(
        keyPair: keyPair,
        remotePublicKey: SimplePublicKey(
          _clientPubKey!,
          type: KeyPairType.x25519,
        ),
      );
      _cipher = Security1Cipher(
        security1SessionKey(
          sharedSecret: await sharedSecret.extractBytes(),
          pop: pop,
        ),
        deviceRandom,
      );

      final resp0 = ProtoWriter()
        ..writeBytesField(Sec1Fields.devicePubKey, _devicePubKey!)
        ..writeBytesField(Sec1Fields.deviceRandom, deviceRandom);
      return _sessionResponse(
        Sec1Fields.msgSessionResponse0,
        Sec1Fields.sr0,
        resp0,
      );
    }

    final cmd1 = payload?.message(Sec1Fields.sc1);
    if (cmd1 != null) {
      final clientVerify = cmd1.bytes(Sec1Fields.clientVerifyData)!;
      final decrypted = _cipher!.apply(clientVerify);
      final resp1 = ProtoWriter();
      if (!_bytesEqual(decrypted, _devicePubKey!)) {
        // Status CryptoError, as the firmware reports on a PoP mismatch.
        resp1.writeVarintField(Sec1Fields.respStatus, 6);
      } else {
        resp1.writeBytesField(
          Sec1Fields.deviceVerifyData,
          _cipher!.apply(_clientPubKey!),
        );
      }
      return _sessionResponse(
        Sec1Fields.msgSessionResponse1,
        Sec1Fields.sr1,
        resp1,
      );
    }

    throw StateError('Unexpected session message');
  }

  Uint8List _sessionResponse(int msgType, int field, ProtoWriter message) {
    final payload = ProtoWriter()
      ..writeVarintField(Sec1Fields.msgType, msgType)
      ..writeMessageField(field, message);
    final session = ProtoWriter()
      ..writeVarintField(Sec1Fields.secVer, Sec1Fields.secScheme1)
      ..writeMessageField(Sec1Fields.sec1Payload, payload);
    return session.toBytes();
  }

  Uint8List _handleSecured(String endpoint, Uint8List data) {
    final cipher = _cipher;
    if (cipher == null) throw StateError('No session established');
    final request = utf8.decode(cipher.apply(data));
    final response = _dispatch(endpoint, request);
    return cipher.apply(_utf8Bytes(response));
  }

  String _dispatch(String endpoint, String request) {
    switch (endpoint) {
      case HubBleContract.hubInfo:
        return jsonEncode({
          'fw': firmwareVersion,
          'serial': serial,
          'mac': mac,
          'eth_link': ethLink,
          'eth_ip': _activeIp,
          'wifi_configured': wifiSsid != null,
          'wifi_connected': false,
          'net': _ethOnline ? 'eth' : (wifiSsid != null ? 'wifi' : 'none'),
          'claimed': claimed,
          'prov_win_s': provWindowSeconds,
          'uptime_s': 3600,
          'heap_free': 180000,
        });
      case HubBleContract.hubClaim:
        if (request.isEmpty || request.length > 256) {
          return '{"status":"invalid_args"}';
        }
        claimToken = request;
        claimed = true;
        provWindowSeconds = 300;
        return '{"status":"ok"}';
      case HubBleContract.hubNet:
        return _dispatchNet(request);
      case HubBleContract.hubWifi:
        return _dispatchWifi(request);
      case HubBleContract.hubReset:
        final json = _decodeJson(request);
        if (json['confirm'] != true) return '{"status":"invalid_args"}';
        claimed = false;
        claimToken = null;
        provWindowSeconds = -1;
        netMode = 'dhcp';
        staticIp = staticNetmask = staticGateway = staticDns = null;
        wifiSsid = wifiPassword = null;
        return '{"status":"ok","rebooting":true}';
      default:
        throw StateError('Unknown endpoint $endpoint');
    }
  }

  String _dispatchNet(String request) {
    final json = _decodeJson(request);
    if (json.isEmpty) {
      return jsonEncode({
        'mode': netMode,
        'link': ethLink,
        'active_ip': _activeIp,
        if (netMode == 'static') ...{
          'ip': staticIp,
          'netmask': staticNetmask,
          'gw': staticGateway,
          'dns': staticDns ?? staticGateway,
        },
      });
    }
    if (json['mode'] == 'dhcp') {
      netMode = 'dhcp';
      return '{"status":"ok"}';
    }
    if (json['mode'] == 'static') {
      final fields = [json['ip'], json['netmask'], json['gw']];
      if (fields.any((f) => f is! String || !_looksLikeIp(f))) {
        return '{"status":"invalid_args"}';
      }
      netMode = 'static';
      staticIp = json['ip'] as String;
      staticNetmask = json['netmask'] as String;
      staticGateway = json['gw'] as String;
      staticDns = json['dns'] as String?;
      return '{"status":"ok"}';
    }
    return '{"status":"invalid_args"}';
  }

  String _dispatchWifi(String request) {
    final json = _decodeJson(request);
    if (json.isEmpty) {
      return jsonEncode({
        'configured': wifiSsid != null,
        'ssid': wifiSsid ?? '',
        'connected': false,
        'ip': '0.0.0.0',
      });
    }
    if (json['clear'] == true) {
      wifiSsid = wifiPassword = null;
      return '{"status":"ok"}';
    }
    final ssid = json['ssid'];
    final password = json['password'] as String? ?? '';
    if (ssid is! String || ssid.isEmpty || ssid.length > 32) {
      return '{"status":"invalid_args"}';
    }
    if (password.isNotEmpty && (password.length < 8 || password.length > 64)) {
      return '{"status":"invalid_args"}';
    }
    wifiSsid = ssid;
    wifiPassword = password;
    return '{"status":"ok"}';
  }

  Map<String, dynamic> _decodeJson(String request) {
    try {
      final decoded = jsonDecode(request);
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v));
      }
    } catch (_) {}
    return const {};
  }

  static bool _looksLikeIp(String value) =>
      RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(value);

  static Uint8List _utf8Bytes(String value) =>
      Uint8List.fromList(utf8.encode(value));

  static bool _bytesEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
