import 'package:flutter/material.dart';

import '../widgets/section_placeholder.dart';

/// Phase 5 fills this with the big-screen assistant chat/voice panel reusing
/// claude_agent_client.
class AssistantPanelScreen extends StatelessWidget {
  const AssistantPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionPlaceholder(
      title: 'Assistant',
      icon: Icons.smart_toy_outlined,
      note: 'The AI control assistant arrives in a later phase.',
    );
  }
}
