import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fibo_core/services/home_graph.dart';
import 'package:fibo_core/theme/space_tokens.dart';

import '../state/home_controller.dart';

/// Ambient "glance" page shown before Home: a large live clock, date, an
/// at-a-glance temperature + device summary, connection state, a mic shortcut
/// into the assistant, and one-tap scene tiles.
class StandbyScreen extends StatefulWidget {
  const StandbyScreen({
    super.key,
    required this.controller,
    required this.onAssistant,
    this.onNext,
  });

  final HomeController controller;
  final VoidCallback onAssistant;

  /// Advances to the Home page (wired by the shell); also drives the swipe hint.
  final VoidCallback? onNext;

  @override
  State<StandbyScreen> createState() => _StandbyScreenState();
}

class _StandbyScreenState extends State<StandbyScreen>
    with SingleTickerProviderStateMixin {
  late DateTime _now = DateTime.now();
  Timer? _timer;
  late final AnimationController _nudge = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) setState(() => _now = DateTime.now());
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _nudge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: SpaceColors.bgBase,
      child: SafeArea(
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            return Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 22, 28, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _topRow(),
                      const SizedBox(height: 28),
                      _clock(),
                      const Spacer(),
                      _sceneTiles(),
                    ],
                  ),
                ),
                Positioned(
                  right: 6,
                  top: 0,
                  bottom: 0,
                  child: Center(child: _swipeHint()),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _topRow() {
    final temp = _glanceTemperature();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.thermostat_rounded,
                      color: SpaceColors.textPrimary, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    temp ?? '—',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: SpaceColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _formatDate(_now),
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: SpaceColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        Icon(
          widget.controller.shadowsConnected
              ? Icons.wifi_rounded
              : Icons.wifi_off_rounded,
          color: SpaceColors.textMuted,
          size: 24,
        ),
        const SizedBox(width: 18),
        InkWell(
          onTap: widget.onAssistant,
          customBorder: const CircleBorder(),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.mic_none_rounded,
                color: SpaceColors.textPrimary, size: 24),
          ),
        ),
      ],
    );
  }

  /// A gently nudging "swipe to Home" chevron on the right edge; also tappable.
  Widget _swipeHint() {
    return InkWell(
      onTap: widget.onNext,
      borderRadius: BorderRadius.circular(40),
      child: AnimatedBuilder(
        animation: _nudge,
        builder: (context, child) => Transform.translate(
          offset: Offset(_nudge.value * 6, 0),
          child: child,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chevron_right_rounded,
                color: SpaceColors.textMuted, size: 40),
            Text(
              'Home',
              style: SpaceTextStyles.pillMeta.copyWith(letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _clock() {
    final t = _formatTime(_now);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          t.$1,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 116,
            fontWeight: FontWeight.w700,
            color: SpaceColors.textPrimary,
            height: 1.0,
          ),
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Text(
            t.$2,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: SpaceColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 20),
        Padding(
          padding: const EdgeInsets.only(bottom: 22),
          child: Text(
            _deviceSummary(),
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 15,
              color: SpaceColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sceneTiles() {
    final scenes = widget.controller.scenes.take(4).toList();
    if (scenes.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        for (final s in scenes) ...[
          Expanded(child: _SceneTile(scene: s, onTap: () => _runScene(s))),
          const SizedBox(width: 14),
        ],
        // Balance the row when there are fewer than 4 scenes.
        for (var i = scenes.length; i < 2; i++) ...[
          const Expanded(child: SizedBox()),
          const SizedBox(width: 14),
        ],
      ],
    );
  }

  Future<void> _runScene(HomeScene scene) async {
    try {
      await widget.controller.runScene(scene.sceneId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: SpaceColors.bgElevated,
            content: Text('${scene.name} started',
                style: const TextStyle(
                    fontFamily: 'Manrope', color: Colors.white)),
          ),
        );
      }
    } catch (_) {/* surfaced elsewhere */}
  }

  // --- Glance data ---------------------------------------------------------

  String? _glanceTemperature() {
    final g = widget.controller.graph;
    if (g == null) return null;
    for (final d in g.devices) {
      if (d.profile == 'multi_sensor') {
        final label = widget.controller.viewFor(d).valueLabel;
        if (label != null && label.contains('°')) return label;
      }
    }
    return null;
  }

  String _deviceSummary() {
    final rooms = widget.controller.rooms;
    var total = 0;
    var on = 0;
    for (final r in rooms) {
      for (final d in r.devices) {
        total++;
        final v = widget.controller.viewFor(d);
        if (v.isOn && v.kind != DeviceKind.sensor) on++;
      }
    }
    if (total == 0) return '';
    return '$total devices · $on on';
  }

  // --- Formatting ----------------------------------------------------------

  (String, String) _formatTime(DateTime t) {
    final ampm = t.hour >= 12 ? 'PM' : 'AM';
    var h = t.hour % 12;
    if (h == 0) h = 12;
    final hh = h.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return ('$hh:$mm', ampm);
  }

  String _formatDate(DateTime t) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${t.day}${_ordinal(t.day)} ${months[t.month - 1]} '
        '${weekdays[t.weekday - 1]}';
  }

  String _ordinal(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}

class _SceneTile extends StatelessWidget {
  const _SceneTile({required this.scene, required this.onTap});

  final HomeScene scene;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        height: 96,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: SpaceColors.bgSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: SpaceColors.stroke),
        ),
        child: Row(
          children: [
            Text(scene.icon, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                scene.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: SpaceColors.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.play_arrow_rounded,
                color: SpaceColors.accentStart, size: 26),
          ],
        ),
      ),
    );
  }
}
