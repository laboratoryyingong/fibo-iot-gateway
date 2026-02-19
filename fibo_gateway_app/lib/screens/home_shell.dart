import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'dashboard_home_screen.dart';
import 'devices_list_screen.dart';
import 'network_status_screen.dart';
import 'scenes_list_screen.dart';
import 'settings_main_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final List<Widget> _pages = const [
    DashboardHomeScreen(),
    DevicesListScreen(),
    ScenesListScreen(),
    NetworkStatusScreen(),
    SettingsMainScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (value) => setState(() => _index = value),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.card,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.mutedForeground,
        selectedLabelStyle: AppTextStyles.body13Muted.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.body13Muted,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.devices_outlined),
            activeIcon: Icon(Icons.devices),
            label: 'Devices',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bolt_outlined),
            activeIcon: Icon(Icons.bolt),
            label: 'Scenes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lan_outlined),
            activeIcon: Icon(Icons.lan),
            label: 'Network',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
