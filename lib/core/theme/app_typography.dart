import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTypography {
  static TextTheme textTheme(Color onSurface, Color muted) {
    final display = GoogleFonts.notoSerif;
    final body = GoogleFonts.notoSans;

    return TextTheme(
      displayLarge: display(
        fontSize: 44,
        fontWeight: FontWeight.w700,
        height: 1.05,
        letterSpacing: -0.5,
        color: onSurface,
      ),
      displayMedium: display(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        height: 1.1,
        color: onSurface,
      ),
      headlineMedium: display(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      headlineSmall: display(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleLarge: body(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      titleMedium: body(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      bodyLarge: body(fontSize: 16, fontWeight: FontWeight.w400, color: onSurface),
      bodyMedium: body(fontSize: 14, fontWeight: FontWeight.w400, color: onSurface),
      bodySmall: body(fontSize: 12, fontWeight: FontWeight.w400, color: muted),
      labelLarge: body(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: onSurface,
      ),
      labelMedium: body(fontSize: 13, fontWeight: FontWeight.w600, color: muted),
    );
  }
}
