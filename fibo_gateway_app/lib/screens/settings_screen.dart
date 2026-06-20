import 'package:flutter/material.dart';

import 'package:fibo_core/services/app_prefs.dart';
import 'package:fibo_core/theme/space_tokens.dart';
import 'space_models.dart';

/// App settings: notification + temperature-unit preferences (persisted on the
/// user), plus About and Account-security entry points.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AppPrefs _prefs = AppPrefs.instance;

  @override
  void initState() {
    super.initState();
    if (!_prefs.isLoaded) _prefs.loadFromUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpaceColors.bgBase,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _prefs,
          builder: (_, _) {
            return Column(
              children: [
                _SimpleHeader(
                  title: 'Setting',
                  onBack: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                    children: [
                      _SectionLabel('Preferences'),
                      _Card(
                        child: Column(
                          children: [
                            _SwitchRow(
                              icon: Icons.notifications_outlined,
                              label: 'Notifications',
                              value: _prefs.notificationsEnabled,
                              onChanged: _prefs.setNotificationsEnabled,
                            ),
                            const _Divider(),
                            _TempUnitRow(
                              unit: _prefs.temperatureUnit,
                              onChanged: (u) async {
                                await _prefs.setTemperatureUnit(u);
                                // Re-derive sensor labels in the live store.
                                SpaceMockStore.instance.rebuildForPrefs();
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _SectionLabel('Account'),
                      _Card(
                        child: _NavRow(
                          icon: Icons.lock_outline,
                          label: 'Account Security',
                          onTap: () => Navigator.of(context)
                              .pushNamed('/account/password'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _SectionLabel('About'),
                      _Card(
                        child: Column(
                          children: [
                            _NavRow(
                              icon: Icons.gavel_outlined,
                              label: 'Terms of use',
                              onTap: () =>
                                  Navigator.of(context).pushNamed('/legal/terms'),
                            ),
                            const _Divider(),
                            _NavRow(
                              icon: Icons.send_outlined,
                              label: 'Contact',
                              onTap: () => Navigator.of(context)
                                  .pushNamed('/support/contact'),
                            ),
                            const _Divider(),
                            const _InfoRow(
                              icon: Icons.info_outline,
                              label: 'Version',
                              value: '1.0.0',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 10),
      child: Text(
        text,
        style: SpaceTextStyles.pillMeta.copyWith(fontSize: 13),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: SpaceColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: SpaceColors.bgElevated);
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          Icon(icon, color: SpaceColors.textPrimary, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: SpaceTextStyles.pillTitle.copyWith(fontSize: 16),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: SpaceColors.accentStart,
            activeTrackColor: const Color(0x887773FA),
            inactiveThumbColor: SpaceColors.textPrimary,
            inactiveTrackColor: SpaceColors.bgElevated,
          ),
        ],
      ),
    );
  }
}

class _TempUnitRow extends StatelessWidget {
  const _TempUnitRow({required this.unit, required this.onChanged});

  final String unit;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          const Icon(
            Icons.thermostat_outlined,
            color: SpaceColors.textPrimary,
            size: 22,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Temperature',
              style: SpaceTextStyles.pillTitle.copyWith(fontSize: 16),
            ),
          ),
          _UnitToggle(unit: unit, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _UnitToggle extends StatelessWidget {
  const _UnitToggle({required this.unit, required this.onChanged});

  final String unit;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SpaceColors.bgBase,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          for (final u in const ['C', 'F'])
            GestureDetector(
              onTap: () => onChanged(u),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: unit == u
                      ? SpaceColors.accentStart
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '°$u',
                  style: SpaceTextStyles.pillTitle.copyWith(fontSize: 15),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            Icon(icon, color: SpaceColors.textPrimary, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: SpaceTextStyles.pillTitle.copyWith(fontSize: 16),
              ),
            ),
            const Icon(Icons.chevron_right, color: SpaceColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          Icon(icon, color: SpaceColors.textPrimary, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: SpaceTextStyles.pillTitle.copyWith(fontSize: 16),
            ),
          ),
          Text(
            value,
            style: SpaceTextStyles.pillMeta.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _SimpleHeader extends StatelessWidget {
  const _SimpleHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(12),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.arrow_back,
                color: SpaceColors.textPrimary,
                size: 22,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(title, style: SpaceTextStyles.navTitle),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}
