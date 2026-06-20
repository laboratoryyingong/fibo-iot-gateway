import 'dart:async';
import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:uuid/uuid.dart';

import 'aws_credentials.dart';
import 'cognito_credentials_provider.dart';
import 'iot_config.dart';
import 'sigv4_iot.dart';

/// One device's reported shadow state, keyed by its named-shadow name
/// (e.g. `admin`, `dev_00158d0001cccccc_ep1`).
class HubShadowEvent {
  const HubShadowEvent(this.shadowName, this.reported, this.desired);
  final String shadowName;
  final Map<String, dynamic> reported;
  final Map<String, dynamic> desired;
}

/// Live AWS IoT shadow client for `fibo-hub-001` over MQTT-WSS.
///
/// Subscribes to every named shadow's `get/accepted` and `update/documents`
/// topics, primes them with a `get`, and exposes a stream of reported state.
/// Control writes go through [setDesired].
class IotShadowClient {
  IotShadowClient({CognitoCredentialsProvider? credentials})
      : _credentials = credentials ?? CognitoCredentialsProvider();

  final CognitoCredentialsProvider _credentials;
  final _events = StreamController<HubShadowEvent>.broadcast();
  MqttServerClient? _client;
  bool _connected = false;

  Stream<HubShadowEvent> get events => _events.stream;
  bool get isConnected => _connected;

  String get _base => '\$aws/things/${IotConfig.thingName}/shadow';

  Future<void> connect() async {
    if (_connected) return;
    // The credentials provider is pre-configured by the caller (guest for dev,
    // or the per-user developer identity for prod).
    final AwsCredentials creds = await _credentials.getCredentials();
    final url = presignIotWssUrl(
      creds: creds,
      region: IotConfig.region,
      endpoint: IotConfig.iotEndpoint,
    );

    final clientId = 'fibo-app-${const Uuid().v4()}';
    final client = MqttServerClient.withPort(url, clientId, 443)
      ..useWebSocket = true
      ..websocketProtocols = ['mqtt']
      ..keepAlivePeriod = 30
      ..setProtocolV311()
      ..logging(on: false)
      ..connectionMessage =
          (MqttConnectMessage()..withClientIdentifier(clientId)..startClean());

    await client.connect();
    if (client.connectionStatus?.state != MqttConnectionState.connected) {
      client.disconnect();
      throw Exception(
          'IoT MQTT connect failed: ${client.connectionStatus?.state}');
    }
    _client = client;
    _connected = true;

    // Subscribe to all named shadows' state topics.
    client.subscribe('$_base/name/+/get/accepted', MqttQos.atLeastOnce);
    client.subscribe('$_base/name/+/update/documents', MqttQos.atLeastOnce);

    client.updates!.listen(_onMessages);
    client.onDisconnected = () => _connected = false;
  }

  /// Publishes a `get` to each named shadow so its `get/accepted` flows in.
  void primeAll(Iterable<String> shadowNames) {
    for (final name in shadowNames) {
      _publish('$_base/name/$name/get', const {});
    }
  }

  /// Writes desired state to a named shadow (control).
  void setDesired(String shadowName, Map<String, dynamic> desired) {
    _publish('$_base/name/$shadowName/update', {
      'state': {'desired': desired},
    });
  }

  void _publish(String topic, Map<String, dynamic> payload) {
    final client = _client;
    if (client == null || !_connected) return;
    final builder = MqttClientPayloadBuilder()..addString(jsonEncode(payload));
    client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  void _onMessages(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final m in messages) {
      final topic = m.topic;
      final msg = m.payload as MqttPublishMessage;
      final text =
          MqttPublishPayload.bytesToStringAsString(msg.payload.message);
      Map<String, dynamic> doc;
      try {
        doc = jsonDecode(text) as Map<String, dynamic>;
      } catch (_) {
        continue;
      }

      final shadowName = _shadowNameFromTopic(topic);
      if (shadowName == null) continue;

      Map<String, dynamic> state;
      if (topic.endsWith('/get/accepted')) {
        state = _asMap(doc['state']);
      } else if (topic.endsWith('/update/documents')) {
        state = _asMap(_asMap(doc['current'])['state']);
      } else {
        continue;
      }
      final reported = _asMap(state['reported']);
      final desired = _asMap(state['desired']);
      if (reported.isNotEmpty || desired.isNotEmpty) {
        _events.add(HubShadowEvent(shadowName, reported, desired));
      }
    }
  }

  /// `$aws/things/fibo-hub-001/shadow/name/<NAME>/get/accepted` → `<NAME>`.
  String? _shadowNameFromTopic(String topic) {
    final marker = '/shadow/name/';
    final i = topic.indexOf(marker);
    if (i < 0) return null;
    final rest = topic.substring(i + marker.length);
    final slash = rest.indexOf('/');
    return slash < 0 ? rest : rest.substring(0, slash);
  }

  Map<String, dynamic> _asMap(Object? v) =>
      v is Map ? v.cast<String, dynamic>() : const <String, dynamic>{};

  void disconnect() {
    _connected = false;
    _client?.disconnect();
    _client = null;
  }
}
