import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fibo_core/services/home_graph.dart';
import 'package:fibo_core/theme/space_tokens.dart';

import '../state/home_controller.dart';
import '../widgets/connection_icon.dart';
import '../widgets/device_icons.dart';

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
                      _shortcuts(),
                    ],
                  ),
                ),
                Positioned(
                  right: 18,
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
        _brand(),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ConnectionIcon(connected: widget.controller.shadowsConnected),
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
          ),
        ),
      ],
    );
  }

  /// FIBO logo + wordmark (placeholder logo mark pending the final asset).
  Widget _brand() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [SpaceColors.accentStart, SpaceColors.accentEnd],
            ),
          ),
          child: const Icon(Icons.hub_rounded, color: Colors.white, size: 19),
        ),
        const SizedBox(width: 10),
        const Text(
          'FIBO',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: SpaceColors.textPrimary,
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
          children: const [
            Icon(Icons.chevron_right_rounded,
                color: SpaceColors.textMuted, size: 40),
            Icon(Icons.dashboard_rounded,
                color: SpaceColors.textMuted, size: 24),
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

  /// Two rows of quick shortcuts: devices, then scenes — each four wide, with
  /// empty slots shown as "+" tiles.
  Widget _shortcuts() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _shortcutRow(_deviceShortcuts()),
        const SizedBox(height: 14),
        _shortcutRow(_sceneShortcuts()),
      ],
    );
  }

  Widget _shortcutRow(List<Widget> tiles) {
    return Row(
      children: [
        for (var i = 0; i < 4; i++) ...[
          Expanded(child: i < tiles.length ? tiles[i] : const _AddTile()),
          if (i < 3) const SizedBox(width: 14),
        ],
      ],
    );
  }

  List<Widget> _deviceShortcuts() {
    final out = <Widget>[];
    for (final room in widget.controller.rooms) {
      for (final device in room.devices) {
        final v = widget.controller.viewFor(device);
        if (v.isToggle || v.isLock) {
          out.add(_DeviceShortcut(
              controller: widget.controller, device: device));
          if (out.length == 4) return out;
        }
      }
    }
    return out;
  }

  List<Widget> _sceneShortcuts() {
    return [
      for (final s in widget.controller.scenes.take(4))
        _SceneShortcut(scene: s, onTap: () => _runScene(s)),
    ];
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

/// Shared compact shortcut tile: a centered icon area + label.
class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final Widget icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 96,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: SpaceColors.bgSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active ? SpaceColors.accentStart : SpaceColors.stroke,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: SpaceColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceShortcut extends StatelessWidget {
  const _DeviceShortcut({required this.controller, required this.device});

  final HomeController controller;
  final HomeDevice device;

  @override
  Widget build(BuildContext context) {
    final v = controller.viewFor(device);
    final on = v.isOn && v.kind != DeviceKind.sensor;
    return _ShortcutTile(
      active: on,
      onTap: () => controller.toggle(device),
      label: device.displayName,
      icon: Icon(
        iconForProfile(device.profile),
        size: 26,
        color: on ? SpaceColors.accentStart : SpaceColors.textPrimary,
      ),
    );
  }
}

class _SceneShortcut extends StatelessWidget {
  const _SceneShortcut({required this.scene, required this.onTap});

  final HomeScene scene;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _ShortcutTile(
      onTap: onTap,
      label: scene.name,
      icon: Text(scene.icon, style: const TextStyle(fontSize: 26)),
    );
  }
}

/// Empty shortcut slot shown as a "+" (matches the reference layout).
class _AddTile extends StatelessWidget {
  const _AddTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: SpaceColors.bgSurface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SpaceColors.stroke),
      ),
      child: const Icon(Icons.add_rounded, color: SpaceColors.textMuted, size: 28),
    );
  }
}
