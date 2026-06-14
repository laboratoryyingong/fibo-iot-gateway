import 'package:flutter/material.dart';

import '../services/device_api_models.dart';
import '../theme/assistant_tokens.dart';
import 'assistant_card_kit.dart';

/// Presence radar card, mirroring
/// design/fibo_claude_agent.pen › "49. Presence Radar". Live presence is
/// display-only; the advanced tuning sliders push best-effort config.
class AssistantPresenceCard extends StatefulWidget {
  const AssistantPresenceCard({
    super.key,
    required this.device,
    required this.onControl,
  });

  final AgentDevice device;
  final void Function(String action, Map<String, dynamic>? params) onControl;

  @override
  State<AssistantPresenceCard> createState() => _AssistantPresenceCardState();
}

class _AssistantPresenceCardState extends State<AssistantPresenceCard> {
  late final bool _present;
  late final num? _distance;

  late double _sensitivity; // 0..10
  late double _minRange; // cm, 0..200
  late double _maxRange; // cm, 0..800
  late double _fade; // s, 0..60

  @override
  void initState() {
    super.initState();
    final s = widget.device.state;
    _present = s['presence'] == true ||
        s['occupancy'] == true ||
        s['motion'] == true ||
        s['present'] == true;
    final d = s['distance'] ?? s['target_distance'];
    _distance = d is num ? d : null;
    _sensitivity = _num(s['sensitivity'], 6).clamp(0, 10);
    _minRange = _num(s['min_range'], 30).clamp(0, 200);
    _maxRange = _num(s['max_range'], 600).clamp(0, 800);
    _fade = _num(s['fade_time'] ?? s['fading_time'], 15).clamp(0, 60);
  }

  double _num(Object? v, double fallback) =>
      v is num ? v.toDouble() : fallback;

  void _push(String key, num value) =>
      widget.onControl('set_config', {key: value});

  @override
  Widget build(BuildContext context) {
    const accentGreen = Color(0xFF34D399);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AgentCard(
          padding: 20,
          child: Column(
            children: [
              Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _present ? const Color(0xFF173329) : kCardChipBg,
                ),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _present
                        ? const Color(0xFF1E3A2C)
                        : AgentColors.surface,
                  ),
                  child: Icon(Icons.radar,
                      size: 30,
                      color: _present ? accentGreen : AgentColors.inkMuted),
                ),
              ),
              const SizedBox(height: 14),
              Text(_present ? 'Present' : 'Absent',
                  style: CardText.value.copyWith(fontSize: 20)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _present ? const Color(0xFF1E3A2C) : kCardChipBg,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  _present
                      ? (_distance != null
                          ? 'Target at ${_distance.round()} cm'
                          : 'Target detected')
                      : 'No target',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 13,
                    color: _present ? const Color(0xFF6EE7A8) : AgentColors.inkMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AgentCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Advanced', style: CardText.title),
                  Text('Tuning', style: CardText.muted.copyWith(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 18),
              _tune('Sensitivity', _sensitivity.round().toString(),
                  _sensitivity / 10, (t) => setState(() => _sensitivity = t * 10),
                  () => _push('sensitivity', _sensitivity.round())),
              const SizedBox(height: 18),
              _tune('Min range', '${_minRange.round()} cm', _minRange / 200,
                  (t) => setState(() => _minRange = t * 200),
                  () => _push('min_range', _minRange.round())),
              const SizedBox(height: 18),
              _tune('Max range', '${_maxRange.round()} cm', _maxRange / 800,
                  (t) => setState(() => _maxRange = t * 800),
                  () => _push('max_range', _maxRange.round())),
              const SizedBox(height: 18),
              _tune('Fading time', '${_fade.round()} s', _fade / 60,
                  (t) => setState(() => _fade = t * 60),
                  () => _push('fade_time', _fade.round())),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tune(String label, String value, double t,
      ValueChanged<double> onChanged, VoidCallback onCommit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 13,
                    color: AgentColors.inkMuted)),
            Text(value,
                style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AgentColors.ink)),
          ],
        ),
        const SizedBox(height: 8),
        AgentFillSlider(
          value: t.clamp(0.0, 1.0),
          onChanged: onChanged,
          onChangeEnd: (_) => onCommit(),
        ),
      ],
    );
  }
}
