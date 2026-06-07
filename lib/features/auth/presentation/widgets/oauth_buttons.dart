import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_spacing.dart';

/// Google / Apple sign-in row. Wire these up after enabling the providers in
/// Supabase Auth and configuring deep-link redirects.
class OAuthButtons extends StatelessWidget {
  const OAuthButtons({super.key, required this.onProvider});

  final void Function(OAuthProvider provider) onProvider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text('or continue with',
                  style: theme.textTheme.bodySmall),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _OAuthTile(
                label: 'Google',
                icon: Icons.g_mobiledata_rounded,
                onTap: () => onProvider(OAuthProvider.google),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _OAuthTile(
                label: 'Apple',
                icon: Icons.apple_rounded,
                onTap: () => onProvider(OAuthProvider.apple),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OAuthTile extends StatelessWidget {
  const _OAuthTile({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 24),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.colorScheme.onSurface,
        side: BorderSide(color: theme.colorScheme.outline),
        minimumSize: const Size.fromHeight(52),
      ),
    );
  }
}
