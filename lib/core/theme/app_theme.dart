import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Builds the Nosiva [ThemeData] for light and dark modes.
abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final background = isDark ? AppColors.backgroundDark : AppColors.cream;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final surfaceMuted =
        isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMutedLight;
    final onSurface = isDark ? AppColors.textOnDark : AppColors.plum;
    final muted = isDark ? AppColors.textMutedDark : AppColors.plumSoft;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.hotPink,
      onPrimary: Colors.white,
      primaryContainer: AppColors.blush,
      onPrimaryContainer: AppColors.plum,
      secondary: AppColors.lilac,
      onSecondary: AppColors.plum,
      secondaryContainer: AppColors.lilac.withValues(alpha: 0.25),
      onSecondaryContainer: onSurface,
      tertiary: AppColors.sun,
      onTertiary: AppColors.plum,
      error: AppColors.error,
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: surfaceMuted,
      onSurfaceVariant: muted,
      outline: border,
      outlineVariant: border,
    );

    final textTheme = AppTypography.textTheme(onSurface, muted);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall,
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.hotPink,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.hotPink.withValues(alpha: 0.4),
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          textStyle: textTheme.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.button),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.hotPink,
          minimumSize: const Size.fromHeight(54),
          side: const BorderSide(color: AppColors.hotPink, width: 1.5),
          textStyle: textTheme.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.button),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.hotPink,
          textStyle: textTheme.labelLarge,
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.plumFaint),
        labelStyle: textTheme.labelMedium,
        border: const OutlineInputBorder(
          borderRadius: AppRadii.field,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.field,
          borderSide: BorderSide(color: border, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadii.field,
          borderSide: BorderSide(color: AppColors.hotPink, width: 1.8),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadii.field,
          borderSide: BorderSide(color: AppColors.error, width: 1.4),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadii.field,
          borderSide: BorderSide(color: AppColors.error, width: 1.8),
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.card),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: surfaceMuted,
        selectedColor: AppColors.hotPink,
        secondarySelectedColor: AppColors.hotPink,
        labelStyle: textTheme.labelMedium!,
        secondaryLabelStyle:
            textTheme.labelMedium!.copyWith(color: Colors.white),
        side: BorderSide(color: border),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.chip),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      ),

      // Bottom nav
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: AppColors.hotPink,
        unselectedItemColor: muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showUnselectedLabels: true,
        selectedLabelStyle: textTheme.labelMedium,
        unselectedLabelStyle: textTheme.labelMedium,
      ),

      // Sheets & dialogs
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.sheet),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.card),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.plum,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.field),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
    );
  }
}
