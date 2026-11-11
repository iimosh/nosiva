import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/theme/app_spacing.dart';

/// "Filled in from your last order · Clear" — shown under the address and
/// phone when they were pre-filled, so it's clear where they came from and
/// one tap empties them.
class SavedDetailsNote extends StatelessWidget {
  const SavedDetailsNote({super.key, required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(Icons.history_rounded, size: 16, color: muted),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            context.l10n.savedDeliveryDetails,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ),
        TextButton(
          onPressed: onClear,
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          ),
          child: Text(context.l10n.clear),
        ),
      ],
    );
  }
}
