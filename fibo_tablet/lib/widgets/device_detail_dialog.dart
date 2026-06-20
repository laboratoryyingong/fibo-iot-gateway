import 'package:flutter/material.dart';
import 'package:fibo_core/services/home_graph.dart';
import 'package:fibo_core/theme/space_tokens.dart';

import '../state/home_controller.dart';
import 'device_icons.dart';

/// Centered control panel for a single device, opened by tapping its tile.
/// Mirrors the phone's per-profile control surface (power, brightness, lock,
/// curtain position) while reading/writing live shadow state.
Future<void> showDeviceDetail(
  BuildContext context,
  HomeController controller,
  HomeDevice device,
) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => _DeviceDetailDialog(controller: controller, device: device),
  );
}

class _DeviceDetailDialog extends StatelessWidget {
  const _DeviceDetailDialog({required this.controller, required this.device});

  final HomeController controller;
  final HomeDevice device;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: SpaceColors.bgSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final view = controller.viewFor(device);
            final on = view.isOn && view.kind != DeviceKind.sensor;
            return Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          device.displayName,
                          style: SpaceTextStyles.cardTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded,
                            color: SpaceColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Hero icon.
                  Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: on
                            ? SpaceColors.accentStart.withValues(alpha: 0.18)
                            : SpaceColors.bgElevated,
                      ),
                      child: Icon(
                        iconForProfile(device.profile),
                        size: 44,
                        color:
                            on ? SpaceColors.accentStart : SpaceColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      view.online
                          ? (view.valueLabel ?? (on ? 'On' : 'Off'))
                          : 'Offline',
                      style: SpaceTextStyles.cardMeta,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ..._controls(view),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _controls(DeviceView view) {
    if (!view.online) return const [];
    final widgets = <Widget>[];

    if (view.isToggle || view.isLock) {
      widgets.add(_ToggleRow(
        label: view.isLock ? 'Locked' : 'Power',
        value: view.isOn,
        onChanged: (_) => controller.toggle(device),
      ));
    }
    if (view.hasSlider) {
      final isCurtain = view.kind == DeviceKind.curtain;
      if (!isCurtain && !view.isOn) return widgets; // hide brightness when off
      widgets.add(const SizedBox(height: 16));
      widgets.add(_SliderRow(
        label: isCurtain ? 'Position' : 'Brightness',
        percent: view.levelPercent ?? 0,
        onChanged: (p) => controller.setPercent(device, p),
      ));
    }
    if (view.kind == DeviceKind.sensor) {
      widgets.add(_ReadOnlyRow(value: view.valueLabel ?? '—'));
    }
    return widgets;
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 8, 12, 8),
      decoration: BoxDecoration(
        color: SpaceColors.bgElevated,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: SpaceTextStyles.pillTitle)),
          Switch.adaptive(
            value: value,
            activeThumbColor: SpaceColors.accentStart,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.percent,
    required this.onChanged,
  });

  final String label;
  final int percent;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: BoxDecoration(
        color: SpaceColors.bgElevated,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: SpaceTextStyles.pillTitle)),
              Text('$percent%', style: SpaceTextStyles.pillMeta),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              activeTrackColor: SpaceColors.accentStart,
              inactiveTrackColor: SpaceColors.bgSurface,
              thumbColor: SpaceColors.accentStart,
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: percent.toDouble().clamp(0, 100),
              max: 100,
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SpaceColors.bgElevated,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(value, style: SpaceTextStyles.cardTitle),
    );
  }
}
