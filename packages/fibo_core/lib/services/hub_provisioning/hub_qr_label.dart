import 'dart:convert';

/// Parsed FIBO hub QR label, printed on the enclosure at the factory.
///
/// Wire format (version 1), see docs/firmware/ble-provisioning-protocol.md §4:
/// `{"v":1,"sn":"FIBO-A1B2C3D4E5F6","ble":"FIBO-D4E5F6","pop":"x7k2mn9p"}`
class HubQrLabel {
  const HubQrLabel({
    required this.version,
    required this.serial,
    required this.bleName,
    required this.pop,
  });

  /// Label schema version. The app should prompt an update on unknown values.
  static const supportedVersion = 1;

  final int version;

  /// Device serial (`sn`); matches `hub-info.serial` and is also the AWS IoT
  /// thing name. Empty on development boards that skipped factory provisioning.
  final String serial;

  /// BLE advertising name (`ble`), e.g. `FIBO-D4E5F6`.
  final String bleName;

  /// Proof-of-possession for the security1 handshake.
  final String pop;

  bool get isSupportedVersion => version == supportedVersion;

  /// Parses the QR payload. Returns null when the content is not a FIBO hub
  /// label (not JSON, or missing the required fields).
  static HubQrLabel? tryParse(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw.trim());
    } catch (_) {
      return null;
    }
    if (decoded is! Map) return null;

    final version = decoded['v'];
    final bleName = decoded['ble'];
    final pop = decoded['pop'];
    if (version is! int || bleName is! String || pop is! String) return null;
    if (bleName.isEmpty || pop.isEmpty) return null;

    return HubQrLabel(
      version: version,
      serial: decoded['sn'] is String ? decoded['sn'] as String : '',
      bleName: bleName,
      pop: pop,
    );
  }
}
