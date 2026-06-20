import 'package:flutter/material.dart';

import '../widgets/section_placeholder.dart';

/// Phase 4 fills this with the scene list + one-tap trigger via scenes_service.
class ScenesScreen extends StatelessWidget {
  const ScenesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionPlaceholder(
      title: 'Scenes',
      icon: Icons.auto_awesome_outlined,
      note: 'Tap-to-run scenes arrive in a later phase.',
    );
  }
}
