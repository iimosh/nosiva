import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

enum NosivaButtonVariant { primary, secondary, ghost }

/// The Nosiva button: solid wine (primary), outlined (secondary) or text-only
/// (ghost), with an optional leading icon and a built-in loading state so
/// screens never roll their own spinner. Colours come from the theme.
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

    final button = switch (variant) {
      NosivaButtonVariant.primary =>
        ElevatedButton(onPressed: disabled ? null : onPressed, child: child),
      NosivaButtonVariant.secondary =>
        OutlinedButton(onPressed: disabled ? null : onPressed, child: child),
      NosivaButtonVariant.ghost =>
        TextButton(onPressed: disabled ? null : onPressed, child: child),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _content(BuildContext context) {
    if (loading) {
      return SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: variant == NosivaButtonVariant.primary
              ? Colors.white
              : Theme.of(context).colorScheme.primary,
        ),
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
