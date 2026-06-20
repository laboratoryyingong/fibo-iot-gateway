import 'package:flutter/material.dart';
import 'package:fibo_core/services/home_graph.dart';
import 'package:fibo_core/theme/space_tokens.dart';

import '../state/home_controller.dart';
import '../widgets/device_icons.dart';
import '../widgets/device_detail_dialog.dart';

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

/// Read-only device tile in the phone's grid style: a vertical gradient card
/// with a centered icon, name and live state. Tapping opens the detail panel
/// for full control.
class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.controller, required this.device});

  final HomeController controller;
  final HomeDevice device;

  @override
  Widget build(BuildContext context) {
    final view = controller.viewFor(device);
    final on = view.isOn && view.kind != DeviceKind.sensor;
    final accent = on ? SpaceColors.accentStart : SpaceColors.textPrimary;
    return Opacity(
      opacity: view.online ? 1 : 0.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => showDeviceDetail(context, controller, device),
        child: Container(
          width: 168,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [SpaceColors.bgElevated, SpaceColors.bgSurface],
            ),
            border: Border.all(
              color: on ? SpaceColors.accentStart : SpaceColors.stroke,
            ),
          ),
          child: Column(
            children: [
              Icon(iconForProfile(device.profile), color: accent, size: 30),
              const SizedBox(height: 14),
              Text(
                device.displayName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: SpaceTextStyles.pillTitle,
              ),
              const SizedBox(height: 4),
              Text(
                view.online ? (view.valueLabel ?? (on ? 'On' : 'Off')) : 'Offline',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SpaceTextStyles.pillMeta,
              ),
            ],
          ),
        ),
      ),
    );
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
