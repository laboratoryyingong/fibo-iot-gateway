import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:fibo_core/theme/space_tokens.dart';

import '../screens/home_dashboard_screen.dart';
import '../screens/scenes_screen.dart';
import '../screens/assistant_panel_screen.dart';
import '../screens/login_screen.dart';
import '../screens/standby_screen.dart';
import '../state/home_controller.dart';
import '../state/shortcuts_controller.dart';
import '../widgets/connection_icon.dart';

/// Landscape control-hub shell, phone-styled: a greeting header, two swipeable
/// pages (Home / Scenes), and a floating orb into the assistant.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _home = HomeController();
  final _shortcuts = ShortcutsController();
  // Page 0 is the ambient standby/glance screen; 1 = Home, 2 = Scenes. Launch
  // on the standby screen.
  final _pageController = PageController(initialPage: 0);
  int _page = 0;
  String _greetingName = '';
  String _initials = '';

  static const _tabs = ['Home', 'Scenes'];

  @override
  void initState() {
    super.initState();
    _home.load();
    _shortcuts.load();
    _home.addListener(_maybeSeedShortcuts);
    _shortcuts.addListener(_maybeSeedShortcuts);
    _loadUser();
  }

  /// Seed the standby shortcuts once, from the first controllable devices and
  /// all scenes, after both the home graph and the saved pins have loaded.
  void _maybeSeedShortcuts() {
    if (!_shortcuts.needsSeed || _home.graph == null) return;
    final devices = <String>[];
    for (final room in _home.rooms) {
      for (final d in room.devices) {
        final v = _home.viewFor(d);
        if (v.isToggle || v.isLock) {
          devices.add(d.shadowName);
          if (devices.length == ShortcutsController.max) break;
        }
      }
      if (devices.length == ShortcutsController.max) break;
    }
    _shortcuts.seedIfNeeded(
      devices: devices,
      scenes: _home.scenes.map((s) => s.sceneId).toList(),
    );
  }

  Future<void> _loadUser() async {
    final user = await ParseUser.currentUser() as ParseUser?;
    if (user == null || !mounted) return;
    final name = user.get<String>('fullName') ??
        user.get<String>('name') ??
        user.username ??
        user.emailAddress ??
        '';
    setState(() {
      _greetingName = _friendlyFirstName(name);
      _initials = _initialsOf(name);
    });
  }

  /// A short, friendly first name from a full name, username or email.
  static String _friendlyFirstName(String raw) {
    var s = raw.trim();
    final at = s.indexOf('@');
    if (at > 0) s = s.substring(0, at); // drop email domain
    final first = s.split(RegExp(r'[._\s]+')).firstWhere(
          (p) => p.isNotEmpty,
          orElse: () => '',
        );
    if (first.isEmpty) return '';
    return first[0].toUpperCase() + first.substring(1);
  }

  static String _initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'H';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  @override
  void dispose() {
    _home.removeListener(_maybeSeedShortcuts);
    _shortcuts.removeListener(_maybeSeedShortcuts);
    _home.dispose();
    _shortcuts.dispose();
    _pageController.dispose();
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

  void _selectTab(int i) {
    // Tabs map to pages 1 (Home) and 2 (Scenes); page 0 is the standby screen.
    _pageController.animateToPage(
      i + 1,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  void _openAssistant() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _AssistantRoute()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpaceColors.bgBase,
      // The standby screen has its own mic shortcut, so hide the orb there.
      floatingActionButton:
          _page == 0 ? null : _AssistantFab(onTap: _openAssistant),
      body: PageView(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _page = i),
        children: [
          StandbyScreen(
            controller: _home,
            shortcuts: _shortcuts,
            onAssistant: _openAssistant,
            onNext: () => _pageController.animateToPage(
              1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            ),
          ),
          _mainPage(HomeDashboardScreen(controller: _home)),
          _mainPage(ScenesScreen(controller: _home)),
        ],
      ),
    );
  }

  /// Home/Scenes pages share the greeting header + tab strip.
  Widget _mainPage(Widget content) {
    final tabIndex = (_page - 1).clamp(0, _tabs.length - 1);
    return SafeArea(
      child: Column(
        children: [
          _Header(
            greeting: _greetingName,
            initials: _initials,
            home: _home,
            onSignOut: _signOut,
          ),
          _TabStrip(tabs: _tabs, index: tabIndex, onTap: _selectTab),
          Expanded(child: content),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.greeting,
    required this.initials,
    required this.home,
    required this.onSignOut,
  });

  final String greeting;
  final String initials;
  final HomeController home;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 24, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              greeting.isEmpty ? 'Welcome' : 'Mornin’ $greeting!',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SpaceTextStyles.sectionTitle.copyWith(fontSize: 32),
            ),
          ),
          const SizedBox(width: 16),
          _ConnectionPill(home: home),
          const SizedBox(width: 14),
          PopupMenuButton<String>(
            color: SpaceColors.bgElevated,
            offset: const Offset(0, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (v) {
              if (v == 'sign-out') onSignOut();
            },
            itemBuilder: (_) => [
              PopupMenuItem<String>(
                value: 'sign-out',
                child: Row(
                  children: [
                    const Icon(Icons.logout_rounded,
                        size: 18, color: SpaceColors.textMuted),
                    const SizedBox(width: 10),
                    Text('Sign out',
                        style: SpaceTextStyles.pillTitle
                            .copyWith(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [SpaceColors.accentStart, SpaceColors.accentEnd],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                initials.isEmpty ? 'H' : initials,
                style: SpaceTextStyles.pillTitle
                    .copyWith(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Connection state shown as a wifi icon (green when the shadow stream is up,
/// muted wifi-off otherwise) — consistent across all pages.
class _ConnectionPill extends StatelessWidget {
  const _ConnectionPill({required this.home});

  final HomeController home;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: home,
      builder: (context, _) => ConnectionIcon(connected: home.shadowsConnected),
    );
  }
}

class _TabStrip extends StatelessWidget {
  const _TabStrip({required this.tabs, required this.index, required this.onTap});

  final List<String> tabs;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 8),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++) ...[
            _TabButton(
              label: tabs[i],
              selected: i == index,
              onTap: () => onTap(i),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? SpaceColors.bgSurface : Colors.transparent,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          child: Text(
            label,
            style: SpaceTextStyles.pillTitle.copyWith(
              fontSize: 16,
              color: selected ? SpaceColors.textPrimary : SpaceColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-screen assistant opened from the floating orb.
class _AssistantRoute extends StatelessWidget {
  const _AssistantRoute();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpaceColors.bgBase,
      body: SafeArea(
        child: Stack(
          children: [
            const AssistantPanelScreen(),
            Positioned(
              top: 16,
              left: 24,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: SpaceColors.bgSurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: SpaceColors.stroke),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      size: 22, color: SpaceColors.textPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Siri-style floating orb that opens the assistant: a glowing circular
/// gradient button with the assistant sparkle.
class _AssistantFab extends StatelessWidget {
  const _AssistantFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [SpaceColors.accentStart, SpaceColors.accentEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: SpaceColors.accentStart.withValues(alpha: 0.5),
            blurRadius: 22,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
