import 'package:flutter/material.dart';

import 'package:fibo_core/theme/space_tokens.dart';
import '../widgets/space_bottom_bar.dart';
import 'assistant_screen.dart';
import 'home_profile_home_screen.dart';

/// Native-style tab shell: one fixed bottom bar over an [IndexedStack] of the
/// four tab pages. Switching a tab swaps the content instantly (no slide) while
/// the bar stays put, and each tab keeps its scroll/state because all pages
/// stay mounted.
class MainTabShell extends StatefulWidget {
  const MainTabShell({super.key, this.initialTab = SpaceTab.spaces});

  final SpaceTab initialTab;

  @override
  State<MainTabShell> createState() => _MainTabShellState();
}

class _MainTabShellState extends State<MainTabShell> {
  // Two primary tabs: Home (Spaces + Scenes are merged into it) and Assistant.
  // Both pages suppress their own bottom bar — the shell owns the single bar.
  late SpaceTab _current =
      widget.initialTab == SpaceTab.assistant ? SpaceTab.assistant : SpaceTab.home;

  static const List<Widget> _pages = [
    HomeProfileHomeScreen(showBottomBar: false),
    AssistantScreen(showBottomBar: false),
  ];

  @override
  Widget build(BuildContext context) {
    final index = _current == SpaceTab.assistant ? 1 : 0;
    return Scaffold(
      backgroundColor: SpaceColors.bgBase,
      body: IndexedStack(index: index, children: _pages),
      bottomNavigationBar: SpaceBottomBar(
        active: _current == SpaceTab.assistant
            ? SpaceTab.assistant
            : SpaceTab.home,
        onSelect: (tab) {
          if (tab != _current) setState(() => _current = tab);
        },
      ),
    );
  }
}
