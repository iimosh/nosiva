import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum NosivaButtonVariant { primary, secondary, ghost, gradient }

/// The Nosiva button. Soft, rounded, with an optional leading icon and a
/// built-in loading state so screens never roll their own spinner.
class NosivaButton extends StatelessWidget {
  const NosivaButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = NosivaButtonVariant.primary,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final NosivaButtonVariant variant;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;
    final child = _content(context);

    Widget button;
    switch (variant) {
      case NosivaButtonVariant.primary:
        button = ElevatedButton(onPressed: disabled ? null : onPressed, child: child);
      case NosivaButtonVariant.secondary:
        button = OutlinedButton(onPressed: disabled ? null : onPressed, child: child);
      case NosivaButtonVariant.ghost:
        button = TextButton(onPressed: disabled ? null : onPressed, child: child);
      case NosivaButtonVariant.gradient:
        button = _GradientButton(onPressed: disabled ? null : onPressed, child: child);
    }

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _content(BuildContext context) {
    if (loading) {
      return const SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
      );
    }
    if (icon == null) return Text(label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: AppSpacing.xs),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.onPressed, required this.child});
  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: AppRadii.button,
          boxShadow: AppShadows.soft(AppColors.hotPink),
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
          ),
          child: child,
        ),
      ),
    );
  }
}
