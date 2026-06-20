import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fibo_core/services/home_graph.dart';
import 'package:fibo_core/theme/space_tokens.dart';

import '../state/home_controller.dart';
import '../state/shortcuts_controller.dart';
import '../widgets/connection_icon.dart';
import '../widgets/device_icons.dart';

/// Ambient "glance" page shown before Home: a large live clock, date, an
/// at-a-glance temperature + device summary, connection state, a mic shortcut
/// into the assistant, and one-tap scene tiles.
class StandbyScreen extends StatefulWidget {
  const StandbyScreen({
    super.key,
    required this.controller,
    required this.shortcuts,
    required this.onAssistant,
    this.onNext,
  });

  final HomeController controller;
  final ShortcutsController shortcuts;
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
          listenable: Listenable.merge([widget.controller, widget.shortcuts]),
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
                      const SizedBox(height: 28),
                      Expanded(child: _shortcuts()),
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

  /// Two titled rows of quick shortcuts (devices, then scenes) that fill the
  /// space; each is four wide with empty slots shown as "+" tiles.
  Widget _shortcuts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _rowTitle('Devices'),
        const SizedBox(height: 12),
        Expanded(child: _shortcutRow(_deviceShortcuts(), _pickDevice)),
        const SizedBox(height: 22),
        _rowTitle('Scenes'),
        const SizedBox(height: 12),
        Expanded(child: _shortcutRow(_sceneShortcuts(), _pickScene)),
      ],
    );
  }

  Widget _rowTitle(String text) {
    return Text(text, style: SpaceTextStyles.cardTitle);
  }

  Widget _shortcutRow(List<Widget> tiles, VoidCallback onAdd) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < 4; i++) ...[
          Expanded(
            child: i < tiles.length ? tiles[i] : _AddTile(onTap: onAdd),
          ),
          if (i < 3) const SizedBox(width: 14),
        ],
      ],
    );
  }

  /// Pinned device shortcuts, resolved from saved keys against the live graph.
  List<Widget> _deviceShortcuts() {
    final graph = widget.controller.graph;
    if (graph == null) return const [];
    final out = <Widget>[];
    for (final key in widget.shortcuts.deviceKeys) {
      final device = graph.devices
          .where((d) => d.shadowName == key)
          .cast<HomeDevice?>()
          .firstWhere((d) => true, orElse: () => null);
      if (device == null) continue;
      out.add(_DeviceShortcut(
        controller: widget.controller,
        device: device,
        onRemove: () => _removeDevice(device),
      ));
    }
    return out;
  }

  List<Widget> _sceneShortcuts() {
    final byId = {for (final s in widget.controller.scenes) s.sceneId: s};
    final out = <Widget>[];
    for (final id in widget.shortcuts.sceneIds) {
      final scene = byId[id];
      if (scene == null) continue;
      out.add(_SceneShortcut(
        scene: scene,
        onTap: () => _runScene(scene),
        onRemove: () => _removeScene(scene),
      ));
    }
    return out;
  }

  // --- Add / remove --------------------------------------------------------

  void _removeDevice(HomeDevice device) {
    widget.shortcuts.removeDevice(device.shadowName);
    _snack('Removed ${device.displayName}',
        onUndo: () => widget.shortcuts.addDevice(device.shadowName));
  }

  void _removeScene(HomeScene scene) {
    widget.shortcuts.removeScene(scene.sceneId);
    _snack('Removed ${scene.name}',
        onUndo: () => widget.shortcuts.addScene(scene.sceneId));
  }

  Future<void> _pickDevice() async {
    final graph = widget.controller.graph;
    if (graph == null) return;
    final pinned = widget.shortcuts.deviceKeys.toSet();
    final options = [
      for (final room in widget.controller.rooms)
        for (final d in room.devices)
          if (() {
                final v = widget.controller.viewFor(d);
                return (v.isToggle || v.isLock) && !pinned.contains(d.shadowName);
              }())
            d,
    ];
    final picked = await _showPicker<HomeDevice>(
      title: 'Add a device',
      options: options,
      iconBuilder: (d) => Icon(iconForProfile(d.profile),
          color: SpaceColors.textPrimary, size: 22),
      labelBuilder: (d) => d.displayName,
    );
    if (picked != null) widget.shortcuts.addDevice(picked.shadowName);
  }

  Future<void> _pickScene() async {
    final pinned = widget.shortcuts.sceneIds.toSet();
    final options = [
      for (final s in widget.controller.scenes)
        if (!pinned.contains(s.sceneId)) s,
    ];
    final picked = await _showPicker<HomeScene>(
      title: 'Add a scene',
      options: options,
      iconBuilder: (s) => Text(s.icon, style: const TextStyle(fontSize: 22)),
      labelBuilder: (s) => s.name,
    );
    if (picked != null) widget.shortcuts.addScene(picked.sceneId);
  }

  Future<T?> _showPicker<T>({
    required String title,
    required List<T> options,
    required Widget Function(T) iconBuilder,
    required String Function(T) labelBuilder,
  }) {
    return showDialog<T>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: SpaceColors.bgSurface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Text(title, style: SpaceTextStyles.cardTitle),
              ),
              if (options.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Text('Nothing left to add.',
                      style: SpaceTextStyles.cardMeta),
                )
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 12),
                    children: [
                      for (final o in options)
                        ListTile(
                          leading: iconBuilder(o),
                          title: Text(labelBuilder(o),
                              style: SpaceTextStyles.pillTitle),
                          onTap: () => Navigator.of(ctx).pop(o),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _snack(String message, {VoidCallback? onUndo}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: SpaceColors.bgElevated,
        content: Text(message,
            style: const TextStyle(fontFamily: 'Manrope', color: Colors.white)),
        action: onUndo == null
            ? null
            : SnackBarAction(
                label: 'Undo',
                textColor: SpaceColors.accentStart,
                onPressed: onUndo,
              ),
      ),
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

/// Shared compact shortcut tile: a centered icon area + label.
class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.onLongPress,
    this.active = false,
  });

  final Widget icon;
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
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
  const _DeviceShortcut({
    required this.controller,
    required this.device,
    required this.onRemove,
  });

  final HomeController controller;
  final HomeDevice device;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final v = controller.viewFor(device);
    final on = v.isOn && v.kind != DeviceKind.sensor;
    return _ShortcutTile(
      active: on,
      onTap: () => controller.toggle(device),
      onLongPress: onRemove,
      label: device.displayName,
      icon: Icon(
        iconForProfile(device.profile),
        size: 34,
        color: on ? SpaceColors.accentStart : SpaceColors.textPrimary,
      ),
    );
  }
}

class _SceneShortcut extends StatelessWidget {
  const _SceneShortcut({
    required this.scene,
    required this.onTap,
    required this.onRemove,
  });

  final HomeScene scene;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _ShortcutTile(
      onTap: onTap,
      onLongPress: onRemove,
      label: scene.name,
      icon: Text(scene.icon, style: const TextStyle(fontSize: 32)),
    );
  }
}

/// Empty shortcut slot shown as a tappable "+" that opens the add picker.
class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: SpaceColors.bgSurface.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: SpaceColors.stroke),
        ),
        child: const Icon(Icons.add_rounded,
            color: SpaceColors.textMuted, size: 30),
      ),
    );
  }
}
