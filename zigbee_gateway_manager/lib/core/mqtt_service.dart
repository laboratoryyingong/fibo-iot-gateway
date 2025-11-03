import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  final String clientId;
  final String broker;
  final int port;
  final bool useWebSocket;
  final bool secure;
  final String? username;
  final String? password;
  // final String wsPath;

  late final MqttServerClient _client;
  final _updatesCtrl = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get updates => _updatesCtrl.stream;

  MqttService({
    required this.clientId,
    required this.broker,
    required this.port,
    required this.useWebSocket,
    required this.secure,
    this.username,
    this.password,
  }) {
    _client = MqttServerClient(broker, clientId);
    _client.logging(on: false);
    _client.keepAlivePeriod = 30;
    _client.autoReconnect = true;
    _client.resubscribeOnAutoReconnect = true;

    if (useWebSocket) {
      _client.useWebSocket = true;
      _client.port = port;
      _client.websocketProtocols = MqttClientConstants.protocolsSingleDefault;
    } else {
      _client.port = port;
      _client.secure = secure;
    }

    _client.onDisconnected = () => _updatesCtrl.add({'event': 'disconnected'});
    _client.onConnected = () => _updatesCtrl.add({'event': 'connected'});
    _client.onAutoReconnect = () => _updatesCtrl.add({'event': 'reconnecting'});
    _client.onAutoReconnected = () =>
        _updatesCtrl.add({'event': 'reconnected'});

    _client.updates?.listen((events) {
      for (final e in events) {
        final msg = e.payload as MqttPublishMessage;
        final topic = e.topic;
        final payload = MqttPublishPayload.bytesToStringAsString(
          msg.payload.message,
        );
        _updatesCtrl.add({
          'event': 'message',
          'topic': topic,
          'payload': payload,
        });
      }
    });
  }

  Future<void> connect() async {
    final conn = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    _client.connectionMessage = conn;
    try {
      await _client.connect(username, password);
    } catch (e) {
      _client.disconnect();
      rethrow;
    }
  }

  void subscribe(String topic, {MqttQos qos = MqttQos.atLeastOnce}) {
    _client.subscribe(topic, qos);
  }

  void publishJson(
    String topic,
    Map<String, dynamic> payload, {
    MqttQos qos = MqttQos.atLeastOnce,
    bool retain = false,
  }) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode(payload));
    _client.publishMessage(topic, qos, builder.payload!, retain: retain);
  }

  void publishRaw(
    String topic,
    String payload, {
    MqttQos qos = MqttQos.atLeastOnce,
    bool retain = false,
  }) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);
    _client.publishMessage(topic, qos, builder.payload!, retain: retain);
  }

  void dispose() {
    _updatesCtrl.close();
    _client.disconnect();
  }
}
