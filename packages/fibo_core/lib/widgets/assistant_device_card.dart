import 'package:flutter/material.dart';

import '../assistant_models.dart';
import 'package:fibo_core/services/device_api_models.dart';
import 'assistant_curtain_card.dart';
import 'assistant_light_card.dart';
import 'assistant_lock_card.dart';
import 'assistant_presence_card.dart';
import 'assistant_siren_card.dart';
import 'assistant_smoke_card.dart';

/// Renders the in-chat control card matching the device's type. The type is
/// resolved by [deviceCardType]; controls are routed to the live device via
/// [AssistantStore.controlDevice].
class AssistantDeviceCard extends StatelessWidget {
  const AssistantDeviceCard({super.key, required this.device});

  final AgentDevice device;

  void _control(String action, Map<String, dynamic>? params) =>
      AssistantStore.instance.controlDevice(device.id, action, params);

  @override
  Widget build(BuildContext context) {
    switch (deviceCardType(device)) {
      case 'light':
        return AssistantLightCard(device: device, onControl: _control);
      case 'curtain':
        return AssistantCurtainCard(device: device, onControl: _control);
      case 'lock':
        return AssistantLockCard(device: device, onControl: _control);
      case 'siren':
        return AssistantSirenCard(device: device, onControl: _control);
      case 'presence':
        return AssistantPresenceCard(device: device, onControl: _control);
      case 'smoke':
        return AssistantSmokeCard(device: device, onControl: _control);
      default:
        return const SizedBox.shrink();
    }
  }
}
