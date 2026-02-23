import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../widgets/header_action_button.dart';

class ScenesDetailScreen extends StatelessWidget {
  const ScenesDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onBack: () => Navigator.of(context).pop(),
              onSave: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  children: [
                    _InputSection(
                      label: 'Scene Name',
                      value: 'Temperature Control',
                    ),
                    const SizedBox(height: 16),
                    const _IconSection(),
                    const SizedBox(height: 20),
                    _FlowSection(
                      label: 'When (Triggers)',
                      onAdd: () => Navigator.of(
                        context,
                      ).pushNamed('/scenes/add-trigger'),
                      children: const [
                        _FlowItem(
                          icon: Icons.thermostat,
                          title: 'Temperature Sensor',
                          subtitle: 'Less than 24°C',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _FlowSection(
                      label: 'Then (Actions)',
                      onAdd: () =>
                          Navigator.of(context).pushNamed('/scenes/add-action'),
                      children: const [
                        _FlowItem(
                          icon: Icons.ac_unit,
                          title: 'Air Conditioner',
                          subtitle: 'Turn On → Heat Mode 26°C',
                        ),
                        SizedBox(height: 10),
                        _FlowItem(
                          icon: Icons.notifications_active,
                          title: 'Notification',
                          subtitle: 'Send push notification',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.destructive,
                          side: const BorderSide(
                            color: AppColors.destructive,
                            width: 1,
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Delete Scene'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.onSave});

  final VoidCallback onBack;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          HeaderActionButton(icon: Icons.arrow_back, onTap: onBack),
          Text(
            'Edit Scene',
            style: AppTextStyles.body16.copyWith(fontWeight: FontWeight.w600),
          ),
          Row(
            children: [
              TextButton(
                onPressed: onSave,
                child: Text('Save', style: AppTextStyles.link14),
              ),
              const HeaderActionButton(icon: Icons.notifications),
            ],
          ),
        ],
      ),
    );
  }
}

class _InputSection extends StatelessWidget {
  const _InputSection({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.body14),
          const SizedBox(height: 8),
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(value, style: AppTextStyles.body14),
          ),
        ],
      ),
    );
  }
}

class _IconSection extends StatelessWidget {
  const _IconSection();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Scene Icon', style: AppTextStyles.body14),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _IconOption(icon: Icons.bolt, selected: true),
              _IconOption(icon: Icons.nightlight_round),
              _IconOption(icon: Icons.lock_outline),
              _IconOption(icon: Icons.home_outlined),
              _IconOption(icon: Icons.schedule),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconOption extends StatelessWidget {
  const _IconOption({required this.icon, this.selected = false});

  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 22,
        color: selected ? AppColors.primaryForeground : AppColors.foreground,
      ),
    );
  }
}

class _FlowSection extends StatelessWidget {
  const _FlowSection({
    required this.label,
    required this.onAdd,
    required this.children,
  });

  final String label;
  final VoidCallback onAdd;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTextStyles.body14),
              TextButton(
                onPressed: onAdd,
                child: Text(
                  'Add',
                  style: AppTextStyles.link14.copyWith(fontSize: 13),
                ),
              ),
            ],
          ),
          ...children,
        ],
      ),
    );
  }
}

class _FlowItem extends StatelessWidget {
  const _FlowItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.body14),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.body13Muted),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            size: 22,
            color: AppColors.mutedForeground,
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppDecorations.softCardShadow,
      ),
      child: child,
    );
  }
}
