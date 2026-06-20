import 'dart:convert';

sealed class AgentEvent {
  const AgentEvent();
}

class SessionEvent extends AgentEvent {
  const SessionEvent(this.sessionId);
  final String sessionId;
}

class TextDeltaEvent extends AgentEvent {
  const TextDeltaEvent(this.delta);
  final String delta;
}

class ToolCallEvent extends AgentEvent {
  const ToolCallEvent(this.name, this.input);
  final String name;
  final Map<String, dynamic> input;
}

class ToolResultEvent extends AgentEvent {
  const ToolResultEvent(this.name, this.input, this.output, this.isError);
  final String name;
  final Map<String, dynamic> input;
  final Map<String, dynamic> output;
  final bool isError;

  bool get requiresConfirmation =>
      isError && output['requires_confirmation'] == true;
}

class DoneEvent extends AgentEvent {
  const DoneEvent(this.reply);
  final String reply;
}

class AgentErrorEvent extends AgentEvent {
  const AgentErrorEvent(this.message);
  final String message;
}

class UnknownEvent extends AgentEvent {
  const UnknownEvent(this.name, this.data);
  final String name;
  final Map<String, dynamic> data;
}

AgentEvent parseAgentEvent(String name, String dataJson) {
  final dynamic decoded = jsonDecode(dataJson);
  final Map<String, dynamic> json = decoded is Map<String, dynamic>
      ? decoded
      : const <String, dynamic>{};

  switch (name) {
    case 'session':
      return SessionEvent(json['session_id'] as String? ?? '');
    case 'text':
      return TextDeltaEvent(json['delta'] as String? ?? '');
    case 'tool_call':
      return ToolCallEvent(
        json['name'] as String? ?? '',
        _mapOf(json['input']),
      );
    case 'tool_result':
      return ToolResultEvent(
        json['name'] as String? ?? '',
        _mapOf(json['input']),
        _mapOf(json['output']),
        json['isError'] as bool? ?? false,
      );
    case 'done':
      return DoneEvent(json['reply'] as String? ?? '');
    case 'error':
      return AgentErrorEvent(json['message'] as String? ?? 'unknown');
    default:
      return UnknownEvent(name, json);
  }
}

Map<String, dynamic> _mapOf(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const <String, dynamic>{};
}
