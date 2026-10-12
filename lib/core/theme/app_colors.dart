import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand: rose for the brand and accents, wine for actions.
  static const rose = Color(0xFFC2748C);
  static const wine = Color(0xFF7B344A);

  /// Accent: links, icons, selected states, the heart. (Name kept from the
  /// first palette.)
  static const hotPink = rose;

  /// Filled buttons and strong emphasis — white text reads clearly on it.
  static const berry = wine;

  static const blush = Color(0xFFF5E1E7); // soft secondary
  static const cream = Color(0xFFFAF8F9); // light background
  static const plum = Color(0xFF34212A); // primary text / dark surfaces
  static const lilac = Color(0xFF9D7890); // status accents

  static const hotPinkDark = Color(0xFFA85A73);
  static const hotPinkSoft = Color(0xFFE2A9BA); // emphasis on dark backgrounds
  static const plumSoft = Color(0xFF715A65); // muted body text on light
  static const plumFaint = Color(0xFFA9939D); // hint / disabled text
  static const mint = Color(0xFF5FA879); // success / available
  static const sun = Color(0xFFD9A441); // ratings

  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceMutedLight = Color(0xFFF3EEF1);
  static const borderLight = Color(0xFFECE2E7);

  static const backgroundDark = Color(0xFF1E1318);
  static const surfaceDark = Color(0xFF2B1D24);
  static const surfaceMutedDark = Color(0xFF382833);
  static const borderDark = Color(0xFF4B3642);
  static const textOnDark = Color(0xFFFBF4F6);
  static const textMutedDark = Color(0xFFD3BDC6);

  static const error = Color(0xFFE5484D);
  static const success = mint;
  static const warning = sun;
}
