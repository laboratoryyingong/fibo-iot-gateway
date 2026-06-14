import 'agent_config.local.dart' as local;

class AgentConfig {
  static const String baseUrl = local.baseUrl;
  static const bool useStreaming = true;

  /// Shared secret for the agent's `Authorization: Bearer <key>` header.
  /// Empty string ⇒ no header sent (the server runs open, dev only).
  ///
  /// ⚠️ This is a single shared secret, NOT per-user auth. Never ship it in a
  /// production client; proxy through your own backend that holds the key and
  /// authenticates users. See docs/claude-agent/APP-INTEGRATION.md §2 & §7.
  static const String apiKey = local.apiKey;

  /// Whether the Spaces dashboard should read/write through the live REST
  /// device API instead of the local mock store. Requires a reachable
  /// [baseUrl]. See docs/claude-agent/APP-INTEGRATION.md §4.
  static const bool useLiveDevices = local.useLiveDevices;

  bool get hasApiKey => apiKey.isNotEmpty;

  /// Authorization header to merge into every agent request, or an empty map
  /// when no key is configured (open dev server).
  static Map<String, String> authHeader() =>
      apiKey.isEmpty ? const {} : {'authorization': 'Bearer $apiKey'};
}
