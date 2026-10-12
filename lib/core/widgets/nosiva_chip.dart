import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A selectable pill chip — used for categories, sizes, sorting and filters.
class NosivaChip extends StatelessWidget {
  const NosivaChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = selected ? Colors.white : theme.colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadii.chip,
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.berry
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: AppRadii.chip,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
