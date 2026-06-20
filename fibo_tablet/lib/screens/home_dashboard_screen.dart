import 'package:flutter/material.dart';

import '../widgets/section_placeholder.dart';

/// Phase 2 fills this with the live rooms + device grid from home_graph /
/// device_api. Placeholder for now.
class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionPlaceholder(
      title: 'Home',
      icon: Icons.dashboard_outlined,
      note: 'Live rooms & devices arrive in the next phase.',
    );
  }
}
