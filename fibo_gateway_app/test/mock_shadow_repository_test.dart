import 'package:fibo_gateway_app/services/mock_shadow_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses stage one endpoint shadows from fixture json', () {
    const rawJson = '''
{
  "thing_name": "fibo-hub-001",
  "named_shadows": [
    {
      "shadow_name": "dev_00158d0001aaaaaa_ep1",
      "kind": "endpoint",
      "profile": "onoff_actuator",
      "document": {
        "state": {
          "reported": {
            "identity": {
              "ieee": "00158d0001aaaaaa",
              "ep": 1,
              "model": "TS0001"
            },
            "connectivity": {
              "online": true
            },
            "state": {
              "power": 1
            }
          }
        }
      }
    },
    {
      "shadow_name": "dev_00158d0001bbbbbb_ep1",
      "kind": "endpoint",
      "profile": "dimmable_light",
      "document": {
        "state": {
          "reported": {
            "identity": {
              "ieee": "00158d0001bbbbbb",
              "ep": 1,
              "model": "TS0601_dimmer"
            },
            "connectivity": {
              "online": true
            },
            "state": {
              "power": 1,
              "level": 128
            }
          }
        }
      }
    },
    {
      "shadow_name": "dev_00158d0001cccccc_ep1",
      "kind": "endpoint",
      "profile": "color_light",
      "document": {
        "state": {
          "reported": {
            "identity": {
              "ieee": "00158d0001cccccc",
              "ep": 1,
              "model": "TS0505B"
            },
            "connectivity": {
              "online": true
            },
            "state": {
              "power": 1,
              "level": 180
            }
          }
        }
      }
    }
  ]
}
''';

    final snapshot = MockShadowRepository.parseSnapshot(rawJson);

    expect(snapshot.thingName, 'fibo-hub-001');
    expect(snapshot.endpoints, hasLength(2));
    expect(snapshot.endpoints.first.shadowName, 'dev_00158d0001aaaaaa_ep1');
    expect(snapshot.endpoints.first.isOn, isTrue);
    expect(snapshot.endpoints.last.supportsLevel, isTrue);
    expect(snapshot.endpoints.last.level, 128);
  });
}
