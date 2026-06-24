import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shared snackbar helpers for success, error, and neutral feedback.
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
