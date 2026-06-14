import 'package:flutter/material.dart';

import '../services/device_api_models.dart';
import '../theme/assistant_tokens.dart';
import 'assistant_card_kit.dart';

/// Entrance siren control card, mirroring
/// design/fibo_claude_agent.pen › "48. Entrance Siren".
class AssistantSirenCard extends StatefulWidget {
  const AssistantSirenCard({
    super.key,
    required this.device,
    required this.onControl,
  });

  final AgentDevice device;
  final void Function(String action, Map<String, dynamic>? params) onControl;

  @override
  State<AssistantSirenCard> createState() => _AssistantSirenCardState();
}

class _AssistantSirenCardState extends State<AssistantSirenCard> {
  late bool _sounding;
  String _volume = 'Med';
  int _melody = 3;
  String _duration = '30s';

  static const _volumes = ['Low', 'Med', 'High'];
  static const _durations = ['30s', '60s', '5 min'];

  @override
  void initState() {
    super.initState();
    final s = widget.device.state;
    _sounding = s['alarm'] == true ||
        s['active'] == true ||
        s['state'] == 'on' ||
        s['power'] == 'on';
    final v = s['volume'];
    if (v is String && _volumes.contains(_cap(v))) _volume = _cap(v);
    final m = s['melody'];
    if (m is num) _melody = m.round().clamp(1, 9);
  }

  String _cap(String v) =>
      v.isEmpty ? v : '${v[0].toUpperCase()}${v.substring(1).toLowerCase()}';

  void _toggleSound() {
    setState(() => _sounding = !_sounding);
    widget.onControl(_sounding ? 'trigger' : 'silence', {
      'volume': _volume.toLowerCase(),
      'melody': _melody,
    });
  }

  @override
  Widget build(BuildContext context) {
    final circleBg = _sounding ? const Color(0xFF3D2630) : kCardChipBg;
    final circleFg = _sounding ? const Color(0xFFF87171) : AgentColors.inkMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AgentCard(
          child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(shape: BoxShape.circle, color: circleBg),
                child: Icon(Icons.campaign_outlined, size: 40, color: circleFg),
              ),
              const SizedBox(height: 10),
              Text(_sounding ? 'Sounding' : 'Silent',
                  style: CardText.value.copyWith(fontSize: 22)),
              const SizedBox(height: 4),
              Text(_sounding ? 'Alarm active' : 'Armed · ready',
                  style: CardText.muted.copyWith(
                      fontSize: 13, fontWeight: FontWeight.w400)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _toggleSound,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _sounding ? AgentColors.surfaceElevated : kCardAccent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_sounding ? Icons.volume_off : Icons.volume_up,
                          size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        _sounding ? 'Silence' : 'Sound Siren',
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.gpp_maybe_outlined,
                      size: 13, color: Color(0xFFFFD17A)),
                  const SizedBox(width: 6),
                  Text('Requires confirmation',
                      style: CardText.hint.copyWith(color: const Color(0xFFFFD17A))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AgentCard(
          padding: 14,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Settings',
                  style: CardText.muted.copyWith(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _settingRow(
                'Volume',
                _ChipGroup(
                  options: _volumes,
                  selected: _volume,
                  onSelect: (v) {
                    setState(() => _volume = v);
                    widget.onControl('set_volume', {'value': v.toLowerCase()});
                  },
                ),
              ),
              const SizedBox(height: 12),
              _settingRow(
                'Melody',
                _Stepper(
                  label: 'Melody $_melody',
                  onMinus: () => _stepMelody(-1),
                  onPlus: () => _stepMelody(1),
                ),
              ),
              const SizedBox(height: 12),
              _settingRow(
                'Duration',
                _ChipGroup(
                  options: _durations,
                  selected: _duration,
                  onSelect: (v) {
                    setState(() => _duration = v);
                    widget.onControl('set_duration', {'value': v});
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF3D3416),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.bedtime_outlined,
                  size: 16, color: Color(0xFFFFD17A)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Quiet hours 23:00–07:00 — siren can’t sound',
                  style: CardText.hint.copyWith(color: const Color(0xFFFFD17A)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _stepMelody(int delta) {
    setState(() => _melody = (_melody + delta).clamp(1, 9));
    widget.onControl('set_melody', {'value': _melody});
  }

  Widget _settingRow(String label, Widget control) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AgentColors.inkMuted,
            ),
          ),
        ),
        control,
      ],
    );
  }
}

class _ChipGroup extends StatelessWidget {
  const _ChipGroup({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final o in options) ...[
          if (o != options.first) const SizedBox(width: 6),
          GestureDetector(
            onTap: () => onSelect(o),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: o == selected ? kCardAccent : kCardChipBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                o,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: o == selected ? Colors.white : AgentColors.inkMuted,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _round(Icons.chevron_left, onMinus),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AgentColors.ink,
          ),
        ),
        const SizedBox(width: 10),
        _round(Icons.chevron_right, onPlus),
      ],
    );
  }

  Widget _round(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: kCardChipBg),
        child: Icon(icon, size: 16, color: AgentColors.ink),
      ),
    );
  }
}
