import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:fibo_gateway_app/services/device_api_client.dart';
import 'package:fibo_gateway_app/services/device_api_models.dart';

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status,
        headers: {'content-type': 'application/json'});

void main() {
  group('model parsing', () {
    test('AgentDevice exposes typed power/brightness accessors', () {
      final device = AgentDevice.fromJson(const {
        'id': 'light.living_room',
        'name': 'Living room main light',
        'type': 'light',
        'profile': 'color_light',
        'room': 'living_room',
        'online': true,
        'dangerous': false,
        'state': {'power': 'on', 'brightness': 71, 'color_temp': 4000},
      });

      expect(device.id, 'light.living_room');
      expect(device.isOn, true);
      expect(device.brightness, 71);
    });

    test('sensor with no power key reports null isOn', () {
      final device = AgentDevice.fromJson(const {
        'id': 'sensor.hall',
        'state': {'motion': true},
      });
      expect(device.isOn, isNull);
      expect(device.brightness, isNull);
    });

    test('DeviceControlResult treats missing converged as converged', () {
      final result = DeviceControlResult.fromJson(const {
        'ok': true,
        'device_id': 'light.kitchen',
        'current': {'power': 'on'},
      });
      expect(result.converged, true);
      expect(result.current['power'], 'on');
    });
  });

  group('control status-code mapping', () {
    test('200 returns a parsed DeviceControlResult', () async {
      final client = DeviceApiClient(
        client: MockClient((_) async => _json({
              'ok': true,
              'device_id': 'light.kitchen',
              'action': 'set_brightness',
              'previous': {'brightness': 0},
              'current': {'power': 'on', 'brightness': 30},
              'converged': true,
            })),
      );
      final result = await client.controlDevice('light.kitchen',
          action: 'set_brightness', params: {'value': 30});
      expect(result.ok, true);
      expect(result.current['brightness'], 30);
    });

    test('409 throws AgentConflictException with the rule name', () async {
      final client = DeviceApiClient(
        client: MockClient((_) async =>
            _json({'error': 'blocked', 'conflict_rule': 'no_lights_when_armed'}, 409)),
      );
      expect(
        () => client.controlDevice('light.kitchen', action: 'turn_on'),
        throwsA(isA<AgentConflictException>()
            .having((e) => e.conflictRule, 'conflictRule', 'no_lights_when_armed')),
      );
    });

    test('428 throws AgentConfirmationRequiredException', () async {
      final client = DeviceApiClient(
        client: MockClient((_) async =>
            _json({'error': 'confirm required', 'requires_confirmation': true}, 428)),
      );
      expect(
        () => client.controlDevice('lock.front', action: 'unlock'),
        throwsA(isA<AgentConfirmationRequiredException>()),
      );
    });

    test('502 throws AgentNotConvergedException', () async {
      final client = DeviceApiClient(
        client: MockClient((_) async => _json({'error': 'device offline'}, 502)),
      );
      expect(
        () => client.controlDevice('light.kitchen', action: 'turn_on'),
        throwsA(isA<AgentNotConvergedException>()),
      );
    });

    test('listDevices unwraps the devices array', () async {
      late Uri seen;
      final client = DeviceApiClient(
        client: MockClient((req) async {
          seen = req.url;
          return _json({
            'devices': [
              {'id': 'light.kitchen', 'state': {'power': 'off'}},
            ],
          });
        }),
      );
      final devices = await client.listDevices(room: 'kitchen');
      expect(devices.single.id, 'light.kitchen');
      expect(seen.queryParameters['room'], 'kitchen');
    });
  });
}
