import 'package:flutter/material.dart';
import 'package:fibo_core/theme/space_tokens.dart';

import '../screens/home_dashboard_screen.dart';
import '../screens/scenes_screen.dart';
import '../screens/assistant_panel_screen.dart';

/// Persistent landscape layout for the control hub: a fixed left sidebar with
/// the primary destinations, and a content pane that swaps between them.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _destinations = <_Destination>[
    _Destination('Home', Icons.dashboard_rounded, Icons.dashboard_outlined),
    _Destination('Scenes', Icons.auto_awesome_rounded, Icons.auto_awesome_outlined),
    _Destination('Assistant', Icons.smart_toy_rounded, Icons.smart_toy_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpaceColors.bgBase,
      body: SafeArea(
        child: Row(
          children: [
            _Sidebar(
              destinations: _destinations,
              selectedIndex: _index,
              onSelect: (i) => setState(() => _index = i),
            ),
            Expanded(
              child: IndexedStack(
                index: _index,
                children: const [
                  HomeDashboardScreen(),
                  ScenesScreen(),
                  AssistantPanelScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<_Destination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 232,
      decoration: const BoxDecoration(
        color: SpaceColors.bgSurface,
        border: Border(right: BorderSide(color: SpaceColors.stroke)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Brand(),
          const SizedBox(height: 8),
          for (var i = 0; i < destinations.length; i++)
            _NavItem(
              key: ValueKey('nav-${destinations[i].label}'),
              destination: destinations[i],
              selected: i == selectedIndex,
              onTap: () => onSelect(i),
            ),
          const Spacer(),
          const _GatewayStatus(),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [SpaceColors.accentStart, SpaceColors.accentEnd],
              ),
            ),
            child: const Icon(Icons.hub_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Fibo',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: SpaceColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    super.key,
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: selected ? SpaceColors.bgElevated : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(
                  selected ? destination.activeIcon : destination.icon,
                  size: 22,
                  color: selected
                      ? SpaceColors.accentStart
                      : SpaceColors.textMuted,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    destination.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 16,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected
                          ? SpaceColors.textPrimary
                          : SpaceColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Placeholder gateway status footer — wired to real gateway state in a later
/// phase. For now it reads as a neutral, truthful "not connected yet".
class _GatewayStatus extends StatelessWidget {
  const _GatewayStatus();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: SpaceColors.textMuted,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Gateway offline',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                color: SpaceColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Destination {
  const _Destination(this.label, this.activeIcon, this.icon);

  final String label;
  final IconData activeIcon;
  final IconData icon;
}
