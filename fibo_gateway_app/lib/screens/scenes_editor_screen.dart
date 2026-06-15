import 'package:flutter/material.dart';

import '../services/home_graph.dart';
import '../services/scenes_service.dart';
import '../theme/scenes_tokens.dart';
import 'space_models.dart';

/// Real Parse-backed scene editor: name + emoji + a list of device actions
/// (deterministic desired-state writes). Create (no args) or edit (sceneId).
/// Triggers are intentionally absent — the Parse V1 model is manual scenes.
class ScenesEditorScreen extends StatefulWidget {
  const ScenesEditorScreen({super.key});

  @override
  State<ScenesEditorScreen> createState() => _ScenesEditorScreenState();
}

class _ScenesEditorScreenState extends State<ScenesEditorScreen> {
  final TextEditingController _name = TextEditingController();
  final List<SceneActionDraft> _actions = [];
  String _emoji = '✨';
  String? _sceneId;
  bool _loaded = false;
  bool _busy = false;

  static const _emojis = ['✨', '☀️', '🌙', '🍿', '🔒', '🏠', '🥁', '🌅', '🏃', '🛌'];

  HomeGraph? get _graph => SpaceMockStore.instance.homeGraph;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    _sceneId = args is String ? args : null;
    final graph = _graph;
    if (_sceneId != null && graph != null) {
      final scene = graph.scenes.where((s) => s.sceneId == _sceneId).firstOrNull;
      if (scene != null) {
        _name.text = scene.name;
        _emoji = scene.icon;
      }
      _loadActions(graph.homeId, _sceneId!);
    }
    _loaded = true;
  }

  Future<void> _loadActions(String homeId, String sceneId) async {
    try {
      final actions = await fetchSceneActions(homeId, sceneId);
      if (!mounted) return;
      setState(() => _actions
        ..clear()
        ..addAll(actions));
    } catch (_) {/* keep empty */}
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  HomeDevice? _device(String endpointKey) =>
      _graph?.devices.where((d) => d.endpointKey == endpointKey).firstOrNull;

  Future<void> _save() async {
    final graph = _graph;
    final name = _name.text.trim();
    if (graph == null) return;
    if (name.isEmpty) {
      _toast('Give the scene a name.');
      return;
    }
    if (_actions.isEmpty) {
      _toast('Add at least one device action.');
      return;
    }
    setState(() => _busy = true);
    try {
      await saveScene(
        homeId: graph.homeId,
        sceneId: _sceneId,
        name: name,
        icon: _emoji,
        actions: _actions,
      );
      await SpaceMockStore.instance.hydrateFromShadows(); // refresh scenes
      if (mounted) Navigator.of(context).pop();
    } catch (err) {
      if (mounted) {
        setState(() => _busy = false);
        _toast('Save failed: $err');
      }
    }
  }

  Future<void> _delete() async {
    final graph = _graph;
    if (graph == null || _sceneId == null) return;
    setState(() => _busy = true);
    try {
      await deleteScene(homeId: graph.homeId, sceneId: _sceneId!);
      await SpaceMockStore.instance.hydrateFromShadows();
      if (mounted) Navigator.of(context).pop();
    } catch (err) {
      if (mounted) {
        setState(() => _busy = false);
        _toast('Delete failed: $err');
      }
    }
  }

  void _run() {
    if (_sceneId == null) return;
    SpaceMockStore.instance.runScene(_sceneId!);
    _toast('Running ${_name.text.trim()}…');
  }

  void _toast(String t) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(t), duration: const Duration(seconds: 2)));

  Future<void> _addAction() async {
    final graph = _graph;
    if (graph == null) return;
    final controllable =
        graph.devices.where((d) => d.isSceneControllable).toList();
    final draft = await showModalBottomSheet<SceneActionDraft>(
      context: context,
      backgroundColor: ScenesColors.bgElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddActionSheet(devices: controllable),
    );
    if (draft != null) setState(() => _actions.add(draft));
  }

  @override
  Widget build(BuildContext context) {
    final editing = _sceneId != null;
    return Scaffold(
      backgroundColor: ScenesColors.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            _header(editing),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  ScenesLayout.horizontalPadding, 16,
                  ScenesLayout.horizontalPadding, 24),
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _emoji =
                            _emojis[(_emojis.indexOf(_emoji) + 1) % _emojis.length]),
                        child: Container(
                          width: 64,
                          height: 64,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: ScenesColors.bgField,
                            borderRadius: BorderRadius.circular(ScenesRadii.card),
                          ),
                          child: Text(_emoji, style: const TextStyle(fontSize: 34)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          decoration: BoxDecoration(
                            color: ScenesColors.bgField,
                            borderRadius: BorderRadius.circular(ScenesRadii.card),
                          ),
                          child: TextField(
                            controller: _name,
                            style: ScenesTextStyles.mutedBody,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isCollapsed: true,
                              hintText: 'Scene Name',
                              hintStyle: ScenesTextStyles.mutedBody,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      const Text('Actions', style: ScenesTextStyles.sectionTitle),
                      const Spacer(),
                      InkWell(
                        onTap: _addAction,
                        child: const Text('Add', style: ScenesTextStyles.buttonSmall),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_actions.isEmpty)
                    Text('No actions yet — tap Add to control a device.',
                        style: ScenesTextStyles.caption),
                  for (var i = 0; i < _actions.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _actionCard(_actions[i], () =>
                          setState(() => _actions.removeAt(i))),
                    ),
                  const SizedBox(height: 24),
                  _primaryButton(_busy ? 'Saving…' : 'Save Scene', _busy ? null : _save),
                  if (editing) ...[
                    const SizedBox(height: 12),
                    _secondaryButton('Run Now', _run),
                    const SizedBox(height: 12),
                    _secondaryButton('Delete Scene', _busy ? null : _delete,
                        danger: true),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(bool editing) => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: ScenesLayout.horizontalPadding),
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.arrow_back,
                    color: ScenesColors.textPrimary, size: 22),
              ),
              Expanded(
                child: Center(
                  child: Text(editing ? 'Edit Scene' : 'New Scene',
                      style: ScenesTextStyles.navTitle),
                ),
              ),
              const SizedBox(width: 22),
            ],
          ),
        ),
      );

  Widget _actionCard(SceneActionDraft a, VoidCallback onRemove) {
    final device = _device(a.endpointKey);
    final name = device?.displayName ?? a.endpointKey;
    final profile = device?.profile ?? '';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: ScenesGradients.surface,
        borderRadius: BorderRadius.circular(ScenesRadii.panel),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ScenesColors.bgElevated,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(_iconFor(profile), color: ScenesColors.textPrimary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: ScenesTextStyles.buttonSmall),
                const SizedBox(height: 2),
                Text(_summary(profile, a.state), style: ScenesTextStyles.caption),
              ],
            ),
          ),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.close, color: ScenesColors.textMuted, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton(String text, VoidCallback? onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ScenesRadii.card),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ScenesRadii.card),
            color: ScenesColors.accentStart,
          ),
          child: Text(text, style: ScenesTextStyles.button),
        ),
      );

  Widget _secondaryButton(String text, VoidCallback? onTap, {bool danger = false}) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ScenesRadii.card),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ScenesRadii.card),
            border: Border.all(
                color: danger ? const Color(0xFFB44A66) : ScenesColors.bgElevated),
          ),
          child: Text(text,
              style: ScenesTextStyles.buttonSmall.copyWith(
                  color: danger ? const Color(0xFFFFB4C2) : ScenesColors.textPrimary)),
        ),
      );

  static IconData _iconFor(String profile) {
    switch (profile) {
      case 'color_light':
      case 'dimmable_light':
        return Icons.lightbulb_outline;
      case 'onoff_actuator':
        return Icons.tv_outlined;
      case 'curtain':
        return Icons.blinds_outlined;
      case 'door_lock':
        return Icons.lock_outline;
      default:
        return Icons.devices_other_outlined;
    }
  }

  static String _summary(String profile, Map<String, dynamic> s) {
    switch (profile) {
      case 'color_light':
      case 'dimmable_light':
        if (s['power'] != 1) return 'Turn off';
        final lvl = s['level'];
        return lvl is num ? 'On · ${(lvl / 254 * 100).round()}%' : 'Turn on';
      case 'onoff_actuator':
        return s['power'] == 1 ? 'Turn on' : 'Turn off';
      case 'curtain':
        final t = s['target_lift_percent'];
        return (t is num && t > 0) ? 'Open' : 'Close';
      case 'door_lock':
        return s['locked'] == true ? 'Lock' : 'Unlock';
      default:
        return '';
    }
  }
}

/// Bottom sheet: pick a device, then set its target state.
class _AddActionSheet extends StatefulWidget {
  const _AddActionSheet({required this.devices});
  final List<HomeDevice> devices;

  @override
  State<_AddActionSheet> createState() => _AddActionSheetState();
}

class _AddActionSheetState extends State<_AddActionSheet> {
  HomeDevice? _selected;
  bool _on = true;
  double _level = 60; // percent

  @override
  Widget build(BuildContext context) {
    final d = _selected;
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 18,
        bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(d == null ? 'Choose a device' : d.displayName,
              style: ScenesTextStyles.sectionTitle),
          const SizedBox(height: 14),
          if (d == null)
            ...widget.devices.map((dev) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(_ScenesEditorScreenState._iconFor(dev.profile),
                      color: ScenesColors.textPrimary),
                  title: Text(dev.displayName, style: ScenesTextStyles.body),
                  trailing: const Icon(Icons.chevron_right,
                      color: ScenesColors.textMuted),
                  onTap: () => setState(() => _selected = dev),
                ))
          else ...[
            _stateControls(d),
            const SizedBox(height: 18),
            InkWell(
              onTap: () => Navigator.of(context).pop(
                  SceneActionDraft(endpointKey: d.endpointKey, state: _stateFor(d))),
              borderRadius: BorderRadius.circular(ScenesRadii.card),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ScenesColors.accentStart,
                  borderRadius: BorderRadius.circular(ScenesRadii.card),
                ),
                child: const Text('Add Action', style: ScenesTextStyles.button),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stateControls(HomeDevice d) {
    switch (d.profile) {
      case 'color_light':
      case 'dimmable_light':
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _onOff('Off', 'On'),
          if (_on) ...[
            const SizedBox(height: 8),
            Text('Brightness ${_level.round()}%', style: ScenesTextStyles.caption),
            Slider(
              value: _level, min: 0, max: 100,
              activeColor: ScenesColors.accentStart,
              onChanged: (v) => setState(() => _level = v),
            ),
          ],
        ]);
      case 'curtain':
        return _onOff('Close', 'Open');
      case 'door_lock':
        return _onOff('Unlock', 'Lock');
      default: // onoff_actuator
        return _onOff('Off', 'On');
    }
  }

  Widget _onOff(String offLabel, String onLabel) => Row(
        children: [
          for (final on in [false, true])
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _on = on),
                child: Container(
                  margin: EdgeInsets.only(right: on ? 0 : 8),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _on == on ? ScenesColors.accentStart : ScenesColors.bgField,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(on ? onLabel : offLabel,
                      style: ScenesTextStyles.buttonSmall.copyWith(
                          color: ScenesColors.textPrimary)),
                ),
              ),
            ),
        ],
      );

  Map<String, dynamic> _stateFor(HomeDevice d) {
    switch (d.profile) {
      case 'color_light':
      case 'dimmable_light':
        return _on
            ? {'power': 1, 'level': (_level / 100 * 254).round()}
            : {'power': 0};
      case 'curtain':
        return {'target_lift_percent': _on ? 100 : 0};
      case 'door_lock':
        return {'locked': _on};
      default:
        return {'power': _on ? 1 : 0};
    }
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
