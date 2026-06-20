/// Temporary AWS credentials vended by Cognito for signing IoT requests.
class AwsCredentials {
  const AwsCredentials({
    required this.accessKeyId,
    required this.secretKey,
    required this.sessionToken,
    required this.expiration,
  });

  final String accessKeyId;
  final String secretKey;
  final String sessionToken;
  final DateTime expiration;

  /// Refresh a little before the hard expiry to avoid mid-request failures.
  bool get isExpired =>
      DateTime.now().isAfter(expiration.subtract(const Duration(minutes: 2)));

  factory AwsCredentials.fromCognito(Map<String, dynamic> json) {
    final c = json['Credentials'] as Map<String, dynamic>;
    final exp = c['Expiration'];
    // Cognito returns Expiration as epoch seconds (number).
    final expiration = exp is num
        ? DateTime.fromMillisecondsSinceEpoch((exp * 1000).round(), isUtc: true)
        : DateTime.now().add(const Duration(minutes: 50));
    return AwsCredentials(
      accessKeyId: c['AccessKeyId'] as String,
      secretKey: c['SecretKey'] as String,
      sessionToken: c['SessionToken'] as String,
      expiration: expiration,
    );
  }
}
