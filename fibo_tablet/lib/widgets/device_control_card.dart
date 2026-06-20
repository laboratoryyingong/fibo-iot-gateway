import 'package:flutter/material.dart';
import 'package:fibo_core/services/home_graph.dart';
import 'package:fibo_core/theme/space_tokens.dart';

import '../state/home_controller.dart';
import 'device_icons.dart';

/// A device tile that embeds the full control surface inline: a hero icon, live
/// state, and per-profile controls (power/lock toggle, brightness/curtain
/// slider, sensor read-out). Reads/writes live shadow state via [controller].
class DeviceControlCard extends StatelessWidget {
  const DeviceControlCard({
    super.key,
    required this.controller,
    required this.device,
  });

  final HomeController controller;
  final HomeDevice device;

  @override
  Widget build(BuildContext context) {
    final view = controller.viewFor(device);
    final on = view.isOn && view.kind != DeviceKind.sensor;
    return Opacity(
      opacity: view.online ? 1 : 0.5,
      child: Container(
        width: 300,
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero icon.
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: on
                      ? SpaceColors.accentStart.withValues(alpha: 0.18)
                      : SpaceColors.bgBase,
                ),
                child: Icon(
                  iconForProfile(device.profile),
                  size: 34,
                  color: on ? SpaceColors.accentStart : SpaceColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              device.displayName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SpaceTextStyles.pillTitle,
            ),
            const SizedBox(height: 2),
            Text(
              view.online ? (view.valueLabel ?? (on ? 'On' : 'Off')) : 'Offline',
              textAlign: TextAlign.center,
              style: SpaceTextStyles.pillMeta,
            ),
            ..._controls(view),
          ],
        ),
      ),
    );
  }

  List<Widget> _controls(DeviceView view) {
    if (!view.online) return const [];
    final widgets = <Widget>[];

    if (view.isToggle || view.isLock) {
      widgets.add(const SizedBox(height: 14));
      widgets.add(_ToggleRow(
        label: view.isLock ? 'Locked' : 'Power',
        value: view.isOn,
        onChanged: (_) => controller.toggle(device),
      ));
    }
    if (view.hasSlider) {
      final isCurtain = view.kind == DeviceKind.curtain;
      if (isCurtain || view.isOn) {
        widgets.add(const SizedBox(height: 10));
        widgets.add(_SliderRow(
          label: isCurtain ? 'Position' : 'Brightness',
          percent: view.levelPercent ?? 0,
          onChanged: (p) => controller.setPercent(device, p),
        ));
      }
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
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      decoration: BoxDecoration(
        color: SpaceColors.bgBase,
        borderRadius: BorderRadius.circular(12),
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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      decoration: BoxDecoration(
        color: SpaceColors.bgBase,
        borderRadius: BorderRadius.circular(12),
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
