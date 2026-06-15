import 'package:flutter/material.dart';

import '../screens/assistant_screen.dart';
import '../screens/home_profile_home_screen.dart';
import '../screens/scenes_list_screen.dart';
import '../screens/spaces_overview_screen.dart';
import '../theme/space_tokens.dart';

enum SpaceTab { home, scenes, spaces, assistant }

/// Builds the destination screen for a tab. Kept here so tab switches can use a
/// custom (non-sliding) transition instead of the default named-route push.
Widget _pageForTab(SpaceTab tab) {
  switch (tab) {
    case SpaceTab.home:
      return const HomeProfileHomeScreen();
    case SpaceTab.scenes:
      return const ScenesListScreen(showSpacesBottomTabs: true);
    case SpaceTab.spaces:
      return const SpacesOverviewScreen();
    case SpaceTab.assistant:
      return const AssistantScreen();
  }
}

/// A seamless tab transition: the new page fades in while scaling up slightly
/// (small → big) — no horizontal slide. The route name is preserved so other
/// screens' `popUntil(name == '/spaces')` logic keeps working.
Route<void> _tabRoute(Widget page, String name) {
  return PageRouteBuilder<void>(
    settings: RouteSettings(name: name),
    transitionDuration: const Duration(milliseconds: 240),
    reverseTransitionDuration: const Duration(milliseconds: 160),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class SpaceBottomBar extends StatelessWidget {
  const SpaceBottomBar({super.key, required this.active, this.onSelect});

  final SpaceTab active;

  /// When provided (tab-shell mode), tapping a tab calls this instead of
  /// navigating — so the bar stays fixed and only the content switches.
  final ValueChanged<SpaceTab>? onSelect;

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

  // The app has two primary tabs; Spaces and Scenes are merged into Home.
  static const _visibleTabs = [SpaceTab.home, SpaceTab.assistant];

  @override
  Widget build(BuildContext context) {
    const tabs = _visibleTabs;
    final children = <Widget>[];
    for (var i = 0; i < tabs.length; i++) {
      final tab = tabs[i];
      final selected = tab == active;
      children.add(
        selected
            ? Expanded(child: _SelectedPill(tab: tab))
            : _IconOnlyButton(
                tab: tab,
                onTap: () {
                  if (onSelect != null) {
                    onSelect!(tab);
                  } else {
                    Navigator.of(context).pushReplacement(
                      _tabRoute(_pageForTab(tab), _route[tab]!),
                    );
                  }
                },
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
    // Pops in (small → big) each time a new tab becomes selected. A ValueKey on
    // the tab forces a fresh animation when switching directly between tabs.
    return TweenAnimationBuilder<double>(
      key: ValueKey(tab),
      tween: Tween<double>(begin: 0.6, end: 1.0),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) => Transform.scale(
        scale: scale,
        child: child,
      ),
      child: Container(
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
