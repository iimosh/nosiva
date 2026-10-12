import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Brand colours that need a different shade in dark mode. Use these instead
/// of fixed [AppColors] for text and surfaces, so nothing turns unreadable
/// when the theme changes:
///
///   context.palette.emphasis     prices and highlighted text
///   context.palette.placeholder  behind photos still loading, empty avatars
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.emphasis,
    required this.placeholder,
    required this.onPlaceholder,
  });

  final Color emphasis;
  final Color placeholder;
  final Color onPlaceholder;

  static const light = AppPalette(
    emphasis: AppColors.berry,
    placeholder: AppColors.blush,
    onPlaceholder: AppColors.hotPink,
  );

  static const dark = AppPalette(
    emphasis: AppColors.hotPinkSoft,
    placeholder: AppColors.surfaceMutedDark,
    onPlaceholder: AppColors.textMutedDark,
  );

  @override
  AppPalette copyWith({Color? emphasis, Color? placeholder, Color? onPlaceholder}) =>
      AppPalette(
        emphasis: emphasis ?? this.emphasis,
        placeholder: placeholder ?? this.placeholder,
        onPlaceholder: onPlaceholder ?? this.onPlaceholder,
      );

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      emphasis: Color.lerp(emphasis, other.emphasis, t)!,
      placeholder: Color.lerp(placeholder, other.placeholder, t)!,
      onPlaceholder: Color.lerp(onPlaceholder, other.onPlaceholder, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
