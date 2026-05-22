import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Accent (primary)
  static const Color accent = Color(0xFF7C5CFF);
  static const Color accentDim = Color(0xFF5C3FCC);
  static const Color accentSoft = Color(0x267C5CFF);

  // Semantic
  static const Color danger = Color(0xFFFF5A6E);
  static const Color dangerSoft = Color(0x26FF5A6E);
  static const Color success = Color(0xFF29D391);
  static const Color successSoft = Color(0x2629D391);
  static const Color warning = Color(0xFFFFB454);
  static const Color warningSoft = Color(0x26FFB454);

  // Dark theme
  static const Color darkBg = Color(0xFF0B0B10);
  static const Color darkBgSecondary = Color(0xFF101017);
  static const Color darkSurface = Color(0xFF15151D);
  static const Color darkSurface2 = Color(0xFF1C1C26);
  static const Color darkSurface3 = Color(0xFF232330);
  static const Color darkText = Color(0xFFF2F2F5);
  static const Color darkTextDim = Color(0xFF9292A0);
  static const Color darkTextFaint = Color(0xFF5E5E6B);
  static const Color darkBorder = Color(0x12FFFFFF);
  static const Color darkBorderStrong = Color(0x21FFFFFF);

  // Light theme
  static const Color lightBg = Color(0xFFF6F6F8);
  static const Color lightBgSecondary = Color(0xFFEEEEF2);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurface2 = Color(0xFFF0F0F5);
  static const Color lightSurface3 = Color(0xFFE8E8EF);
  static const Color lightText = Color(0xFF0B0B10);
  static const Color lightTextDim = Color(0xFF5E5E6B);
  static const Color lightTextFaint = Color(0xFF9292A0);
  static const Color lightBorder = Color(0x14000000);
  static const Color lightBorderStrong = Color(0x21000000);

  // Avatar gradient pairs
  static const List<List<Color>> avatarGradients = [
    [Color(0xFF7C5CFF), Color(0xFFB69EFF)],
    [Color(0xFF29D391), Color(0xFF00E5A0)],
    [Color(0xFFFF5A6E), Color(0xFFFF8FA0)],
    [Color(0xFFFFB454), Color(0xFFFFD89E)],
    [Color(0xFF5CC8FF), Color(0xFF99DEFF)],
    [Color(0xFFFF6B9D), Color(0xFFFFAACC)],
    [Color(0xFF6BFFD8), Color(0xFF99FFE8)],
    [Color(0xFFFFA654), Color(0xFFFFCC99)],
  ];
}
