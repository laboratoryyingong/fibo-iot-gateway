import 'package:flutter/material.dart';
import 'package:fibo_core/services/home_graph.dart';
import 'package:fibo_core/theme/space_tokens.dart';

import '../state/home_controller.dart';

/// The Home pane: live rooms + device grid from the home graph. Device on/off
/// state and quick-control land in the next phase.
class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(32, 28, 32, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Home', style: SpaceTextStyles.sectionTitle),
                  const SizedBox(width: 12),
                  if (controller.graph != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        controller.graph!.homeName,
                        style: SpaceTextStyles.sectionCount,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(child: _body(context)),
            ],
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context) {
    switch (controller.state) {
      case HomeLoadState.loading:
        return const Center(
          child: CircularProgressIndicator(color: SpaceColors.accentStart),
        );
      case HomeLoadState.error:
        return _ErrorState(
          message: controller.error ?? 'Could not load your home.',
          onRetry: controller.load,
        );
      case HomeLoadState.ready:
        final rooms = controller.rooms;
        if (rooms.isEmpty) {
          return const _EmptyState();
        }
        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 28),
          itemCount: rooms.length,
          separatorBuilder: (_, _) => const SizedBox(height: 28),
          itemBuilder: (_, i) =>
              _RoomSection(controller: controller, room: rooms[i]),
        );
    }
  }
}

class _RoomSection extends StatelessWidget {
  const _RoomSection({required this.controller, required this.room});

  final HomeController controller;
  final RoomGroup room;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(room.name, style: SpaceTextStyles.cardTitle),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '${room.devices.length}',
                style: SpaceTextStyles.pillMeta,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (final d in room.devices)
              _DeviceCard(controller: controller, device: d),
          ],
        ),
      ],
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.controller, required this.device});

  final HomeController controller;
  final HomeDevice device;

  @override
  Widget build(BuildContext context) {
    final view = controller.viewFor(device);
    final accent = view.isOn && view.kind != DeviceKind.sensor;
    final card = Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SpaceColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent ? SpaceColors.accentStart : SpaceColors.stroke,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent
                      ? SpaceColors.accentStart.withValues(alpha: 0.18)
                      : SpaceColors.bgElevated,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  _iconForProfile(device.profile),
                  color: accent
                      ? SpaceColors.accentStart
                      : SpaceColors.textPrimary,
                  size: 20,
                ),
              ),
              const Spacer(),
              _control(view),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            device.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SpaceTextStyles.pillTitle,
          ),
          const SizedBox(height: 2),
          Text(
            view.online ? (view.valueLabel ?? _label(view.kind)) : 'Offline',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SpaceTextStyles.pillMeta,
          ),
          if (view.hasSlider && (view.isOn || view.kind == DeviceKind.curtain))
            _slider(view),
        ],
      ),
    );
    return Opacity(opacity: view.online ? 1 : 0.5, child: card);
  }

  /// Trailing control: a switch for toggleable devices and locks; nothing for
  /// read-only sensors.
  Widget _control(DeviceView view) {
    if (view.kind == DeviceKind.sensor) return const SizedBox.shrink();
    return Switch.adaptive(
      value: view.isOn,
      activeThumbColor: SpaceColors.accentStart,
      onChanged: view.online ? (_) => controller.toggle(device) : null,
    );
  }

  Widget _slider(DeviceView view) {
    final pct = (view.levelPercent ?? 0).toDouble();
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 3,
        activeTrackColor: SpaceColors.accentStart,
        inactiveTrackColor: SpaceColors.bgElevated,
        thumbColor: SpaceColors.accentStart,
        overlayShape: SliderComponentShape.noOverlay,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
      ),
      child: Slider(
        value: pct.clamp(0, 100),
        max: 100,
        onChanged: view.online
            ? (v) => controller.setPercent(device, v.round())
            : null,
      ),
    );
  }

  String _label(DeviceKind kind) {
    switch (kind) {
      case DeviceKind.light:
      case DeviceKind.dimmableLight:
        return 'Light';
      case DeviceKind.onoff:
        return 'Switch';
      case DeviceKind.curtain:
        return 'Curtain';
      case DeviceKind.lock:
        return 'Lock';
      case DeviceKind.siren:
        return 'Siren';
      case DeviceKind.sensor:
        return 'Sensor';
    }
  }
}

/// Maps a device profile to a display icon (mirrors the phone app).
IconData _iconForProfile(String profile) {
  switch (profile) {
    case 'color_light':
    case 'dimmable_light':
      return Icons.lightbulb_outline;
    case 'onoff_actuator':
      return Icons.toggle_on_outlined;
    case 'curtain':
      return Icons.blinds_outlined;
    case 'door_lock':
      return Icons.lock_outline;
    case 'siren_actuator':
      return Icons.notifications_active_outlined;
    case 'smoke_alarm':
      return Icons.local_fire_department_outlined;
    case 'ias_sensor':
      return Icons.directions_walk_outlined;
    case 'mmwave_sensor':
      return Icons.sensors_outlined;
    case 'multi_sensor':
      return Icons.thermostat_outlined;
    case 'button_remote':
      return Icons.radio_button_checked;
    default:
      return Icons.devices_other_outlined;
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined,
              size: 52, color: SpaceColors.textMuted),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: SpaceTextStyles.cardMeta,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: SpaceColors.textPrimary,
              side: const BorderSide(color: SpaceColors.stroke),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.dashboard_outlined,
              size: 52, color: SpaceColors.textMuted),
          const SizedBox(height: 16),
          Text('No devices in this home yet.',
              style: SpaceTextStyles.cardMeta),
        ],
      ),
    );
  }
}
