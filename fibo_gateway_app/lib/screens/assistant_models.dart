import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../services/agent_device_map.dart';
import '../services/agent_events.dart';
import '../services/claude_agent_client.dart';
import '../services/device_api_client.dart';
import '../services/device_api_models.dart';

enum ChatRole { user, assistant, system }

/// Maps a device to the in-chat control card that should represent it, or null
/// when the device type has no dedicated card. Shared by the store (to decide
/// whether to attach [ChatMessage.deviceControl]) and the message bubble.
String? deviceCardType(AgentDevice device) {
  final type = device.type.toLowerCase();
  if (type.contains('light')) return 'light';
  if (type.contains('curtain') || type.contains('blind') ||
      type.contains('shade')) {
    return 'curtain';
  }
  if (type.contains('lock')) return 'lock';
  if (type.contains('siren')) return 'siren';

  final key = '${device.id} ${device.profile} ${device.name}'.toLowerCase();
  if (type.contains('sensor') || type.contains('alarm') ||
      type.contains('radar') || type.contains('detector')) {
    if (key.contains('smoke')) return 'smoke';
    if (key.contains('presence') || key.contains('radar') ||
        key.contains('motion') || key.contains('occupan')) {
      return 'presence';
    }
  }
  return null;
}

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

  /// App-fetched device list rendered as the "My Home" dashboard card. When
  /// set, the raw agent text is hidden in favour of the card.
  List<AgentDevice>? deviceDashboard;

  /// True while the app is fetching the device list for this turn, so the UI
  /// can show a pending state instead of the agent's interim text.
  bool dashboardPending = false;

  /// A single device whose fresh state is rendered as a device-specific card
  /// (light, curtain, lock, siren, sensor), populated after a `control_device`
  /// or `get_device_status` turn. When set, the device tool chips are hidden.
  AgentDevice? deviceControl;

  /// App-fetched scenes rendered as the tap-to-activate scene grid. Set on a
  /// "scenes" intent turn; hides the raw text reply.
  List<AgentScene>? scenes;

  /// True while the app is fetching scenes for this turn.
  bool scenesPending = false;
}

class AssistantStore extends ChangeNotifier {
  AssistantStore._({ClaudeAgentClient? client, DeviceApiClient? devices})
      : _client = client ?? ClaudeAgentClient(),
        _devices = devices ??
            DeviceApiClient(timeout: const Duration(seconds: 8));

  static final AssistantStore instance = AssistantStore._();

  final ClaudeAgentClient _client;
  final DeviceApiClient _devices;
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

    // For "list my devices"-style turns the app fetches the device list itself
    // and renders the My Home card, instead of relying on the agent to call
    // get_devices (which it does inconsistently). The raw text reply is then
    // hidden in favour of the card.
    if (_looksLikeSceneRequest(text)) {
      assistantMsg.scenesPending = true;
      _loadScenes(assistantMsg);
    } else if (_looksLikeDeviceListRequest(text)) {
      assistantMsg.dashboardPending = true;
      _loadDeviceDashboard(assistantMsg);
    }

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

  static final RegExp _deviceListVerbs =
      RegExp(r'\b(show|list|all|what|which|see|view|display|my)\b');

  bool _looksLikeDeviceListRequest(String text) {
    final s = text.toLowerCase();
    return s.contains('device') && _deviceListVerbs.hasMatch(s);
  }

  bool _looksLikeSceneRequest(String text) {
    final s = text.toLowerCase();
    return s.contains('scene') && _deviceListVerbs.hasMatch(s);
  }

  Future<void> _loadScenes(ChatMessage msg) async {
    try {
      final scenes = await _devices.listScenes();
      if (scenes.isNotEmpty) msg.scenes = scenes;
    } catch (_) {
      // Leave the agent's text reply as the fallback for this turn.
    } finally {
      msg.scenesPending = false;
      notifyListeners();
    }
  }

  /// Runs a scene from the scene grid (best-effort; errors swallowed).
  Future<void> runScene(String sceneId) async {
    try {
      await _devices.runScene(sceneId);
    } catch (_) {
      // Best-effort.
    }
  }

  Future<void> _loadDeviceDashboard(ChatMessage msg) async {
    try {
      final devices = await _devices.listDevices();
      if (devices.isNotEmpty) msg.deviceDashboard = devices;
    } catch (_) {
      // Leave the agent's text reply as the fallback for this turn.
    } finally {
      msg.dashboardPending = false;
      notifyListeners();
    }
  }

  /// After a `control_device`/`get_device_status` turn, fetch the device's
  /// fresh state and attach it so the bubble renders its device-specific card
  /// (when the device type has one).
  void _maybeLoadDeviceControl(ChatMessage msg, ToolResultEvent e) {
    if (e.isError) return;
    if (e.name != 'control_device' && e.name != 'get_device_status') return;
    final id = e.input['device_id'];
    if (id is! String || id.isEmpty) return;
    _loadDeviceControl(msg, id);
  }

  Future<void> _loadDeviceControl(ChatMessage msg, String deviceId) async {
    try {
      final device = await _devices.getDevice(deviceId);
      if (deviceCardType(device) != null) {
        msg.deviceControl = device;
        notifyListeners();
      }
    } catch (_) {
      // Fall back to the chips/text already shown for this turn.
    }
  }

  /// Drives a device from one of the control cards. Optimistic UI lives in the
  /// card; failures are swallowed so the card keeps its local state.
  Future<void> controlDevice(
    String deviceId,
    String action,
    Map<String, dynamic>? params,
  ) async {
    try {
      await _devices.controlDevice(deviceId, action: action, params: params);
    } catch (_) {
      // Best-effort; the card keeps its optimistic state.
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
        _maybeLoadDeviceControl(msg, e);
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
