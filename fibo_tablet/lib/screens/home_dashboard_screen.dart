import 'package:flutter/material.dart';
import 'package:fibo_core/theme/space_tokens.dart';

import '../state/home_controller.dart';
import '../widgets/device_control_card.dart';

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
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
          child: _body(context),
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
        // Fixed-height grid so every device tile has the same height,
        // regardless of how many controls its profile shows.
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 340,
            mainAxisExtent: 308,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: room.devices.length,
          itemBuilder: (_, i) =>
              DeviceControlCard(controller: controller, device: room.devices[i]),
        ),
      ],
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
