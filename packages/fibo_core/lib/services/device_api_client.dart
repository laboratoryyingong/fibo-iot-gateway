// REST client for the agent's device API (docs/claude-agent/API.md
// "REST Device API"). Reads hit the gateway snapshot; writes pass the same
// Rules Engine gate as the chat tools, so the 409/428/502 control flows below
// mirror the conversational path exactly.
//
// Auth: AgentConfig.authHeader() attaches `Authorization: Bearer <key>` when a
// key is configured. See docs/claude-agent/APP-INTEGRATION.md §2.

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'agent_config.dart';
import 'claude_agent_client.dart' show AgentHttpException;
import 'device_api_models.dart';

/// `409` — a conflict rule blocked the control. [conflictRule] names the rule.
class AgentConflictException implements Exception {
  AgentConflictException(this.message, this.conflictRule);
  final String message;
  final String? conflictRule;

  @override
  String toString() => 'AgentConflictException($conflictRule): $message';
}

/// `428` — a dangerous action needs confirmation. Resend the same control with
/// `confirm: true` to authorize it.
class AgentConfirmationRequiredException implements Exception {
  AgentConfirmationRequiredException(this.message);
  final String message;

  @override
  String toString() => 'AgentConfirmationRequiredException: $message';
}

/// `502` — the cloud accepted the control but the device never confirmed
/// (offline/unresponsive).
class AgentNotConvergedException implements Exception {
  AgentNotConvergedException(this.message);
  final String message;

  @override
  String toString() => 'AgentNotConvergedException: $message';
}

class DeviceApiClient {
  DeviceApiClient({http.Client? client, Duration? timeout})
      : _client = client ?? http.Client(),
        _timeout = timeout ?? const Duration(seconds: 15);

  final http.Client _client;
  final Duration _timeout;

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = Uri.parse('${AgentConfig.baseUrl}$path');
    if (query == null || query.isEmpty) return base;
    return base.replace(queryParameters: {...base.queryParameters, ...query});
  }

  Map<String, String> get _jsonHeaders => {
        'content-type': 'application/json',
        ...AgentConfig.authHeader(),
      };

  // --- Reads ---------------------------------------------------------------

  Future<List<AgentDevice>> listDevices({String? room, String? type}) async {
    final query = <String, String>{
      if (room != null && room.isNotEmpty) 'room': room,
      if (type != null && type.isNotEmpty) 'type': type,
    };
    final json = await _get('/devices', query);
    return _list(json['devices']).map(AgentDevice.fromJson).toList();
  }

  Future<AgentDevice> getDevice(String id) async {
    final json = await _get('/devices/${Uri.encodeComponent(id)}');
    return AgentDevice.fromJson(json);
  }

  Future<List<AgentRoom>> listRooms() async {
    final json = await _get('/rooms');
    return _list(json['rooms']).map(AgentRoom.fromJson).toList();
  }

  Future<List<AgentScene>> listScenes() async {
    final json = await _get('/scenes');
    return _list(json['scenes']).map(AgentScene.fromJson).toList();
  }

  // --- Writes --------------------------------------------------------------

  /// Controls a device. Throws [AgentConfirmationRequiredException] on `428`
  /// (resend with `confirm: true`), [AgentConflictException] on `409`,
  /// [AgentNotConvergedException] on `502`, or [AgentHttpException] otherwise.
  Future<DeviceControlResult> controlDevice(
    String id, {
    required String action,
    Map<String, dynamic>? params,
    bool confirm = false,
    String? userId,
  }) async {
    final body = <String, dynamic>{
      'action': action,
      if (params != null && params.isNotEmpty) 'params': params,
      if (confirm) 'confirm': true,
      if (userId != null && userId.isNotEmpty) 'user_id': userId,
    };
    final json = await _post(
      '/devices/${Uri.encodeComponent(id)}/control',
      body,
    );
    return DeviceControlResult.fromJson(json);
  }

  /// Runs a scene. Same `409`/`428` gating as [controlDevice] if a step is
  /// dangerous or conflicting.
  Future<SceneRunResult> runScene(String id, {bool confirm = false}) async {
    final json = await _post(
      '/scenes/${Uri.encodeComponent(id)}/run',
      {if (confirm) 'confirm': true},
    );
    return SceneRunResult.fromJson(json);
  }

  // --- Plumbing ------------------------------------------------------------

  Future<Map<String, dynamic>> _get(String path, [Map<String, String>? q]) async {
    final resp = await _client
        .get(_uri(path, q), headers: AgentConfig.authHeader())
        .timeout(_timeout);
    return _decode(resp);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final resp = await _client
        .post(_uri(path), headers: _jsonHeaders, body: jsonEncode(body))
        .timeout(_timeout);
    return _decode(resp);
  }

  /// Decodes a response, mapping the documented control status codes to typed
  /// exceptions. Returns the parsed body on `200`.
  Map<String, dynamic> _decode(http.Response resp) {
    final body = _tryParse(resp.body);
    if (resp.statusCode == 200) return body;

    final message = (body['error'] ?? resp.body).toString();
    switch (resp.statusCode) {
      case 409:
        throw AgentConflictException(message, body['conflict_rule']?.toString());
      case 428:
        throw AgentConfirmationRequiredException(message);
      case 502:
        throw AgentNotConvergedException(message);
      default:
        throw AgentHttpException(resp.statusCode, message);
    }
  }

  Map<String, dynamic> _tryParse(String body) {
    if (body.isEmpty) return const <String, dynamic>{};
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'value': decoded};
    } catch (_) {
      return const <String, dynamic>{};
    }
  }

  List<Map<String, dynamic>> _list(Object? value) {
    if (value is! List) return const <Map<String, dynamic>>[];
    return value
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList(growable: false);
  }

  void close() => _client.close();
}
