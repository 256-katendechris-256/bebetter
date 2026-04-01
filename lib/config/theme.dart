import 'package:flutter/material.dart';

class AppColors {
  static const Color ink = Color(0xFF0D1B2A);
  static const Color emerald = Color(0xFF059669);
  static const Color emeraldSoft = Color(0xFFECFDF5);
  static const Color gold = Color(0xFFF59E0B);
  static const Color goldSoft = Color(0xFFFFFBEB);
  static const Color red = Color(0xFFEF4444);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF4F6F8);
  static const Color shadow = Color(0x0D000000);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  static const Color tealDark = Color(0xFF0B4D40);
  static const Color tealMid = Color(0xFF11755E);
  static const Color amber = Color(0xFFE8A838);
}

class AppDecorations {
  static BoxDecoration card({double radius = 16, Color? color}) => BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 3)),
          BoxShadow(
              color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      );
}
