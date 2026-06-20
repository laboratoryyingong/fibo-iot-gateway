// V0 SCOPE NOTE:
//   - Direct HTTP from app to agent (no Parse proxy). When AgentConfig.apiKey
//     is set, an `Authorization: Bearer <key>` header is attached; otherwise
//     the URL must point at a private/dev host running open.
//     See docs/claude-agent/APP-INTEGRATION.md §2.
//   - SSE parsing is hand-rolled (~50 lines) instead of pulling a dependency.
//     If the protocol grows beyond `event:` / `data:` lines, revisit.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'agent_config.dart';
import 'agent_events.dart';

class AgentHttpException implements Exception {
  AgentHttpException(this.statusCode, this.body);
  final int statusCode;
  final String body;

  @override
  String toString() => 'AgentHttpException($statusCode): $body';
}

class ClaudeAgentClient {
  ClaudeAgentClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Sends a chat turn and yields typed events. Uses SSE when
  /// [AgentConfig.useStreaming] is true; otherwise calls the blocking
  /// /chat endpoint and synthesizes events client-side.
  Stream<AgentEvent> streamChat({
    required String message,
    required String sessionId,
  }) {
    return AgentConfig.useStreaming
        ? _streamChatSse(message: message, sessionId: sessionId)
        : _streamChatBlocking(message: message, sessionId: sessionId);
  }

  Stream<AgentEvent> _streamChatSse({
    required String message,
    required String sessionId,
  }) async* {
    final uri = Uri.parse('${AgentConfig.baseUrl}/chat/stream');
    final req = http.Request('POST', uri)
      ..headers['content-type'] = 'application/json'
      ..headers['accept'] = 'text/event-stream'
      ..headers.addAll(AgentConfig.authHeader())
      ..body = jsonEncode({'message': message, 'session_id': sessionId});

    final resp = await _client.send(req).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) {
      final body = await resp.stream.bytesToString();
      throw AgentHttpException(resp.statusCode, body);
    }

    String? event;
    final dataBuf = StringBuffer();
    final lines = resp.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in lines) {
      if (line.isEmpty) {
        if (event != null && dataBuf.isNotEmpty) {
          yield parseAgentEvent(event, dataBuf.toString());
        }
        event = null;
        dataBuf.clear();
        continue;
      }
      if (line.startsWith(':')) continue;
      if (line.startsWith('event:')) {
        event = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        dataBuf.write(line.substring(5).trimLeft());
      }
    }
    if (event != null && dataBuf.isNotEmpty) {
      yield parseAgentEvent(event, dataBuf.toString());
    }
  }

  Stream<AgentEvent> _streamChatBlocking({
    required String message,
    required String sessionId,
  }) async* {
    final uri = Uri.parse('${AgentConfig.baseUrl}/chat');
    final resp = await _client
        .post(
          uri,
          headers: {
            'content-type': 'application/json',
            ...AgentConfig.authHeader(),
          },
          body: jsonEncode({'message': message, 'session_id': sessionId}),
        )
        .timeout(const Duration(seconds: 60));
    if (resp.statusCode != 200) {
      throw AgentHttpException(resp.statusCode, resp.body);
    }

    final decoded = jsonDecode(resp.body);
    final json = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{};

    final returnedSession = json['session_id'] as String? ?? sessionId;
    yield SessionEvent(returnedSession);

    final toolCalls = json['tool_calls'];
    if (toolCalls is List) {
      for (final raw in toolCalls) {
        if (raw is! Map) continue;
        final entry = raw.cast<String, dynamic>();
        final name = entry['name'] as String? ?? '';
        final input = _asMap(entry['input']);
        final output = _asMap(entry['output']);
        final isError = entry['isError'] as bool? ?? false;
        yield ToolCallEvent(name, input);
        yield ToolResultEvent(name, input, output, isError);
      }
    }

    final reply = json['reply'] as String? ?? '';
    if (reply.isNotEmpty) {
      yield TextDeltaEvent(reply);
    }
    yield DoneEvent(reply);
  }

  void close() => _client.close();
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const <String, dynamic>{};
}
