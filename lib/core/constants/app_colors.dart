// SafeGuardHer - App Color Scheme
// Premium dark maroon + pink accent palette.

import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors — Updated per design spec
  static const Color primary = Color(0xFF8B1A4A);       // Dark Maroon
  static const Color secondary = Color(0xFF6D1038);      // Deeper Maroon
  static const Color accent = Color(0xFFE91E8C);         // Vibrant Pink
  static const Color background = Color(0xFFFFF5F7);     // Warm Off-White
  static const Color textDark = Color(0xFF1a1a1a);
  static const Color textLight = Color(0xFF757575);
  static const Color success = Color(0xFF2e7d32);
  static const Color danger = Color(0xFFc62828);
  static const Color warning = Color(0xFFF57C00);
  static const Color surface = Color(0xFFFFF0F3);         // Soft pink surface
  static const Color cardBg = Color(0xFFFFFFFF);

  // Matte gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF8B1A4A), Color(0xFFE91E8C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Subtle shimmer gradient for loading skeletons
  static const Color shimmerBase = Color(0xFFFFE8EE);
  static const Color shimmerHighlight = Color(0xFFFFF5F7);
}
