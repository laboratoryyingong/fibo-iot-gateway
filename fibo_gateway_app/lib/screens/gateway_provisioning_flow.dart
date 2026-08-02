import 'package:fibo_core/services/hub_provisioning/hub_provisioning.dart';

/// Shared state for one BLE provisioning run, passed between the QR-scan,
/// discovery, network, and binding screens via route arguments.
///
/// Session ownership: the network screen closes the session when it is popped
/// without finishing; the binding screen sets [completed] and closes it after
/// a successful claim.
class HubProvisioningFlow {
  HubProvisioningFlow({required this.label, this.reconfigure = false});

  final HubQrLabel label;

  /// True when reconfiguring an already-claimed hub (BOOT 3 s window) instead
  /// of out-of-box onboarding — skips the claim step and enables factory
  /// reset.
  final bool reconfigure;

  HubProvisioningSession? session;
  HubInfo? info;
  bool completed = false;

  Future<void> close() async {
    final active = session;
    session = null;
    if (active != null) {
      await active.close();
    }
  }
}
