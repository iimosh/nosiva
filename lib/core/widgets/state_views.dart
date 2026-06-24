import 'package:flutter/material.dart';

import '../l10n/l10n_extensions.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'nosiva_button.dart';

/// Standard empty state used across listing, order, and message screens.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.title,
    this.message,
    this.emoji = '',
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final String emoji;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 96,
              width: 96,
              decoration: const BoxDecoration(
                gradient: AppColors.blushGradient,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: emoji.isEmpty
                  ? Icon(
                      icon ?? Icons.inventory_2_outlined,
                      color: AppColors.hotPink,
                      size: 38,
                    )
                  : Text(emoji, style: const TextStyle(fontSize: 42)),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                message!,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              NosivaButton(
                label: actionLabel!,
                onPressed: onAction,
                expand: false,
                variant: NosivaButtonVariant.gradient,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Standard error state with retry.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 42,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(context.l10n.oopsGlitched,
                style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              NosivaButton(
                label: context.l10n.tryAgain,
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
                expand: false,
                variant: NosivaButtonVariant.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
