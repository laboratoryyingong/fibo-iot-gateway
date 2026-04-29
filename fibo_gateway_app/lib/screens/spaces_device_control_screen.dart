import 'package:flutter/material.dart';

import '../theme/space_tokens.dart';
import 'space_device_types.dart';
import 'space_models.dart';

class SpacesDeviceControlScreen extends StatefulWidget {
  const SpacesDeviceControlScreen({super.key});

  @override
  State<SpacesDeviceControlScreen> createState() =>
      _SpacesDeviceControlScreenState();
}

class _SpacesDeviceControlScreenState extends State<SpacesDeviceControlScreen> {
  double _temperature = 22;
  double _fanSpeed = 0.4;
  double _acTemperature = 24;
  int _acModeIndex = 1;
  int _purifierModeIndex = 0;
  bool _manualMode = false;
  double _speakerVolume = 0.55;
  final List<double> _eq = [0.3, 0.5, 0.7, 0.45, 0.6];
  double _lightBrightness = 0.6;
  double _lightWarmth = 0.5;
  double _bulbBrightness = 0.7;
  double _bulbWarmth = 0.4;

  @override
  Widget build(BuildContext context) {
    final store = SpaceMockStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (_, _) {
        final args = parseSpaceDeviceControlArgs(
          ModalRoute.of(context)?.settings.arguments,
        );
        final target = _resolveTarget(store, args);
        final type = target?.device.controlType ?? args.type;
        final title = target?.device.name ?? args.deviceName ?? type.title;
        final powerStatus = _powerStatusLabel(target?.device);
        final brightness = _resolvedBrightness(type: type, target: target);

        return Scaffold(
          backgroundColor: SpaceColors.bgSurface,
          body: SafeArea(
            child: Column(
              children: [
                _TopBar(title: title),
                _DeviceTabRow(
                  active: type,
                  onTap: (nextType) =>
                      Navigator.of(context).pushReplacementNamed(
                        '/spaces/device-control',
                        arguments: nextType.routeValue,
                      ),
                ),
                if (target != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                    child: _PowerStateCard(
                      name: target.device.name,
                      isOn: target.device.isOn,
                      statusLabel: powerStatus,
                      enabled: target.device.online,
                      onChanged: (value) => store.toggleDevicePower(
                        roomId: target.room.id,
                        deviceId: target.device.id,
                        value: value,
                      ),
                    ),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    child: _buildBody(
                      type: type,
                      target: target,
                      store: store,
                      brightness: brightness,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  ({SpaceRoom room, SpaceDeviceState device})? _resolveTarget(
    SpaceMockStore store,
    SpaceDeviceControlArgs args,
  ) {
    if (args.roomId != null && args.deviceId != null) {
      final byIds = store.findDeviceByIds(
        roomId: args.roomId!,
        deviceId: args.deviceId!,
      );
      if (byIds != null) return byIds;
    }
    if (args.deviceName != null) {
      final byName = store.findFirstDeviceByName(args.deviceName!);
      if (byName != null) return byName;
    }
    return store.findFirstDeviceByType(args.type);
  }

  Widget _buildBody({
    required SpaceDeviceControlType type,
    required ({SpaceRoom room, SpaceDeviceState device})? target,
    required SpaceMockStore store,
    required double brightness,
  }) {
    switch (type) {
      case SpaceDeviceControlType.climate:
        return _ClimatePanel(
          temperature: _temperature,
          onInc: () =>
              setState(() => _temperature = (_temperature + 1).clamp(16, 30)),
          onDec: () =>
              setState(() => _temperature = (_temperature - 1).clamp(16, 30)),
        );
      case SpaceDeviceControlType.fan:
        return _FanPanel(
          speed: _fanSpeed,
          onSpeedChanged: (value) => setState(() => _fanSpeed = value),
        );
      case SpaceDeviceControlType.ac:
        return _AcPanel(
          temperature: _acTemperature,
          modeIndex: _acModeIndex,
          onInc: () => setState(
            () => _acTemperature = (_acTemperature + 1).clamp(16, 30),
          ),
          onDec: () => setState(
            () => _acTemperature = (_acTemperature - 1).clamp(16, 30),
          ),
          onModeChanged: (index) => setState(() => _acModeIndex = index),
        );
      case SpaceDeviceControlType.purifier:
        return _PurifierPanel(
          modeIndex: _purifierModeIndex,
          onModeChanged: (index) => setState(() => _purifierModeIndex = index),
        );
      case SpaceDeviceControlType.speaker:
        return _SpeakerPanel(
          manualMode: _manualMode,
          volume: _speakerVolume,
          eq: _eq,
          onManualChanged: (value) => setState(() => _manualMode = value),
          onVolumeChanged: (value) => setState(() => _speakerVolume = value),
          onEqChanged: (index, value) => setState(() => _eq[index] = value),
        );
      case SpaceDeviceControlType.ceilingLight:
        return _CeilingLightPanel(
          brightness: brightness,
          warmth: _lightWarmth,
          onBrightnessChanged: (value) =>
              _handleBrightnessChanged(target, store, value, isBulb: false),
          onWarmthChanged: (value) => setState(() => _lightWarmth = value),
        );
      case SpaceDeviceControlType.bulb:
        return _BulbPanel(
          brightness: brightness,
          warmth: _bulbWarmth,
          onBrightnessChanged: (value) =>
              _handleBrightnessChanged(target, store, value, isBulb: true),
          onWarmthChanged: (value) => setState(() => _bulbWarmth = value),
        );
    }
  }

  double _resolvedBrightness({
    required SpaceDeviceControlType type,
    required ({SpaceRoom room, SpaceDeviceState device})? target,
  }) {
    final shadowLevel = target?.device.levelFraction;
    if (shadowLevel != null) return shadowLevel;
    return type == SpaceDeviceControlType.bulb
        ? _bulbBrightness
        : _lightBrightness;
  }

  String? _powerStatusLabel(SpaceDeviceState? device) {
    if (device == null || !device.isShadowBacked) return null;
    if (!device.online) return 'Offline';
    return switch (device.syncStatus) {
      SpaceDeviceSyncStatus.pending => 'Syncing',
      SpaceDeviceSyncStatus.synced => 'Shadow synced',
      SpaceDeviceSyncStatus.localOnly => 'Local only',
    };
  }

  void _handleBrightnessChanged(
    ({SpaceRoom room, SpaceDeviceState device})? target,
    SpaceMockStore store,
    double value, {
    required bool isBulb,
  }) {
    if (target != null && target.device.supportsLevel) {
      store.setDeviceLevel(
        roomId: target.room.id,
        deviceId: target.device.id,
        value: value,
      );
      return;
    }

    setState(() {
      if (isBulb) {
        _bulbBrightness = value;
      } else {
        _lightBrightness = value;
      }
    });
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          _IconButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Center(child: Text(title, style: SpaceTextStyles.navTitle)),
          ),
          _IconButton(
            icon: Icons.close,
            onTap: () => Navigator.of(context).popUntil(
              (route) => route.settings.name == '/spaces' || route.isFirst,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(icon, color: SpaceColors.textPrimary, size: 20),
      ),
    );
  }
}

class _PowerStateCard extends StatelessWidget {
  const _PowerStateCard({
    required this.name,
    required this.isOn,
    required this.onChanged,
    this.statusLabel,
    this.enabled = true,
  });

  final String name;
  final bool isOn;
  final ValueChanged<bool> onChanged;
  final String? statusLabel;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: SpaceColors.bgBase,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SpaceColors.stroke),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$name Power',
                  style: SpaceTextStyles.pillTitle.copyWith(fontSize: 15),
                ),
                if (statusLabel != null)
                  Text(
                    statusLabel!,
                    style: SpaceTextStyles.pillMeta.copyWith(fontSize: 12),
                  ),
              ],
            ),
          ),
          Switch(
            value: isOn,
            onChanged: enabled ? onChanged : null,
            activeThumbColor: SpaceColors.accentStart,
            activeTrackColor: const Color(0x887773FA),
            inactiveThumbColor: SpaceColors.textPrimary,
            inactiveTrackColor: SpaceColors.bgElevated,
          ),
        ],
      ),
    );
  }
}

class _DeviceTabRow extends StatelessWidget {
  const _DeviceTabRow({required this.active, required this.onTap});

  final SpaceDeviceControlType active;
  final ValueChanged<SpaceDeviceControlType> onTap;

  @override
  Widget build(BuildContext context) {
    const tabs = [
      (SpaceDeviceControlType.climate, Icons.thermostat_outlined),
      (SpaceDeviceControlType.fan, Icons.mode_fan_off_outlined),
      (SpaceDeviceControlType.ac, Icons.ac_unit_outlined),
      (SpaceDeviceControlType.purifier, Icons.air_outlined),
      (SpaceDeviceControlType.speaker, Icons.speaker_outlined),
      (SpaceDeviceControlType.ceilingLight, Icons.lightbulb_outline),
      (SpaceDeviceControlType.bulb, Icons.tungsten_outlined),
    ];

    return SizedBox(
      height: 84,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          final type = tabs[index].$1;
          final icon = tabs[index].$2;
          final selected = type == active;
          return InkWell(
            onTap: () => onTap(type),
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? SpaceColors.textPrimary
                    : SpaceColors.bgElevated,
              ),
              child: Icon(
                icon,
                color: selected ? SpaceColors.bgBase : SpaceColors.textPrimary,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ClimatePanel extends StatelessWidget {
  const _ClimatePanel({
    required this.temperature,
    required this.onInc,
    required this.onDec,
  });

  final double temperature;
  final VoidCallback onInc;
  final VoidCallback onDec;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 295,
          height: 295,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: SpaceColors.bgElevated, width: 16),
          ),
          child: Center(
            child: Text(
              '${temperature.round()}',
              style: SpaceTextStyles.sectionTitle.copyWith(fontSize: 88),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RoundAction(icon: Icons.remove, onTap: onDec),
            const SizedBox(width: 16),
            _RoundAction(icon: Icons.add, onTap: onInc),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Adjust the control to find the best temperature for your need.',
          textAlign: TextAlign.center,
          style: SpaceTextStyles.sectionCount,
        ),
      ],
    );
  }
}

class _FanPanel extends StatelessWidget {
  const _FanPanel({required this.speed, required this.onSpeedChanged});

  final double speed;
  final ValueChanged<double> onSpeedChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        const Icon(
          Icons.mode_fan_off_outlined,
          size: 180,
          color: SpaceColors.textPrimary,
        ),
        const SizedBox(height: 14),
        Text(
          'Speed ${(speed * 100).round()}%',
          style: SpaceTextStyles.navTitle,
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: SpaceColors.textPrimary,
            inactiveTrackColor: SpaceColors.bgElevated,
            thumbColor: SpaceColors.accentStart,
          ),
          child: Slider(value: speed, onChanged: onSpeedChanged),
        ),
        const SizedBox(height: 8),
        const _SegmentButtons(labels: ['Slow', 'Moderate', 'Fast']),
      ],
    );
  }
}

class _AcPanel extends StatelessWidget {
  const _AcPanel({
    required this.temperature,
    required this.modeIndex,
    required this.onInc,
    required this.onDec,
    required this.onModeChanged,
  });

  final double temperature;
  final int modeIndex;
  final VoidCallback onInc;
  final VoidCallback onDec;
  final ValueChanged<int> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 327,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: SpaceColors.bgBase,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: SpaceColors.stroke),
          ),
          child: Column(
            children: [
              Text(
                '${temperature.round()}°C',
                style: SpaceTextStyles.sectionTitle,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RoundAction(icon: Icons.remove, onTap: onDec),
                  const SizedBox(width: 16),
                  _RoundAction(icon: Icons.add, onTap: onInc),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _SegmentButtons(
          labels: const ['Cool', 'Auto', 'Heat'],
          selectedIndex: modeIndex,
          onChanged: onModeChanged,
        ),
      ],
    );
  }
}

class _PurifierPanel extends StatelessWidget {
  const _PurifierPanel({required this.modeIndex, required this.onModeChanged});

  final int modeIndex;
  final ValueChanged<int> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 295,
          height: 295,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: SpaceColors.bgElevated, width: 16),
          ),
          child: Center(
            child: Text(
              '24',
              style: SpaceTextStyles.sectionTitle.copyWith(fontSize: 88),
            ),
          ),
        ),
        const SizedBox(height: 18),
        _SegmentButtons(
          labels: const ['Moderate', 'Comfort', 'Density'],
          selectedIndex: modeIndex,
          onChanged: onModeChanged,
        ),
      ],
    );
  }
}

class _SpeakerPanel extends StatelessWidget {
  const _SpeakerPanel({
    required this.manualMode,
    required this.volume,
    required this.eq,
    required this.onManualChanged,
    required this.onVolumeChanged,
    required this.onEqChanged,
  });

  final bool manualMode;
  final double volume;
  final List<double> eq;
  final ValueChanged<bool> onManualChanged;
  final ValueChanged<double> onVolumeChanged;
  final void Function(int index, double value) onEqChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 327,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SpaceColors.bgBase,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SpaceColors.stroke),
          ),
          child: Row(
            children: [
              Text(
                'Manual',
                style: SpaceTextStyles.pillTitle.copyWith(fontSize: 16),
              ),
              const Spacer(),
              Switch(
                value: manualMode,
                onChanged: onManualChanged,
                activeThumbColor: SpaceColors.accentStart,
                activeTrackColor: const Color(0x887773FA),
                inactiveThumbColor: SpaceColors.textPrimary,
                inactiveTrackColor: SpaceColors.bgElevated,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 327,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SpaceColors.bgBase,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SpaceColors.stroke),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'Volume',
                    style: SpaceTextStyles.pillTitle.copyWith(fontSize: 16),
                  ),
                  const Spacer(),
                  Text(
                    '${(volume * 100).round()}%',
                    style: SpaceTextStyles.pillMeta.copyWith(fontSize: 14),
                  ),
                ],
              ),
              Slider(
                value: volume,
                onChanged: onVolumeChanged,
                activeColor: SpaceColors.textPrimary,
                inactiveColor: SpaceColors.bgElevated,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: 327,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          decoration: BoxDecoration(
            color: SpaceColors.bgBase,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SpaceColors.stroke),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(eq.length, (index) {
              return Expanded(
                child: Column(
                  children: [
                    RotatedBox(
                      quarterTurns: 3,
                      child: Slider(
                        value: eq[index],
                        onChanged: (value) => onEqChanged(index, value),
                        activeColor: SpaceColors.accentStart,
                        inactiveColor: SpaceColors.bgElevated,
                      ),
                    ),
                    Text('${index + 1}', style: SpaceTextStyles.pillMeta),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _CeilingLightPanel extends StatelessWidget {
  const _CeilingLightPanel({
    required this.brightness,
    required this.warmth,
    required this.onBrightnessChanged,
    required this.onWarmthChanged,
  });

  final double brightness;
  final double warmth;
  final ValueChanged<double> onBrightnessChanged;
  final ValueChanged<double> onWarmthChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 295,
          height: 295,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [
                Color(0xFFFF454B),
                Color(0xFFFF8A5D),
                Color(0xFFFAD000),
                Color(0xFF24B898),
                Color(0xFF0047FE),
                Color(0xFF9E50DC),
                Color(0xFFFF454B),
              ],
            ),
          ),
          child: Center(
            child: Container(
              width: 134,
              height: 134,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFF9E2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        _SliderCard(
          label: 'Brightness',
          value: brightness,
          onChanged: onBrightnessChanged,
        ),
        const SizedBox(height: 12),
        _SliderCard(label: 'Warmth', value: warmth, onChanged: onWarmthChanged),
      ],
    );
  }
}

class _BulbPanel extends StatelessWidget {
  const _BulbPanel({
    required this.brightness,
    required this.warmth,
    required this.onBrightnessChanged,
    required this.onWarmthChanged,
  });

  final double brightness;
  final double warmth;
  final ValueChanged<double> onBrightnessChanged;
  final ValueChanged<double> onWarmthChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 247,
          height: 75,
          decoration: BoxDecoration(
            color: SpaceColors.bgBase,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: SpaceColors.stroke),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: SpaceColors.bgElevated,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Text(
                  '${(brightness * 100).round()}%',
                  textAlign: TextAlign.center,
                  style: SpaceTextStyles.pillTitle.copyWith(fontSize: 20),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SliderCard(
          label: 'Brightness',
          value: brightness,
          onChanged: onBrightnessChanged,
        ),
        const SizedBox(height: 12),
        _SliderCard(label: 'Warmth', value: warmth, onChanged: onWarmthChanged),
      ],
    );
  }
}

class _SliderCard extends StatelessWidget {
  const _SliderCard({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 327,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      decoration: BoxDecoration(
        color: SpaceColors.bgBase,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SpaceColors.stroke),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                label,
                style: SpaceTextStyles.pillTitle.copyWith(fontSize: 16),
              ),
              const Spacer(),
              Text(
                '${(value * 100).round()}%',
                style: SpaceTextStyles.pillMeta.copyWith(fontSize: 14),
              ),
            ],
          ),
          Slider(
            value: value,
            onChanged: onChanged,
            activeColor: SpaceColors.textPrimary,
            inactiveColor: SpaceColors.bgElevated,
          ),
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: SpaceColors.bgElevated,
          border: Border.all(color: SpaceColors.stroke),
        ),
        child: Icon(icon, color: SpaceColors.textPrimary),
      ),
    );
  }
}

class _SegmentButtons extends StatelessWidget {
  const _SegmentButtons({
    required this.labels,
    this.selectedIndex = 0,
    this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(labels.length, (index) {
        final active = selectedIndex == index;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == labels.length - 1 ? 0 : 10,
            ),
            child: InkWell(
              onTap: onChanged == null ? null : () => onChanged!(index),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: active ? SpaceColors.textPrimary : SpaceColors.bgBase,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SpaceColors.stroke),
                ),
                child: Center(
                  child: Text(
                    labels[index],
                    style: SpaceTextStyles.pillTitle.copyWith(
                      fontSize: 16,
                      color: active
                          ? SpaceColors.bgBase
                          : SpaceColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
