import 'package:flutter/material.dart';

import '../screens/assistant_models.dart';
import '../theme/space_tokens.dart';

class AssistantToolChip extends StatelessWidget {
  const AssistantToolChip({super.key, required this.chip});

  final ToolCallChipState chip;

  @override
  Widget build(BuildContext context) {
    final visual = _resolveVisual(chip);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: visual.background,
        border: Border.all(color: visual.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: visual.leading,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              visual.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: SpaceTextStyles.pillMeta.copyWith(
                color: visual.text,
                fontWeight: FontWeight.w500,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _ChipVisual _resolveVisual(ToolCallChipState chip) {
    if (chip.isPending) {
      return _ChipVisual(
        background: SpaceColors.bgElevated,
        border: SpaceColors.stroke,
        text: SpaceColors.textMuted,
        label: _pendingLabel(chip),
        leading: const CircularProgressIndicator(
          strokeWidth: 2,
          color: SpaceColors.textMuted,
        ),
      );
    }
    if (chip.requiresConfirmation) {
      return _ChipVisual(
        background: const Color(0xFF4A3E16),
        border: const Color(0xFFFFB547),
        text: const Color(0xFFFFD17A),
        label: _confirmationLabel(chip),
        leading: const Icon(
          Icons.help_outline,
          size: 14,
          color: Color(0xFFFFD17A),
        ),
      );
    }
    if (chip.didNotConverge) {
      return _ChipVisual(
        background: const Color(0xFF3D2E1A),
        border: const Color(0xFFD89060),
        text: const Color(0xFFE7B78A),
        label: _unconfirmedLabel(chip),
        leading: const Icon(
          Icons.sync_problem,
          size: 14,
          color: Color(0xFFE7B78A),
        ),
      );
    }
    if (chip.isFailure) {
      return _ChipVisual(
        background: const Color(0xFF4A2330),
        border: const Color(0xFFB44A66),
        text: const Color(0xFFFFB4C2),
        label: _errorLabel(chip),
        leading: const Icon(
          Icons.error_outline,
          size: 14,
          color: Color(0xFFFFB4C2),
        ),
      );
    }
    return _ChipVisual(
      background: SpaceColors.bgElevated,
      border: SpaceColors.accentStart,
      text: SpaceColors.textPrimary,
      label: _successLabel(chip),
      leading: const Icon(
        Icons.check_circle,
        size: 14,
        color: SpaceColors.accentStart,
      ),
    );
  }
}

class _ChipVisual {
  _ChipVisual({
    required this.background,
    required this.border,
    required this.text,
    required this.label,
    required this.leading,
  });

  final Color background;
  final Color border;
  final Color text;
  final String label;
  final Widget leading;
}

String _pendingLabel(ToolCallChipState chip) {
  switch (chip.name) {
    case 'get_devices':
      return 'Looking up devices…';
    case 'get_device_status':
      return 'Checking device…';
    case 'get_room_status':
      final room = chip.input['room'];
      return room is String ? 'Checking $room…' : 'Checking room…';
    case 'control_device':
      final action = chip.input['action'] ?? 'action';
      return 'Sending $action…';
    case 'run_scene':
      final scene = chip.input['scene_id'] ?? 'scene';
      return 'Activating $scene…';
    default:
      return 'Calling ${chip.name}…';
  }
}

String _confirmationLabel(ToolCallChipState chip) {
  final deviceId = chip.input['device_id'];
  if (deviceId is String) {
    return 'Confirmation needed: $deviceId';
  }
  return 'Confirmation needed';
}

String _unconfirmedLabel(ToolCallChipState chip) {
  final output = chip.output ?? const <String, dynamic>{};
  final action = chip.input['action'] as String? ?? 'action';
  final name = (output['name'] as String?) ??
      (chip.input['device_id'] as String? ?? 'device');
  return 'Tried $action on $name — device did not confirm';
}

String _errorLabel(ToolCallChipState chip) {
  final err = chip.output?['error'];
  if (err is String) {
    final trimmed = err.length > 80 ? '${err.substring(0, 77)}…' : err;
    return 'Error: $trimmed';
  }
  return 'Error in ${chip.name}';
}

String _successLabel(ToolCallChipState chip) {
  final output = chip.output ?? const <String, dynamic>{};
  switch (chip.name) {
    case 'get_devices':
      return 'Looked up devices';
    case 'get_device_status':
      final name = output['name'];
      return name is String ? 'Checked $name' : 'Checked device';
    case 'get_room_status':
      final room = chip.input['room'];
      return room is String ? 'Checked $room' : 'Checked room';
    case 'control_device':
      return _controlDeviceLabel(chip);
    case 'run_scene':
      return _runSceneLabel(chip);
    default:
      return chip.name;
  }
}

String _controlDeviceLabel(ToolCallChipState chip) {
  final output = chip.output ?? const <String, dynamic>{};
  final name = (output['name'] as String?) ?? (chip.input['device_id'] as String? ?? 'device');
  final action = chip.input['action'] as String? ?? '';
  switch (action) {
    case 'turn_on':
      return 'Turned on $name';
    case 'turn_off':
      return 'Turned off $name';
    case 'set_brightness':
      final params = chip.input['params'];
      if (params is Map && params['value'] is num) {
        return 'Set $name to ${(params['value'] as num).round()}%';
      }
      return 'Adjusted brightness on $name';
    case 'set_temperature':
      final params = chip.input['params'];
      if (params is Map && params['value'] is num) {
        return 'Set $name to ${(params['value'] as num).round()}°';
      }
      return 'Adjusted $name';
    case 'unlock':
      return 'Unlocked $name';
    case 'lock':
      return 'Locked $name';
    case 'open':
      return 'Opened $name';
    case 'close':
      return 'Closed $name';
    default:
      return action.isEmpty ? name : '$action on $name';
  }
}

String _runSceneLabel(ToolCallChipState chip) {
  final output = chip.output ?? const <String, dynamic>{};
  final scene = output['scene'];
  final sceneName = (scene is Map && scene['name'] is String)
      ? scene['name'] as String
      : (chip.input['scene_id'] as String? ?? 'scene');
  final results = output['results'];
  if (results is List) {
    final total = results.length;
    final ok = results.where((r) => r is Map && r['ok'] == true).length;
    if (total > 0 && ok != total) {
      return 'Activated $sceneName ($ok/$total succeeded)';
    }
  }
  return 'Activated $sceneName';
}
