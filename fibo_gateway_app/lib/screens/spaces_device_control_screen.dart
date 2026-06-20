import 'package:flutter/material.dart';

import 'package:fibo_core/theme/space_tokens.dart';
import 'space_device_types.dart';
import 'space_models.dart';

/// Largest a circular dial can be without overflowing the 24px-padded body —
/// keeps the big control dials from clipping on narrow phones while staying at
/// the design size on regular/large screens.
double _dialDim(BuildContext context, [double max = 295]) {
  final available = MediaQuery.sizeOf(context).width - 48;
  return available < max ? available : max;
}

class SpacesDeviceControlScreen extends StatefulWidget {
  const SpacesDeviceControlScreen({super.key});

  @override
  State<SpacesDeviceControlScreen> createState() =>
      _SpacesDeviceControlScreenState();
}

class _SpacesDeviceControlScreenState extends State<SpacesDeviceControlScreen> {
  final SpaceMockStore _store = SpaceMockStore.instance;
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
  void initState() {
    super.initState();
    _store.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  /// Surfaces live-control feedback (conflict / confirmation / offline / not
  /// supported) from the store as a SnackBar, then clears it so it shows once.
  void _onStoreChanged() {
    final message = _store.controlMessage;
    if (message == null || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _store.controlMessage == null) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(message),
          backgroundColor: SpaceColors.bgElevated,
          behavior: SnackBarBehavior.floating,
        ));
      _store.clearControlMessage();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = _store;
    return AnimatedBuilder(
      animation: store,
      builder: (_, _) {
        final args = parseSpaceDeviceControlArgs(
          ModalRoute.of(context)?.settings.arguments,
        );
        final target = _resolveTarget(store, args);
        final isLive = target?.device.isLiveShadow ?? false;
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
                // Mock-device tab row + generic power card only apply to the
                // template devices. Live shadow devices render a control UI
                // matched to their real profile (and own their own controls).
                if (!isLive)
                  _DeviceTabRow(
                    active: type,
                    onTap: (nextType) =>
                        Navigator.of(context).pushReplacementNamed(
                          '/spaces/device-control',
                          arguments: nextType.routeValue,
                        ),
                  ),
                if (!isLive && target != null)
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
                    child: isLive
                        ? _LiveDeviceBody(target: target!, store: store)
                        : _buildBody(
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

/// Renders the control UI that matches a live shadow device's real profile.
/// Each branch owns the controls that actually apply to that device type, so
/// curtains get a position control, locks get lock/unlock, sensors are
/// read-only, etc. — no more one-size-fits-all climate panel.
class _LiveDeviceBody extends StatelessWidget {
  const _LiveDeviceBody({required this.target, required this.store});

  final ({SpaceRoom room, SpaceDeviceState device}) target;
  final SpaceMockStore store;

  @override
  Widget build(BuildContext context) {
    switch (target.device.iotProfile) {
      case 'color_light':
      case 'dimmable_light':
        return _LiveLightPanel(target: target, store: store);
      case 'onoff_actuator':
        return _LiveSwitchPanel(
          target: target,
          store: store,
          onIcon: Icons.power_settings_new,
        );
      case 'siren_actuator':
        return _LiveSwitchPanel(
          target: target,
          store: store,
          onIcon: Icons.notifications_active,
        );
      case 'curtain':
        return _LiveCurtainPanel(target: target, store: store);
      case 'door_lock':
        return _LiveLockPanel(target: target, store: store);
      default:
        return _LiveSensorPanel(device: target.device);
    }
  }
}

/// Power switch row used by the live light/switch panels.
class _LivePowerRow extends StatelessWidget {
  const _LivePowerRow({required this.target, required this.store});

  final ({SpaceRoom room, SpaceDeviceState device}) target;
  final SpaceMockStore store;

  @override
  Widget build(BuildContext context) {
    final device = target.device;
    return _PowerStateCard(
      name: device.name,
      isOn: device.isOn,
      statusLabel: device.online ? null : 'Offline',
      enabled: device.online,
      onChanged: (value) => store.toggleDevicePower(
        roomId: target.room.id,
        deviceId: device.id,
        value: value,
      ),
    );
  }
}

class _LiveHeroIcon extends StatelessWidget {
  const _LiveHeroIcon({required this.icon, required this.active, this.label});

  final IconData icon;
  final bool active;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: SpaceColors.bgBase,
            border: Border.all(
              color: active ? SpaceColors.accentStart : SpaceColors.stroke,
              width: active ? 4 : 2,
            ),
          ),
          child: Icon(
            icon,
            size: 96,
            color: active ? SpaceColors.accentStart : SpaceColors.textPrimary,
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 16),
          Text(label!, style: SpaceTextStyles.navTitle),
        ],
      ],
    );
  }
}

class _LiveLightPanel extends StatelessWidget {
  const _LiveLightPanel({required this.target, required this.store});

  final ({SpaceRoom room, SpaceDeviceState device}) target;
  final SpaceMockStore store;

  @override
  Widget build(BuildContext context) {
    final device = target.device;
    final brightness = device.labelPercentFraction ?? (device.isOn ? 1.0 : 0.0);
    return Column(
      children: [
        _LiveHeroIcon(
          icon: device.isOn ? Icons.lightbulb : Icons.lightbulb_outline,
          active: device.isOn,
          label: device.isOn ? '${(brightness * 100).round()}%' : 'Off',
        ),
        const SizedBox(height: 20),
        _LivePowerRow(target: target, store: store),
        const SizedBox(height: 12),
        _SliderCard(
          label: 'Brightness',
          value: brightness,
          onChanged: device.online
              ? (value) => store.setDeviceLevel(
                  roomId: target.room.id,
                  deviceId: device.id,
                  value: value,
                )
              : (_) {},
        ),
      ],
    );
  }
}

class _LiveSwitchPanel extends StatelessWidget {
  const _LiveSwitchPanel({
    required this.target,
    required this.store,
    required this.onIcon,
  });

  final ({SpaceRoom room, SpaceDeviceState device}) target;
  final SpaceMockStore store;
  final IconData onIcon;

  @override
  Widget build(BuildContext context) {
    final device = target.device;
    return Column(
      children: [
        _LiveHeroIcon(
          icon: onIcon,
          active: device.isOn,
          label: device.valueLabel ?? (device.isOn ? 'On' : 'Off'),
        ),
        const SizedBox(height: 20),
        _LivePowerRow(target: target, store: store),
      ],
    );
  }
}

class _LiveCurtainPanel extends StatelessWidget {
  const _LiveCurtainPanel({required this.target, required this.store});

  final ({SpaceRoom room, SpaceDeviceState device}) target;
  final SpaceMockStore store;

  @override
  Widget build(BuildContext context) {
    final device = target.device;
    final fraction =
        device.labelPercentFraction ?? (device.isOn ? 1.0 : 0.0);
    final percent = (fraction * 100).round();
    void move(int p) => store.setCurtainPosition(
      roomId: target.room.id,
      deviceId: device.id,
      percent: p,
    );
    return Column(
      children: [
        _LiveHeroIcon(
          icon: percent > 0 ? Icons.blinds_outlined : Icons.blinds_closed,
          active: percent > 0,
          label: '$percent% open',
        ),
        const SizedBox(height: 20),
        if (!device.online)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('Offline', style: SpaceTextStyles.pillMeta),
          ),
        Row(
          children: [
            Expanded(
              child: _WideButton(
                label: 'Close',
                icon: Icons.keyboard_arrow_down,
                onTap: device.online ? () => move(0) : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _WideButton(
                label: 'Open',
                icon: Icons.keyboard_arrow_up,
                onTap: device.online ? () => move(100) : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SliderCard(
          label: 'Position',
          value: fraction,
          onChanged: device.online ? (v) => move((v * 100).round()) : (_) {},
        ),
      ],
    );
  }
}

class _LiveLockPanel extends StatelessWidget {
  const _LiveLockPanel({required this.target, required this.store});

  final ({SpaceRoom room, SpaceDeviceState device}) target;
  final SpaceMockStore store;

  @override
  Widget build(BuildContext context) {
    final device = target.device;
    final locked = device.valueLabel == 'Locked';
    return Column(
      children: [
        _LiveHeroIcon(
          icon: locked ? Icons.lock : Icons.lock_open,
          active: locked,
          label: locked ? 'Locked' : 'Unlocked',
        ),
        const SizedBox(height: 24),
        if (!device.online)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('Offline', style: SpaceTextStyles.pillMeta),
          ),
        _WideButton(
          label: locked ? 'Unlock' : 'Lock',
          icon: locked ? Icons.lock_open : Icons.lock,
          filled: true,
          onTap: device.online
              ? () => store.setLock(
                  roomId: target.room.id,
                  deviceId: device.id,
                  locked: !locked,
                )
              : null,
        ),
      ],
    );
  }
}

class _LiveSensorPanel extends StatelessWidget {
  const _LiveSensorPanel({required this.device});

  final SpaceDeviceState device;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LiveHeroIcon(
          icon: device.icon,
          active: device.isOn,
          label: device.valueLabel ?? '—',
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SpaceColors.bgBase,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SpaceColors.stroke),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SensorRow(
                label: 'Status',
                value: device.valueLabel ?? 'No reading',
              ),
              const SizedBox(height: 10),
              _SensorRow(
                label: 'Connection',
                value: device.online ? 'Online' : 'Offline',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'This is a read-only sensor.',
          textAlign: TextAlign.center,
          style: SpaceTextStyles.pillMeta,
        ),
      ],
    );
  }
}

class _SensorRow extends StatelessWidget {
  const _SensorRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: SpaceTextStyles.pillMeta.copyWith(fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: SpaceTextStyles.pillTitle.copyWith(fontSize: 15),
        ),
      ],
    );
  }
}

class _WideButton extends StatelessWidget {
  const _WideButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final fg = filled ? SpaceColors.bgBase : SpaceColors.textPrimary;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: filled ? SpaceColors.accentStart : SpaceColors.bgBase,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: filled ? SpaceColors.accentStart : SpaceColors.stroke,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: SpaceTextStyles.pillTitle.copyWith(
                  fontSize: 16,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    final dim = _dialDim(context);
    return Column(
      children: [
        Container(
          width: dim,
          height: dim,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: SpaceColors.bgElevated, width: 16),
          ),
          child: Center(
            child: Text(
              '${temperature.round()}',
              style: SpaceTextStyles.sectionTitle.copyWith(
                fontSize: 88 * dim / 295,
              ),
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
          width: double.infinity,
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
    final dim = _dialDim(context);
    return Column(
      children: [
        Container(
          width: dim,
          height: dim,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: SpaceColors.bgElevated, width: 16),
          ),
          child: Center(
            child: Text(
              '24',
              style: SpaceTextStyles.sectionTitle.copyWith(
                fontSize: 88 * dim / 295,
              ),
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
          width: double.infinity,
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
          width: double.infinity,
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
          width: double.infinity,
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
    final dim = _dialDim(context);
    return Column(
      children: [
        Container(
          width: dim,
          height: dim,
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
              width: 134 * dim / 295,
              height: 134 * dim / 295,
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
      width: double.infinity,
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
