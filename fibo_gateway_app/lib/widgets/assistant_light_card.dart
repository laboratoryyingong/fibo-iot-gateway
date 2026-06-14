import 'package:flutter/material.dart';

import '../services/device_api_models.dart';
import '../theme/assistant_tokens.dart';
import 'assistant_card_kit.dart';

/// Interactive light control card rendered after a light `control_device`
/// turn, mirroring design/fibo_claude_agent.pen › "45. Color Light".
///
/// Holds optimistic local state seeded from [device]; user gestures update the
/// UI immediately and call [onControl] to drive the real device.
class AssistantLightCard extends StatefulWidget {
  const AssistantLightCard({
    super.key,
    required this.device,
    required this.onControl,
  });

  final AgentDevice device;

  /// Sends a control to the device, e.g. `('set_brightness', {'value': 60})`.
  final void Function(String action, Map<String, dynamic>? params) onControl;

  @override
  State<AssistantLightCard> createState() => _AssistantLightCardState();

  static const _minKelvin = 2700;
  static const _maxKelvin = 6500;
}

class _AssistantLightCardState extends State<AssistantLightCard> {
  late bool _on;
  late double _brightness; // 0..100
  late double _kelvin; // 2700..6500

  static const _presets = <String, int>{
    'Relax': 2700,
    'Reading': 4000,
    'Bright': 6500,
  };

  @override
  void initState() {
    super.initState();
    final state = widget.device.state;
    _on = widget.device.isOn ?? true;
    _brightness = (widget.device.brightness ?? 100).toDouble().clamp(0.0, 100.0);
    final k = state['color_temp'];
    _kelvin = (k is num ? k.toDouble() : 4000.0).clamp(
        AssistantLightCard._minKelvin.toDouble(),
        AssistantLightCard._maxKelvin.toDouble());
  }

  void _togglePower() {
    setState(() => _on = !_on);
    widget.onControl(_on ? 'turn_on' : 'turn_off', null);
  }

  void _setBrightness(double value, {bool commit = false}) {
    setState(() {
      _brightness = value.clamp(0.0, 100.0);
      if (!_on && _brightness > 0) _on = true;
    });
    if (commit) widget.onControl('set_brightness', {'value': _brightness.round()});
  }

  void _setKelvin(double value, {bool commit = false}) {
    setState(() => _kelvin = value.clamp(
          AssistantLightCard._minKelvin.toDouble(),
          AssistantLightCard._maxKelvin.toDouble(),
        ));
    if (commit) widget.onControl('set_color_temp', {'value': _kelvin.round()});
  }

  double get _tempT =>
      (_kelvin - AssistantLightCard._minKelvin) /
      (AssistantLightCard._maxKelvin - AssistantLightCard._minKelvin);

  double _kelvinFromT(double t) =>
      AssistantLightCard._minKelvin +
      t * (AssistantLightCard._maxKelvin - AssistantLightCard._minKelvin);

  String get _warmthLabel {
    if (_kelvin < 3500) return 'Warm white';
    if (_kelvin < 5000) return 'Neutral white';
    return 'Cool white';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AgentCard(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_on ? 'On' : 'Off', style: CardText.title),
                  DeviceToggle(value: _on, onTap: _togglePower),
                ],
              ),
              const SizedBox(height: 12),
              _bulb(),
              const SizedBox(height: 12),
              Text(
                _on ? '$_warmthLabel · ${_brightness.round()}%' : 'Off',
                style: CardText.muted,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AgentCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AgentCardHeader(
                icon: Icons.wb_sunny_outlined,
                label: 'Brightness',
                value: '${_brightness.round()}%',
                valueColor: kCardAccent,
              ),
              const SizedBox(height: 14),
              AgentFillSlider(
                value: _brightness / 100,
                onChanged: (t) => _setBrightness(t * 100),
                onChangeEnd: (t) => _setBrightness(t * 100, commit: true),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AgentCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AgentCardHeader(
                icon: Icons.thermostat_outlined,
                label: 'Color temperature',
                value: '${_kelvin.round()} K',
              ),
              const SizedBox(height: 14),
              AgentGradientSlider(
                value: _tempT,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFB46B), Color(0xFFFFF7E6), Color(0xFFBCD7FF)],
                ),
                onChanged: (t) => _setKelvin(_kelvinFromT(t)),
                onChangeEnd: (t) => _setKelvin(_kelvinFromT(t), commit: true),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (final entry in _presets.entries) ...[
                    if (entry.key != _presets.keys.first)
                      const SizedBox(width: 8),
                    Expanded(child: _preset(entry.key, entry.value)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bulb() {
    const warm = Color(0xFFFB923C);
    const cool = Color(0xFF93C5FD);
    final glow = Color.lerp(warm, cool, _tempT)!;
    final inner =
        Color.lerp(const Color(0xFFFEF9C3), const Color(0xFFF0F9FF), _tempT)!;
    final intensity = _on ? (0.45 + 0.55 * (_brightness / 100)) : 0.0;

    return Container(
      width: 116,
      height: 116,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: _on
              ? [inner, glow]
              : [AgentColors.surfaceElevated, AgentColors.surface],
        ),
        boxShadow: _on
            ? [BoxShadow(color: glow.withValues(alpha: 0.4 * intensity), blurRadius: 34)]
            : null,
      ),
      child: Icon(
        Icons.lightbulb,
        size: 48,
        color: _on ? Colors.white : const Color(0xFFCBD5E1),
      ),
    );
  }

  Widget _preset(String label, int kelvin) {
    final selected = (_kelvin - kelvin).abs() <= 200;
    return GestureDetector(
      onTap: () => _setKelvin(kelvin.toDouble(), commit: true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? kCardAccent : kCardChipBg,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AgentColors.inkMuted,
          ),
        ),
      ),
    );
  }
}

/// Pill toggle shared by the light and siren cards.
class DeviceToggle extends StatelessWidget {
  const DeviceToggle({super.key, required this.value, required this.onTap});

  final bool value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 48,
        height: 28,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: value ? kCardAccent : kCardTrackGrey,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Align(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Color(0x330F172A), blurRadius: 2, offset: Offset(0, 1)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
