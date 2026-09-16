import 'package:flutter/material.dart';

class AppColors {
  // Primary Blue Tones
  static const Color primaryDark = Color(0xFF061121);
  static const Color primaryNavy = Color(0xFF0A192F);
  static const Color primaryRoyal = Color(0xFF0D47A1);
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color primaryElectric = Color(0xFF0077B6);

  // Accent & Glow Colors
  static const Color accentCyan = Color(0xFF00B4D8);
  static const Color accentSky = Color(0xFF90E0EF);
  static const Color accentNeon = Color(0xFF48CAE4);
  static const Color accentLight = Color(0xFFCAF0F8);

  // Surface & Card Colors
  static const Color surfaceDark = Color(0xFF0F223D);
  static const Color cardGlass = Color(0x1AFFFFFF);
  static const Color cardGlassBorder = Color(0x3300B4D8);
  static const Color inputBackground = Color(0x1FFFFFFF);
  static const Color inputBorder = Color(0x3390E0EF);
  static const Color inputFocusedBorder = Color(0xFF00B4D8);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0C4DE);
  static const Color textMuted = Color(0xFF7E97B8);

  // Feedback Colors
  static const Color success = Color(0xFF00E676);
  static const Color error = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFD600);

  // Gradients
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      primaryDark,
      primaryNavy,
      surfaceDark,
      primaryRoyal,
    ],
    stops: [0.0, 0.3, 0.7, 1.0],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x2E00B4D8),
      Color(0x140D47A1),
    ],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      accentCyan,
      primaryElectric,
      primaryRoyal,
    ],
  );

  static const LinearGradient iconGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      accentSky,
      accentCyan,
      primaryElectric,
    ],
  );

  // Methodist Brand & Login Screen Theme Colors
  static const Color methodistRed = Color(0xFFE52020);
  static const Color methodistBlue = Color(0xFF0D47A1);
  static const Color userCardBackground = Color(0xF2FFFFFF); // ~0.95 white
  static const Color userCardBorder = Color(0x240D47A1);
  static const Color userTextPrimary = Color(0xFF0D47A1);
  static const Color userTextBody = Color(0xFF1E293B);
  static const Color userTextSecondary = Color(0xFF64748B);
  static const Color userTextMuted = Color(0xFF94A3B8);

  static const LinearGradient buttonRedGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFF3333),
      Color(0xFFE52020),
      Color(0xFFB71C1C),
    ],
  );
}
