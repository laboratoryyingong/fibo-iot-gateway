import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../services/agent_device_map.dart';
import '../services/agent_events.dart';
import '../services/claude_agent_client.dart';

enum ChatRole { user, assistant, system }

enum AssistantStreamState { idle, awaitingFirstByte, streaming, error }

class ToolCallChipState {
  ToolCallChipState({
    required this.key,
    required this.name,
    required this.input,
    this.output,
    this.isError,
  });

  final String key;
  final String name;
  final Map<String, dynamic> input;
  Map<String, dynamic>? output;
  bool? isError;

  bool get isPending => output == null;
  bool get isSuccess => output != null && isError == false;
  bool get isFailure =>
      output != null &&
      isError == true &&
      !requiresConfirmation &&
      !didNotConverge;
  bool get requiresConfirmation =>
      isError == true && (output?['requires_confirmation'] == true);
  bool get didNotConverge =>
      isError == true && (output?['converged'] == false);
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.role,
    this.text = '',
    List<ToolCallChipState>? toolCalls,
    DateTime? createdAt,
    this.isStreaming = false,
  })  : toolCalls = toolCalls ?? <ToolCallChipState>[],
        createdAt = createdAt ?? DateTime.now();

  final String id;
  final ChatRole role;
  String text;
  final List<ToolCallChipState> toolCalls;
  final DateTime createdAt;
  bool isStreaming;
}

class AssistantStore extends ChangeNotifier {
  AssistantStore._({ClaudeAgentClient? client})
      : _client = client ?? ClaudeAgentClient();

  static final AssistantStore instance = AssistantStore._();

  final ClaudeAgentClient _client;
  final Uuid _uuid = const Uuid();

  String _sessionId = const Uuid().v4();
  String get sessionId => _sessionId;

  final List<ChatMessage> _messages = <ChatMessage>[];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  AssistantStreamState _state = AssistantStreamState.idle;
  AssistantStreamState get state => _state;

  String? _errorText;
  String? get errorText => _errorText;

  StreamSubscription<AgentEvent>? _sub;
  ChatMessage? _streamingMessage;

  int get userTurnCount =>
      _messages.where((m) => m.role == ChatRole.user).length;

  Future<void> sendMessage(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty) return;
    if (_state != AssistantStreamState.idle) return;

    _errorText = null;
    _messages.add(ChatMessage(
      id: _uuid.v4(),
      role: ChatRole.user,
      text: text,
    ));

    final assistantMsg = ChatMessage(
      id: _uuid.v4(),
      role: ChatRole.assistant,
      isStreaming: true,
    );
    _messages.add(assistantMsg);
    _streamingMessage = assistantMsg;
    _state = AssistantStreamState.awaitingFirstByte;
    notifyListeners();

    try {
      final stream = _client.streamChat(
        message: text,
        sessionId: _sessionId,
      );
      _sub = stream.listen(
        _onEvent,
        onError: _onStreamError,
        onDone: _onStreamDone,
        cancelOnError: true,
      );
    } catch (err) {
      _failStreamingMessage(err.toString());
    }
  }

  Future<void> cancel() async {
    final sub = _sub;
    _sub = null;
    if (sub != null) {
      await sub.cancel();
    }
    if (_streamingMessage != null) {
      _streamingMessage!.isStreaming = false;
      if (_streamingMessage!.text.isEmpty &&
          _streamingMessage!.toolCalls.isEmpty) {
        _streamingMessage!.text = '(cancelled)';
      }
      _streamingMessage = null;
    }
    _state = AssistantStreamState.idle;
    notifyListeners();
  }

  void resetSession() {
    _sub?.cancel();
    _sub = null;
    _streamingMessage = null;
    _messages.clear();
    _sessionId = _uuid.v4();
    _state = AssistantStreamState.idle;
    _errorText = null;
    notifyListeners();
  }

  void _onEvent(AgentEvent event) {
    final msg = _streamingMessage;
    if (msg == null) return;

    switch (event) {
      case SessionEvent e:
        if (e.sessionId.isNotEmpty) _sessionId = e.sessionId;
      case TextDeltaEvent e:
        msg.text = '${msg.text}${e.delta}';
        _state = AssistantStreamState.streaming;
      case ToolCallEvent e:
        final key = _toolCallKey(msg, e.name, e.input);
        msg.toolCalls.add(ToolCallChipState(
          key: key,
          name: e.name,
          input: e.input,
        ));
        _state = AssistantStreamState.streaming;
      case ToolResultEvent e:
        final key = _toolCallKey(msg, e.name, e.input, matchExisting: true);
        final chip = _findChip(msg, key) ?? _findFirstPendingChip(msg, e.name);
        if (chip != null) {
          chip.output = e.output;
          chip.isError = e.isError;
        } else {
          msg.toolCalls.add(ToolCallChipState(
            key: key,
            name: e.name,
            input: e.input,
            output: e.output,
            isError: e.isError,
          ));
        }
        AgentDeviceSync.applyToolResult(e);
      case DoneEvent _:
        msg.isStreaming = false;
        _state = AssistantStreamState.idle;
        _streamingMessage = null;
      case AgentErrorEvent e:
        _failStreamingMessage(e.message);
      case UnknownEvent _:
        break; // ignore future event kinds gracefully
    }
    notifyListeners();
  }

  void _onStreamError(Object error, StackTrace _) {
    _failStreamingMessage(error.toString());
  }

  void _onStreamDone() {
    // If the stream closed without emitting DoneEvent, finalize gracefully.
    if (_streamingMessage != null) {
      _streamingMessage!.isStreaming = false;
      _streamingMessage = null;
      _state = AssistantStreamState.idle;
      notifyListeners();
    }
    _sub = null;
  }

  void _failStreamingMessage(String message) {
    final msg = _streamingMessage;
    if (msg != null) {
      msg.isStreaming = false;
      if (msg.text.isEmpty) {
        msg.text = '(connection error — tap retry)';
      }
    }
    _streamingMessage = null;
    _errorText = message;
    _state = AssistantStreamState.error;
    notifyListeners();

    // Reset to idle so the user can try again.
    _state = AssistantStreamState.idle;
  }

  String _toolCallKey(
    ChatMessage msg,
    String name,
    Map<String, dynamic> input, {
    bool matchExisting = false,
  }) {
    final base = '$name|${jsonEncode(input)}';
    if (matchExisting) {
      // Caller will look up an existing chip; we provide the un-indexed base.
      return base;
    }
    final occurrences = msg.toolCalls.where((c) => c.key.startsWith(base)).length;
    return '$base#$occurrences';
  }

  ToolCallChipState? _findChip(ChatMessage msg, String baseKey) {
    for (final chip in msg.toolCalls) {
      if (chip.key.startsWith(baseKey) && chip.isPending) return chip;
    }
    return null;
  }

  ToolCallChipState? _findFirstPendingChip(ChatMessage msg, String name) {
    for (final chip in msg.toolCalls) {
      if (chip.name == name && chip.isPending) return chip;
    }
    return null;
  }
}
