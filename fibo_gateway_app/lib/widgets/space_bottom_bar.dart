import 'package:flutter/material.dart';

import '../theme/space_tokens.dart';

enum SpaceTab { home, scenes, spaces, assistant }

class SpaceBottomBar extends StatelessWidget {
  const SpaceBottomBar({super.key, required this.active});

  final SpaceTab active;

  static const _route = {
    SpaceTab.home: '/home/profile',
    SpaceTab.scenes: '/home/scenes',
    SpaceTab.spaces: '/spaces',
    SpaceTab.assistant: '/assistant',
  };

  static const _icon = {
    SpaceTab.home: Icons.home_filled,
    SpaceTab.scenes: Icons.bolt_outlined,
    SpaceTab.spaces: Icons.space_dashboard_outlined,
    SpaceTab.assistant: Icons.auto_awesome_outlined,
  };

  static const _label = {
    SpaceTab.home: 'Home',
    SpaceTab.scenes: 'Scenes',
    SpaceTab.spaces: 'Spaces',
    SpaceTab.assistant: 'Assistant',
  };

  @override
  Widget build(BuildContext context) {
    final tabs = SpaceTab.values;
    final children = <Widget>[];
    for (var i = 0; i < tabs.length; i++) {
      final tab = tabs[i];
      final selected = tab == active;
      children.add(
        selected
            ? Expanded(child: _SelectedPill(tab: tab))
            : _IconOnlyButton(
                tab: tab,
                onTap: () => Navigator.of(
                  context,
                ).pushReplacementNamed(_route[tab]!),
              ),
      );
      if (i != tabs.length - 1) {
        children.add(const SizedBox(width: 8));
      }
    }

    return Container(
      height: 86,
      color: SpaceColors.bgBase,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(children: children),
    );
  }
}

class _SelectedPill extends StatelessWidget {
  const _SelectedPill({required this.tab});

  final SpaceTab tab;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        gradient: const LinearGradient(
          colors: [SpaceColors.accentStart, SpaceColors.accentEnd],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            SpaceBottomBar._icon[tab],
            color: SpaceColors.textPrimary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            SpaceBottomBar._label[tab]!,
            style: SpaceTextStyles.pillTitle,
          ),
        ],
      ),
    );
  }
}

class _IconOnlyButton extends StatelessWidget {
  const _IconOnlyButton({required this.tab, required this.onTap});

  final SpaceTab tab;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: SpaceColors.bgElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: SpaceColors.stroke),
        ),
        child: Icon(
          SpaceBottomBar._icon[tab],
          color: SpaceColors.textMuted,
          size: 20,
        ),
      ),
    );
  }
}
