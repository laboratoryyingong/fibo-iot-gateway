class GatewayConfig {
  final String gwId;
  final String host;
  final int port;
  final bool secure; // wss?
  final bool useWebSocket;
  final String wsPath;
  final String? username;
  final String? password;

  const GatewayConfig({
    required this.gwId,
    required this.host,
    required this.port,
    required this.secure,
    required this.useWebSocket,
    required this.wsPath,
    this.username,
    this.password,
  });

  GatewayConfig copyWith({
    String? gwId,
    String? host,
    int? port,
    bool? secure,
    bool? useWebSocket,
    String? wsPath,
    String? username,
    String? password,
  }) {
    return GatewayConfig(
      gwId: gwId ?? this.gwId,
      host: host ?? this.host,
      port: port ?? this.port,
      secure: secure ?? this.secure,
      useWebSocket: useWebSocket ?? this.useWebSocket,
      wsPath: wsPath ?? this.wsPath,
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }

  factory GatewayConfig.fromJson(Map<String, dynamic> j) => GatewayConfig(
    gwId: j['gwId'] ?? 'gw-0001',
    host: j['host'],
    port: j['port'] ?? (j['secure'] == true ? 443 : 80),
    secure: j['secure'] ?? false,
    useWebSocket: j['useWebSocket'] ?? true,
    wsPath: j['wsPath'] ?? '/mqtt',
    username: j['username'],
    password: j['password'],
  );

  Map<String, dynamic> toJson() => {
    'gwId': gwId,
    'host': host,
    'port': port,
    'secure': secure,
    'useWebSocket': useWebSocket,
    'wsPath': wsPath,
    'username': username,
    'password': password,
  };
}
