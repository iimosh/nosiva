import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Playful, on-brand snackbars. "Snatched! Added to favorites 💖"
extension NosivaSnackbars on BuildContext {
  void showSnack(String message, {Color? color}) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
        ),
      );
  }

  void showSuccess(String message) => showSnack(message, color: AppColors.plum);
  void showError(String message) => showSnack(message, color: AppColors.error);
}
