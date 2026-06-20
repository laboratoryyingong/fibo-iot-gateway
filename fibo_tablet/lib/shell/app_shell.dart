import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:fibo_core/theme/space_tokens.dart';

import '../screens/home_dashboard_screen.dart';
import '../screens/scenes_screen.dart';
import '../screens/assistant_panel_screen.dart';
import '../screens/login_screen.dart';
import '../state/home_controller.dart';

/// Persistent landscape layout for the control hub: a fixed left sidebar with
/// the primary destinations, and a content pane that swaps between them.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  final _home = HomeController();

  static const _destinations = <_Destination>[
    _Destination('Home', Icons.dashboard_rounded, Icons.dashboard_outlined),
    _Destination('Scenes', Icons.auto_awesome_rounded, Icons.auto_awesome_outlined),
    _Destination('Assistant', Icons.smart_toy_rounded, Icons.smart_toy_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _home.load();
  }

  @override
  void dispose() {
    _home.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    final user = await ParseUser.currentUser() as ParseUser?;
    await user?.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

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
              onSignOut: _signOut,
              home: _home,
            ),
            Expanded(
              child: IndexedStack(
                index: _index,
                children: [
                  HomeDashboardScreen(controller: _home),
                  ScenesScreen(controller: _home),
                  const AssistantPanelScreen(),
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
    required this.onSignOut,
    required this.home,
  });

  final List<_Destination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onSignOut;
  final HomeController home;

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
          _GatewayStatus(home: home),
          _SignOutButton(onTap: onSignOut),
        ],
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.logout_rounded,
                    size: 20, color: SpaceColors.textMuted),
                SizedBox(width: 14),
                Text(
                  'Sign out',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: SpaceColors.textMuted,
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

/// Live connection footer — reflects whether the IoT shadow stream is up.
class _GatewayStatus extends StatelessWidget {
  const _GatewayStatus({required this.home});

  final HomeController home;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: home,
      builder: (context, _) {
        final connected = home.shadowsConnected;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: connected
                      ? const Color(0xFF34D399)
                      : SpaceColors.textMuted,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  connected ? 'Connected' : 'Connecting…',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13,
                    color: SpaceColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Destination {
  const _Destination(this.label, this.activeIcon, this.icon);

  final String label;
  final IconData activeIcon;
  final IconData icon;
}
