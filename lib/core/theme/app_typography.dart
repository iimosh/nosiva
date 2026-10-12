import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTypography {
  /// Headings: Manrope — geometric and bold, with full Cyrillic support for
  /// the Macedonian translation. Body: Inter, built for small screen text.
  /// The "nosiva" logo is artwork, not a font: see NosivaWordmark.
  static TextTheme textTheme(Color onSurface, Color muted) {
    final display = GoogleFonts.manrope;
    final body = GoogleFonts.inter;

    return TextTheme(
      displayLarge: display(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        height: 1.08,
        letterSpacing: -1.2,
        color: onSurface,
      ),
      displayMedium: display(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -0.9,
        color: onSurface,
      ),
      headlineMedium: display(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: onSurface,
      ),
      headlineSmall: display(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: onSurface,
      ),
      titleLarge: display(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        color: onSurface,
      ),
      titleMedium: body(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: onSurface,
      ),
      bodyLarge: body(fontSize: 16, fontWeight: FontWeight.w400, height: 1.45, color: onSurface),
      bodyMedium: body(fontSize: 14, fontWeight: FontWeight.w400, height: 1.4, color: onSurface),
      bodySmall: body(fontSize: 12, fontWeight: FontWeight.w400, color: muted),
      labelLarge: body(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: onSurface,
      ),
      labelMedium: body(fontSize: 13, fontWeight: FontWeight.w500, color: muted),
    );
  }
}
