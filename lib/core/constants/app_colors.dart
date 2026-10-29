import 'package:flutter/material.dart';

abstract class AppColors {
  AppColors._();

  static const Color darkBackground = Color(0xFF0A0E14);
  static const Color darkSurface = Color(0xFF10151C);
  static const Color darkCardSurface = Color(0xFF151C26);
  static const Color darkBorder = Color(0xFF222B38);
  static const Color darkDivider = Color(0xFF18202B);

  static const Color goldPrimary = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFE8C766);
  static const Color goldDark = Color(0xFF9E7B24);
  static const Color goldGlow = Color(0x33D4AF37);

  static const Color emeraldPrimary = Color(0xFF2EA043);
  static const Color emeraldLight = Color(0xFF3FB950);
  static const Color emeraldGlow = Color(0x332EA043);

  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextTertiary = Color(0xFF64748B);
  static const Color darkIconColor = Color(0xFF94A3B8);
  static const Color darkError = Color(0xFFF85149);
  static const Color darkWarning = Color(0xFFD4AF37);
  static const Color darkSuccess = Color(0xFF3FB950);

  static const Color downloadedColor = Color(0xFF3FB950);
  static const Color downloadingColor = Color(0xFF58A6FF);
  static const Color availableColor = Color(0xFFD4AF37);

  static const Color lightBackground = Color(0xFFF8F4EE);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCardSurface = Color(0xFFFDFAF5);
  static const Color lightBorder = Color(0xFFE8D5B7);
  static const Color lightDivider = Color(0xFFF0E8D8);

  static const Color lightTextPrimary = Color(0xFF1A1208);
  static const Color lightTextSecondary = Color(0xFF5C4A2A);
  static const Color lightTextTertiary = Color(0xFF9E8060);
  static const Color lightIconColor = Color(0xFF7A5C30);
  static const Color lightError = Color(0xFFB91C1C);
  static const Color lightWarning = Color(0xFF92400E);
  static const Color lightSuccess = Color(0xFF166534);

  static const List<Color> playerGradientDark = [
    Color(0xFF0A0E14),
    Color(0xFF141C26),
    Color(0xFF0A0E14),
  ];

  static const List<Color> playerGradientLight = [
    Color(0xFFF8F4EE),
    Color(0xFFFFF8F0),
    Color(0xFFF8F4EE),
  ];

  static const Color shimmerBaseDark = Color(0xFF151C26);
  static const Color shimmerHighlightDark = Color(0xFF222B38);
  static const Color shimmerBaseLight = Color(0xFFE8D5B7);
  static const Color shimmerHighlightLight = Color(0xFFF8F4EE);
}
