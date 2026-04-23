import 'package:flutter/material.dart';

class AppColors {
  static const purple90 = Color(0xFF1A0A3E);
  static const purple80 = Color(0xFF2D1B69);
  static const purple70 = Color(0xFF4A2C8A);
  static const purple60 = Color(0xFF6C3CE1);
  static const purple50 = Color(0xFF8B5CF6);
  static const purple40 = Color(0xFFA78BFA);
  static const purple30 = Color(0xFFC4B5FD);
  static const purple20 = Color(0xFFDDD6FE);
  static const purple10 = Color(0xFFEDE9FE);

  static const gold100 = Color(0xFFFFD700);
  static const gold80 = Color(0xFFFFE54A);
  static const gold60 = Color(0xFFFFEC80);

  static const darkBg = Color(0xFF0D0D1A);
  static const darkSurface = Color(0xFF16162A);
  static const darkCard = Color(0xFF1E1E38);
  static const darkElevated = Color(0xFF28284A);

  static const lightBg = Color(0xFFF5F3FF);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFEDE9FE);
  static const lightElevated = Color(0xFFE0E0F0);

  static const errorRed = Color(0xFFEF4444);
  static const successGreen = Color(0xFF22C55E);
  static const warningAmber = Color(0xFFF59E0B);

  static const textDark = Color(0xFF1A1A2E);
  static const textLight = Color(0xFFE8E8F0);
  static const textMuted = Color(0xFF9CA3AF);
}

class DarkPalette {
  static const background = AppColors.darkBg;
  static const surface = AppColors.darkSurface;
  static const card = AppColors.darkCard;
  static const elevated = AppColors.darkElevated;
  static const primary = AppColors.purple50;
  static const primaryContainer = AppColors.purple70;
  static const onPrimary = Colors.white;
  static const onPrimaryContainer = AppColors.purple10;
  static const secondary = AppColors.purple40;
  static const secondaryContainer = AppColors.purple80;
  static const onSecondary = Colors.white;
  static const onSecondaryContainer = AppColors.purple20;
  static const onSurface = AppColors.textLight;
  static const onSurfaceVariant = AppColors.textMuted;
  static const outline = Color(0xFF3A3A5C);
  static const outlineVariant = Color(0xFF2A2A48);
  static const error = AppColors.errorRed;
  static const onError = Colors.white;
  static const accent = AppColors.gold100;
  static const shimmerBase = Color(0xFF2A2A48);
  static const shimmerHighlight = Color(0xFF3A3A5C);
  static const miniPlayerBg = Color(0xFF1A1A30);
}

class LightPalette {
  static const background = AppColors.lightBg;
  static const surface = AppColors.lightSurface;
  static const card = AppColors.lightCard;
  static const elevated = AppColors.lightElevated;
  static const primary = AppColors.purple60;
  static const primaryContainer = AppColors.purple20;
  static const onPrimary = Colors.white;
  static const onPrimaryContainer = AppColors.purple90;
  static const secondary = AppColors.purple50;
  static const secondaryContainer = AppColors.purple10;
  static const onSecondary = Colors.white;
  static const onSecondaryContainer = AppColors.purple80;
  static const onSurface = AppColors.textDark;
  static const onSurfaceVariant = Color(0xFF6B7280);
  static const outline = Color(0xFFD1D5DB);
  static const outlineVariant = Color(0xFFE5E7EB);
  static const error = AppColors.errorRed;
  static const onError = Colors.white;
  static const accent = AppColors.purple60;
  static const shimmerBase = Color(0xFFE0E0F0);
  static const shimmerHighlight = Color(0xFFFFFFFF);
  static const miniPlayerBg = Color(0xFFFFFFFF);
}
