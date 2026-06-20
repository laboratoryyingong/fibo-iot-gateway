import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'cognito_credentials_provider.dart';

/// The result of `getAwsIotSession`: the user's home/gateway scope plus the
/// Cognito developer identity (already applied to the credentials provider).
class AwsIotSession {
  const AwsIotSession({
    required this.homeId,
    required this.gatewayId,
    required this.role,
  });

  final String homeId;
  final String? gatewayId;
  final String role;
}

/// Configures [provider] for the authenticated (per-user) Cognito flow by
/// minting a developer identity token from the Parse `getAwsIotSession` cloud
/// function, and returns the home/gateway scope. Requires a signed-in Parse
/// user and the deployed cloud function.
Future<AwsIotSession> configureCognitoFromParse(
  CognitoCredentialsProvider provider,
) async {
  final fn = ParseCloudFunction('getAwsIotSession');
  final response = await fn.execute();
  if (!response.success || response.result is! Map) {
    throw Exception('getAwsIotSession failed: ${response.error?.message}');
  }
  final result = (response.result as Map).cast<String, dynamic>();
  final identity = (result['awsIdentity'] as Map?)?.cast<String, dynamic>();
  final identityId = identity?['identityId'] as String?;
  final token = identity?['developerToken'] as String?;
  if (identityId == null || token == null) {
    throw Exception('getAwsIotSession returned no developer identity yet.');
  }
  provider.setDeveloperToken(identityId: identityId, token: token);
  return AwsIotSession(
    homeId: result['homeId']?.toString() ?? '',
    gatewayId: result['gatewayId']?.toString(),
    role: result['role']?.toString() ?? 'member',
  );
}
