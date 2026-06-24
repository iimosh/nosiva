import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTypography {
  static TextTheme textTheme(Color onSurface, Color muted) {
    final display = GoogleFonts.notoSerif;
    final body = GoogleFonts.notoSans;

    return TextTheme(
      displayLarge: display(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        height: 1.08,
        letterSpacing: 0,
        color: onSurface,
      ),
      displayMedium: display(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: 0,
        color: onSurface,
      ),
      headlineMedium: display(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: onSurface,
      ),
      headlineSmall: display(
        fontSize: 21,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
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
        letterSpacing: 0,
        color: onSurface,
      ),
      labelMedium: body(fontSize: 13, fontWeight: FontWeight.w600, color: muted),
    );
  }
}
