import 'dart:convert';

import 'package:http/http.dart' as http;

import 'aws_credentials.dart';
import 'iot_config.dart';

/// Obtains temporary AWS credentials from a Cognito Identity Pool, caching them
/// until they near expiry.
///
/// Dev path ([IotConfig.useGuestIdentity] = true): unauthenticated "guest"
/// identity (read-only), no backend needed.
///
/// Prod path: pass a developer-auth `(identityId, token)` minted by the Parse
/// `getAwsIotSession` cloud function via [setDeveloperToken]; credentials then
/// carry the authenticated (read+control) role.
class CognitoCredentialsProvider {
  CognitoCredentialsProvider({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  AwsCredentials? _cached;
  String? _identityId;
  String? _devToken;

  /// Supply the developer-auth identity + token from the Parse backend. Clears
  /// any cached guest credentials.
  void setDeveloperToken({required String identityId, required String token}) {
    _identityId = identityId;
    _devToken = token;
    _cached = null;
  }

  Future<AwsCredentials> getCredentials() async {
    final cached = _cached;
    if (cached != null && !cached.isExpired) return cached;
    final creds = await _fetch();
    _cached = creds;
    return creds;
  }

  Future<AwsCredentials> _fetch() async {
    // 1. Resolve an identity id (guest GetId, or the developer identity).
    final identityId = _devToken != null
        ? _identityId!
        : (_identityId ??= await _getId());

    // 2. Exchange it for temporary credentials.
    final body = <String, dynamic>{'IdentityId': identityId};
    if (_devToken != null) {
      body['Logins'] = {'cognito-identity.amazonaws.com': _devToken};
    }
    final json = await _call('GetCredentialsForIdentity', body);
    return AwsCredentials.fromCognito(json);
  }

  Future<String> _getId() async {
    final json = await _call('GetId', {
      'IdentityPoolId': IotConfig.identityPoolId,
    });
    return json['IdentityId'] as String;
  }

  Future<Map<String, dynamic>> _call(
    String action,
    Map<String, dynamic> body,
  ) async {
    final resp = await _client
        .post(
          Uri.parse(IotConfig.cognitoEndpoint),
          headers: {
            'content-type': 'application/x-amz-json-1.1',
            'x-amz-target': 'AWSCognitoIdentityService.$action',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) {
      throw Exception('Cognito $action failed (${resp.statusCode}): ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  void close() => _client.close();
}
