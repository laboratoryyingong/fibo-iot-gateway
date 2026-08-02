import 'dart:typed_data';

import 'package:fibo_core/services/hub_provisioning/hub_provisioning.dart';
import 'package:fibo_core/services/hub_provisioning/protocomm_proto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HubQrLabel', () {
    test('parses a factory label', () {
      final label = HubQrLabel.tryParse(
        '{"v":1,"sn":"FIBO-A1B2C3D4E5F6","ble":"FIBO-D4E5F6","pop":"x7k2mn9p"}',
      );
      expect(label, isNotNull);
      expect(label!.version, 1);
      expect(label.serial, 'FIBO-A1B2C3D4E5F6');
      expect(label.bleName, 'FIBO-D4E5F6');
      expect(label.pop, 'x7k2mn9p');
      expect(label.isSupportedVersion, isTrue);
    });

    test('tolerates a missing serial (dev boards)', () {
      final label = HubQrLabel.tryParse(
        '{"v":1,"ble":"FIBO-D4E5F6","pop":"fibo1234"}',
      );
      expect(label, isNotNull);
      expect(label!.serial, '');
    });

    test('rejects non-label content', () {
      expect(HubQrLabel.tryParse('https://example.com'), isNull);
      expect(HubQrLabel.tryParse('{"v":1}'), isNull);
      expect(HubQrLabel.tryParse('{"v":"1","ble":"x","pop":"y"}'), isNull);
    });

    test('flags unknown schema versions', () {
      final label = HubQrLabel.tryParse('{"v":2,"ble":"FIBO-X","pop":"p"}');
      expect(label, isNotNull);
      expect(label!.isSupportedVersion, isFalse);
    });
  });

  group('proto wire format', () {
    test('round-trips varint and bytes fields', () {
      final writer = ProtoWriter()
        ..writeVarintField(2, 300)
        ..writeBytesField(11, [1, 2, 3]);
      final message = ProtoMessage.parse(writer.toBytes());
      expect(message.varint(2), 300);
      expect(message.bytes(11), [1, 2, 3]);
      expect(message.varint(9), 0);
      expect(message.bytes(9), isNull);
    });

    test('round-trips nested messages', () {
      final inner = ProtoWriter()..writeBytesField(1, List.filled(32, 0xAB));
      final outer = ProtoWriter()
        ..writeVarintField(1, 2)
        ..writeMessageField(20, inner);
      final decoded = ProtoMessage.parse(outer.toBytes());
      expect(decoded.varint(1), 2);
      expect(decoded.message(20)!.bytes(1), List.filled(32, 0xAB));
    });
  });

  group('isValidIpv4', () {
    test('accepts normal addresses', () {
      expect(isValidIpv4('192.168.1.50'), isTrue);
      expect(isValidIpv4('8.8.8.8'), isTrue);
      expect(isValidIpv4('255.255.255.0'), isTrue);
    });

    test('rejects malformed addresses', () {
      expect(isValidIpv4(''), isFalse);
      expect(isValidIpv4('192.168.1'), isFalse);
      expect(isValidIpv4('192.168.1.256'), isFalse);
      expect(isValidIpv4('192.168.01.5'), isFalse);
      expect(isValidIpv4('a.b.c.d'), isFalse);
    });
  });

  group('HubProvisioningSession against the fake hub', () {
    test('establishes a security1 session and reads hub-info', () async {
      final hub = FakeHubTransport(pop: 'fibo1234');
      final session = HubProvisioningSession(hub);
      await session.establish('fibo1234');
      expect(session.isEstablished, isTrue);

      final info = await session.readInfo();
      expect(info.serial, 'FIBO-A1B2C3D4E5F6');
      expect(info.uplink, HubUplink.eth);
      expect(info.claimed, isFalse);
      expect(info.isOnline, isTrue);
    });

    test('wrong PoP fails the handshake', () async {
      final hub = FakeHubTransport(pop: 'fibo1234');
      final session = HubProvisioningSession(hub);
      await expectLater(
        session.establish('wrong-pop'),
        throwsA(isA<Security1Exception>()),
      );
      expect(session.isEstablished, isFalse);
    });

    test('claim stores the token and flips claimed', () async {
      final hub = FakeHubTransport();
      final session = HubProvisioningSession(hub);
      await session.establish('fibo1234');
      expect((await session.readInfo()).provWindowSeconds, -1);

      await session.claim('token-abc-123');
      expect(hub.claimToken, 'token-abc-123');
      final info = await session.readInfo();
      expect(info.claimed, isTrue);
      expect(info.provWindowSeconds, 300);
    });

    test('distinguishes cable-unplugged from DHCP failure', () async {
      final hub = FakeHubTransport(ethLink: false);
      final session = HubProvisioningSession(hub);
      await session.establish('fibo1234');
      var info = await session.readInfo();
      expect(info.uplink, HubUplink.none);
      expect(info.ethLinkWithoutIp, isFalse);

      hub.ethLink = true;
      hub.ethHasIp = false;
      info = await session.readInfo();
      expect(info.uplink, HubUplink.none);
      expect(info.ethLinkWithoutIp, isTrue);
    });

    test('hub-info tolerates older firmware without new fields', () {
      final info = HubInfo.fromJson(const {
        'fw': '0.1.0',
        'serial': 'FIBO-A1B2C3D4E5F6',
        'eth_link': true,
        'eth_ip': '192.168.1.23',
        'net': 'eth',
        'claimed': false,
      });
      expect(info.provWindowSeconds, isNull);
      expect(info.uptimeSeconds, isNull);
      expect(info.heapFreeBytes, isNull);
    });

    test('oversized claim token surfaces invalid_args', () async {
      final session = HubProvisioningSession(FakeHubTransport());
      await session.establish('fibo1234');
      await expectLater(
        session.claim('x' * 300),
        throwsA(
          isA<HubEndpointException>().having(
            (e) => e.status,
            'status',
            'invalid_args',
          ),
        ),
      );
    });

    test('hub-net static write persists and reads back', () async {
      final hub = FakeHubTransport();
      final session = HubProvisioningSession(hub);
      await session.establish('fibo1234');

      await session.writeNetStatic(
        ip: '192.168.1.50',
        netmask: '255.255.255.0',
        gateway: '192.168.1.1',
      );
      final config = await session.readNetConfig();
      expect(config.isStatic, isTrue);
      expect(config.ip, '192.168.1.50');
      expect(config.dns, '192.168.1.1');

      await session.writeNetDhcp();
      expect((await session.readNetConfig()).isStatic, isFalse);
    });

    test('hub-wifi stores, reports, and clears credentials', () async {
      final hub = FakeHubTransport(ethLink: true);
      final session = HubProvisioningSession(hub);
      await session.establish('fibo1234');

      await session.writeWifiCredentials(
        ssid: 'MyHomeWiFi',
        password: 'secret123',
      );
      var status = await session.readWifiStatus();
      expect(status.configured, isTrue);
      expect(status.ssid, 'MyHomeWiFi');
      expect(status.connected, isFalse);

      await expectLater(
        session.writeWifiCredentials(ssid: 'X', password: 'short'),
        throwsA(isA<HubEndpointException>()),
      );

      await session.clearWifiCredentials();
      status = await session.readWifiStatus();
      expect(status.configured, isFalse);
    });

    test('factory reset clears claim and network state', () async {
      final hub = FakeHubTransport();
      final session = HubProvisioningSession(hub);
      await session.establish('fibo1234');
      await session.claim('token');
      await session.writeWifiCredentials(
        ssid: 'MyHomeWiFi',
        password: 'secret123',
      );

      await session.factoryReset();
      expect(hub.claimed, isFalse);
      expect(hub.claimToken, isNull);
      expect(hub.wifiSsid, isNull);
    });

    test('proto-ver is readable before the handshake', () async {
      final session = HubProvisioningSession(FakeHubTransport());
      final version = await session.readProtoVersion();
      expect(version, contains('"sec_ver":1'));
    });

    test('endpoint calls without a session throw', () async {
      final session = HubProvisioningSession(FakeHubTransport());
      await expectLater(
        session.readInfo(),
        throwsA(isA<Security1Exception>()),
      );
    });

    test('encrypted payloads are not plaintext on the wire', () async {
      final hub = _RecordingHub();
      final session = HubProvisioningSession(hub);
      await session.establish('fibo1234');
      await session.claim('super-secret-token');

      final wire = hub.writes[HubBleContract.hubClaim]!;
      expect(String.fromCharCodes(wire), isNot(contains('super-secret')));
    });
  });
}

class _RecordingHub extends FakeHubTransport {
  final Map<String, Uint8List> writes = {};

  @override
  Future<Uint8List> sendReceive(String endpoint, Uint8List data) {
    writes[endpoint] = data;
    return super.sendReceive(endpoint, data);
  }
}
