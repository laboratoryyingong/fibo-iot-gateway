import 'dart:typed_data';

/// BLE constants for the FIBO hub provisioning service
/// (docs/firmware/ble-provisioning-protocol.md §2/§6).
class HubBleContract {
  /// Primary GATT service UUID — the ASCII bytes of `FIBO-HUB-PROV-01`.
  static const serviceUuid = '4649424f-2d48-5542-2d50-524f562d3031';

  /// Advertising name prefix; the exact name comes from the QR label.
  static const namePrefix = 'FIBO-';

  // Endpoint names.
  static const provSession = 'prov-session';
  static const protoVer = 'proto-ver';
  static const hubInfo = 'hub-info';
  static const hubClaim = 'hub-claim';
  static const hubNet = 'hub-net';
  static const hubReset = 'hub-reset';
  static const hubWifi = 'hub-wifi';

  /// Endpoint name → 16-bit characteristic UUID under the primary service.
  /// (`hub-factory` 0xFF57 is factory-station only and deliberately omitted.)
  static const endpointCharacteristicUuids = <String, int>{
    provSession: 0xFF51,
    protoVer: 0xFF52,
    hubInfo: 0xFF53,
    hubClaim: 0xFF54,
    hubNet: 0xFF55,
    hubReset: 0xFF56,
    hubWifi: 0xFF58,
  };
}

/// Raw endpoint I/O with a hub: write [data] to the named protocomm endpoint
/// and return the response bytes. Encryption is layered on top by
/// `HubProvisioningSession`.
abstract class HubTransport {
  Future<Uint8List> sendReceive(String endpoint, Uint8List data);

  Future<void> close();
}
