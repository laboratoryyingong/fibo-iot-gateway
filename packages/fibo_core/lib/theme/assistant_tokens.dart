import 'package:flutter/material.dart';

/// Design tokens for the Fibo AI chat agent ("Assistant") experience.
///
/// The Assistant uses the app's shared dark palette (see `space_tokens.dart`:
/// `#1B242D` base, `#7773FA→#5652E5` accent) so it sits cohesively alongside
/// Home / Spaces / Scenes. The layout still follows
/// `design/fibo_claude_agent.pen`; only the palette is unified.
class AgentColors {
  // Surfaces (dark, matching SpaceColors)
  static const bg = Color(0xFF1B242D); // base background
  static const surface = Color(0xFF25313D); // cards, input pill
  static const surfaceElevated = Color(0xFF314252); // chips, badges, tracks
  static const card = Color(0xFF25313D); // card background

  // Text
  static const ink = Color(0xFFFFFFFF); // primary
  static const inkMuted = Color(0xFF8B94A5); // secondary/placeholder
  static const stroke = Color(0xFF3A4A5A); // hairline borders

  // Accent (app purple)
  static const accent = Color(0xFF7773FA);
  static const accentEnd = Color(0xFF5652E5);

  // Fibo logo / avatar gradient — unified to the app accent.
  static const logoStrokeA = Color(0xFF7773FA);
  static const logoStrokeB = Color(0xFF5652E5);
}

class AgentTextStyles {
  static const greeting = TextStyle(
    fontFamily: 'Geist',
    fontSize: 36,
    fontWeight: FontWeight.w500,
    color: AgentColors.ink,
    height: 1.18,
    letterSpacing: -0.4,
  );

  static const cardTitle = TextStyle(
    fontFamily: 'Geist',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AgentColors.ink,
    height: 1.4,
  );

  static const placeholder = TextStyle(
    fontFamily: 'Geist',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AgentColors.inkMuted,
  );

  static const body = TextStyle(
    fontFamily: 'Geist',
    fontSize: 15.5,
    fontWeight: FontWeight.w400,
    color: AgentColors.ink,
    height: 1.45,
  );

  static const chip = TextStyle(
    fontFamily: 'Geist',
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );
}

/// The accent gradient used by the plus button and the icon badges.
const kAgentDarkGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AgentColors.accent, AgentColors.accentEnd],
);
