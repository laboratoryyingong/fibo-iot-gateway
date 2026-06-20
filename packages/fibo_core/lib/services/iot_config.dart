/// AWS IoT / Cognito configuration for live `fibo-hub-001` shadow access.
///
/// None of these are secrets — the identity pool, IoT endpoint, region and
/// thing name are protected by IAM/Cognito authorization, not by being hidden.
/// Real AWS credentials are vended at runtime by Cognito (never embedded).
class IotConfig {
  static const region = 'ap-southeast-2';
  static const identityPoolId =
      'ap-southeast-2:286dcf12-333c-4226-b7bf-691f0e0d3ac0';
  static const iotEndpoint = 'a2y0p1i6czv1i9-ats.iot.ap-southeast-2.amazonaws.com';
  static const thingName = 'fibo-hub-001';

  static String get cognitoEndpoint =>
      'https://cognito-identity.$region.amazonaws.com/';

  /// Dev bootstrap: use an unauthenticated (guest, read-only) Cognito identity
  /// so the app can read real shadows before the Parse `getAwsIotSession`
  /// token-vend is deployed. Flip to false to use the authenticated
  /// (per-user, read+control) flow.
  static const bool useGuestIdentity = false;

  /// Master switch: drive Spaces/Home/Scenes from live `fibo-hub-001` shadows
  /// (MQTT-WSS) instead of the mock store.
  static const bool useLiveShadows = true;
}
