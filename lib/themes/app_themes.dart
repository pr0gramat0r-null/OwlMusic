import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

class AppThemes {
  static ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: DarkPalette.primary,
        onPrimary: DarkPalette.onPrimary,
        primaryContainer: DarkPalette.primaryContainer,
        onPrimaryContainer: DarkPalette.onPrimaryContainer,
        secondary: DarkPalette.secondary,
        onSecondary: DarkPalette.onSecondary,
        secondaryContainer: DarkPalette.secondaryContainer,
        onSecondaryContainer: DarkPalette.onSecondaryContainer,
        surface: DarkPalette.surface,
        onSurface: DarkPalette.onSurface,
        surfaceContainerHighest: DarkPalette.elevated,
        error: DarkPalette.error,
        onError: DarkPalette.onError,
        outline: DarkPalette.outline,
        outlineVariant: DarkPalette.outlineVariant,
      ),
      scaffoldBackgroundColor: DarkPalette.background,
      appBarTheme: AppBarTheme(
        backgroundColor: DarkPalette.surface,
        foregroundColor: DarkPalette.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: const TextStyle(
          color: AppColors.textLight,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: DarkPalette.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: DarkPalette.outlineVariant, width: 0.5),
        ),
      ),
      listTileTheme: ListTileThemeData(
        textColor: DarkPalette.onSurface,
        iconColor: DarkPalette.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: DarkPalette.surface,
        indicatorColor: DarkPalette.primaryContainer,
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(color: DarkPalette.onSurfaceVariant),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: DarkPalette.primary,
        foregroundColor: DarkPalette.onPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DarkPalette.elevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: DarkPalette.primary, width: 1.5),
        ),
        hintStyle: TextStyle(color: DarkPalette.onSurfaceVariant),
        prefixIconColor: DarkPalette.primary,
        suffixIconColor: DarkPalette.onSurfaceVariant,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: DarkPalette.primary,
        inactiveTrackColor: DarkPalette.outlineVariant,
        thumbColor: DarkPalette.primary,
        overlayColor: DarkPalette.primary.withValues(alpha: 0.12),
      ),
      iconTheme: IconThemeData(color: DarkPalette.onSurface),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: DarkPalette.elevated,
        contentTextStyle: TextStyle(color: DarkPalette.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: DarkPalette.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: TextStyle(
          color: DarkPalette.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: DarkPalette.card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: DarkPalette.primary,
        linearTrackColor: DarkPalette.outlineVariant,
      ),
      dividerTheme: DividerThemeData(
        color: DarkPalette.outlineVariant,
        thickness: 0.5,
      ),
    );
  }

  static ThemeData lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: LightPalette.primary,
        onPrimary: LightPalette.onPrimary,
        primaryContainer: LightPalette.primaryContainer,
        onPrimaryContainer: LightPalette.onPrimaryContainer,
        secondary: LightPalette.secondary,
        onSecondary: LightPalette.onSecondary,
        secondaryContainer: LightPalette.secondaryContainer,
        onSecondaryContainer: LightPalette.onSecondaryContainer,
        surface: LightPalette.surface,
        onSurface: LightPalette.onSurface,
        surfaceContainerHighest: LightPalette.elevated,
        error: LightPalette.error,
        onError: LightPalette.onError,
        outline: LightPalette.outline,
        outlineVariant: LightPalette.outlineVariant,
      ),
      scaffoldBackgroundColor: LightPalette.background,
      appBarTheme: AppBarTheme(
        backgroundColor: LightPalette.surface,
        foregroundColor: LightPalette.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: AppColors.textDark,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: LightPalette.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: LightPalette.outlineVariant, width: 0.5),
        ),
      ),
      listTileTheme: ListTileThemeData(
        textColor: LightPalette.onSurface,
        iconColor: LightPalette.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: LightPalette.surface,
        indicatorColor: LightPalette.primaryContainer,
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(color: LightPalette.onSurfaceVariant),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: LightPalette.primary,
        foregroundColor: LightPalette.onPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LightPalette.elevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: LightPalette.primary, width: 1.5),
        ),
        hintStyle: TextStyle(color: LightPalette.onSurfaceVariant),
        prefixIconColor: LightPalette.primary,
        suffixIconColor: LightPalette.onSurfaceVariant,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: LightPalette.primary,
        inactiveTrackColor: LightPalette.outlineVariant,
        thumbColor: LightPalette.primary,
        overlayColor: LightPalette.primary.withValues(alpha: 0.12),
      ),
      iconTheme: IconThemeData(color: LightPalette.onSurface),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: LightPalette.elevated,
        contentTextStyle: TextStyle(color: LightPalette.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: LightPalette.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: TextStyle(
          color: LightPalette.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: LightPalette.card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: LightPalette.primary,
        linearTrackColor: LightPalette.outlineVariant,
      ),
      dividerTheme: DividerThemeData(
        color: LightPalette.outlineVariant,
        thickness: 0.5,
      ),
    );
  }
}
