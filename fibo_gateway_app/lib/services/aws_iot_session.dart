import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'cognito_credentials_provider.dart';

/// Configures [provider] for the authenticated (per-user) Cognito flow by
/// minting a developer identity token from the Parse `getAwsIotSession` cloud
/// function. Requires a signed-in Parse user and the deployed cloud function.
///
/// Throws if the call fails or the function hasn't been deployed yet — callers
/// fall back to the guest path or the cached layout.
Future<void> configureCognitoFromParse(
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
}
