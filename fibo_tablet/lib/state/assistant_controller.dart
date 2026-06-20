import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fibo_core/services/agent_events.dart';
import 'package:fibo_core/services/claude_agent_client.dart';

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
  final List<String> toolNotes = [];
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
            reply.toolNotes.add(_humanizeTool(name));
            notifyListeners();
          case DoneEvent(reply: final fullReply):
            if (reply.text.isEmpty) reply.text = fullReply;
            finish();
          case AgentErrorEvent(:final message):
            if (reply.text.isEmpty) reply.text = 'Sorry — $message';
            finish();
          case ToolResultEvent():
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

  String _humanizeTool(String name) {
    final words = name
        .split(RegExp(r'[_\s]+'))
        .where((w) => w.isNotEmpty)
        .join(' ');
    return 'Using $words…';
  }

  @override
  void dispose() {
    _sub?.cancel();
    _client.close();
    super.dispose();
  }
}
