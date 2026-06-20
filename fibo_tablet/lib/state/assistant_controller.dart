import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fibo_core/services/agent_events.dart';
import 'package:fibo_core/services/claude_agent_client.dart';

/// A tool the agent invoked during a turn, with its result once it lands.
class ToolResult {
  ToolResult({required this.name});

  final String name;
  bool pending = true;
  bool isError = false;
  Map<String, dynamic>? output;
}

/// One chat turn rendered in the assistant panel.
class ChatMessage {
  ChatMessage({
    required this.fromUser,
    this.text = '',
    this.streaming = false,
  });

  final bool fromUser;
  String text;
  bool streaming;
  final List<ToolResult> tools = [];
}

/// Drives the assistant conversation: sends a message and folds the streamed
/// agent events (text deltas, tool calls, done/error) into [messages].
class AssistantController extends ChangeNotifier {
  final _client = ClaudeAgentClient();
  final List<ChatMessage> messages = [];

  // Stable per-app-session id; the server may hand back its own via SessionEvent.
  String _sessionId = 'tablet-${DateTime.now().millisecondsSinceEpoch}';
  bool sending = false;
  StreamSubscription<AgentEvent>? _sub;

  void send(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || sending) return;

    messages.add(ChatMessage(fromUser: true, text: trimmed));
    final reply = ChatMessage(fromUser: false, streaming: true);
    messages.add(reply);
    sending = true;
    notifyListeners();

    void finish() {
      reply.streaming = false;
      sending = false;
      _sub = null;
      notifyListeners();
    }

    _sub = _client.streamChat(message: trimmed, sessionId: _sessionId).listen(
      (event) {
        switch (event) {
          case SessionEvent(:final sessionId):
            _sessionId = sessionId;
          case TextDeltaEvent(:final delta):
            reply.text += delta;
            notifyListeners();
          case ToolCallEvent(:final name):
            reply.tools.add(ToolResult(name: name));
            notifyListeners();
          case ToolResultEvent(:final name, :final output, :final isError):
            ToolResult? tool;
            for (final t in reply.tools) {
              if (t.name == name && t.pending) {
                tool = t;
                break;
              }
            }
            if (tool == null) {
              tool = ToolResult(name: name);
              reply.tools.add(tool);
            }
            tool
              ..pending = false
              ..isError = isError
              ..output = output;
            notifyListeners();
          case DoneEvent(reply: final fullReply):
            if (reply.text.isEmpty) reply.text = fullReply;
            finish();
          case AgentErrorEvent(:final message):
            if (reply.text.isEmpty) reply.text = 'Sorry — $message';
            finish();
          case UnknownEvent():
            break;
        }
      },
      onError: (_) {
        if (reply.text.isEmpty) {
          reply.text = 'Could not reach the assistant. Check your connection.';
        }
        finish();
      },
      onDone: () {
        if (sending) finish();
      },
    );
  }

  /// Stops an in-flight reply, keeping whatever has streamed so far.
  void cancel() {
    _sub?.cancel();
    _sub = null;
    if (messages.isNotEmpty && !messages.last.fromUser) {
      messages.last.streaming = false;
    }
    sending = false;
    notifyListeners();
  }

  /// Clears the conversation to start fresh.
  void newChat() {
    if (sending) return;
    _sub?.cancel();
    _sub = null;
    messages.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _client.close();
    super.dispose();
  }
}
