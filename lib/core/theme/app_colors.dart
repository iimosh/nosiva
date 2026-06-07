import 'package:flutter/material.dart';

/// Nosiva brand palette. Feminine, playful, "main character" energy. 💖
abstract final class AppColors {
  // --- Brand core ---
  static const hotPink = Color(0xFFFF4D8D); // primary
  static const blush = Color(0xFFFFD6E5); // soft secondary
  static const cream = Color(0xFFFFF7FA); // light background
  static const plum = Color(0xFF3D1F2E); // primary text / dark surfaces
  static const lilac = Color(0xFFC8A2E0); // accent

  // --- Derived / supporting ---
  static const hotPinkDark = Color(0xFFE63E7B);
  static const hotPinkSoft = Color(0xFFFF85B0);
  static const plumSoft = Color(0xFF6B4A5A); // muted body text on light
  static const plumFaint = Color(0xFFB39AA6); // hint / disabled text
  static const mint = Color(0xFF7BD8B0); // success / "available"
  static const sun = Color(0xFFFFC857); // stars / sparkles / ratings

  // --- Neutrals (light) ---
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceMutedLight = Color(0xFFFFF0F5);
  static const borderLight = Color(0xFFF3D9E4);

  // --- Neutrals (dark) — deep plum/black with pink accents ---
  static const backgroundDark = Color(0xFF1A0E15);
  static const surfaceDark = Color(0xFF2A1822);
  static const surfaceMutedDark = Color(0xFF35202D);
  static const borderDark = Color(0xFF4A2E3D);
  static const textOnDark = Color(0xFFFCEBF2);
  static const textMutedDark = Color(0xFFC9A7B7);

  // --- Semantic ---
  static const error = Color(0xFFE5484D);
  static const success = mint;
  static const warning = sun;

  // --- Gradients ---
  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [hotPink, lilac],
  );

  static const blushGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [blush, cream],
  );

  static const splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [hotPink, Color(0xFFFF7AB0), lilac],
  );
}
