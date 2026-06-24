import 'package:flutter/material.dart';

abstract final class AppColors {

  static const hotPink = Color(0xFFC85A7A); // primary
  static const berry = Color(0xFF7F2946); // strong emphasis
  static const blush = Color(0xFFF6DDE5); // soft secondary
  static const cream = Color(0xFFFCF7F8); // light background
  static const plum = Color(0xFF34212A); // primary text / dark surfaces
  static const lilac = Color(0xFF9D7890); // accent

  static const hotPinkDark = Color(0xFFA94363);
  static const hotPinkSoft = Color(0xFFE7A5B8);
  static const plumSoft = Color(0xFF715A65); // muted body text on light
  static const plumFaint = Color(0xFFA9939D); // hint / disabled text
  static const mint = Color(0xFF5FA879); // success / available
  static const sun = Color(0xFFD9A441); // ratings

  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceMutedLight = Color(0xFFF8EEF2);
  static const borderLight = Color(0xFFEAD2DC);

  static const backgroundDark = Color(0xFF1E1318);
  static const surfaceDark = Color(0xFF2B1D24);
  static const surfaceMutedDark = Color(0xFF382833);
  static const borderDark = Color(0xFF4B3642);
  static const textOnDark = Color(0xFFFBF4F6);
  static const textMutedDark = Color(0xFFD3BDC6);

  static const error = Color(0xFFE5484D);
  static const success = mint;
  static const warning = sun;

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [hotPink, lilac],
  );

  static const blushGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFBFC), cream],
  );

  static const splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC85A7A), Color(0xFFD7839B), Color(0xFF9D7890)],
  );
}
