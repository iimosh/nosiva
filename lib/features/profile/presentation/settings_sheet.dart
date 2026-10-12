import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/l10n/locale_controller.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_controller.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/delete_account_dialog.dart';

/// Language, appearance and account actions, in one place.
Future<void> showSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _SettingsSheet(screenContext: context),
  );
}

class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet({required this.screenContext});

  /// The profile screen's context: still valid after this sheet closes, so
  /// account actions can run from it.
  final BuildContext screenContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final locale = ref.watch(localeControllerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.settings, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.lg),
            _SectionLabel(l10n.language),
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: 'en', label: Text(l10n.english)),
                ButtonSegment(value: 'mk', label: Text(l10n.macedonian)),
              ],
              selected: {locale.languageCode},
              onSelectionChanged: (choice) => ref
                  .read(localeControllerProvider.notifier)
                  .setLocale(choice.first == 'mk'
                      ? LocaleController.macedonian
                      : LocaleController.english),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionLabel(l10n.appearance),
            SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: const Icon(Icons.brightness_auto_outlined),
                  label: Text(l10n.themeAuto),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: const Icon(Icons.light_mode_outlined),
                  label: Text(l10n.themeLight),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: const Icon(Icons.dark_mode_outlined),
                  label: Text(l10n.themeDark),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (choice) =>
                  ref.read(themeModeProvider.notifier).set(choice.first),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.themeAutoHint,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.logout_rounded),
              title: Text(l10n.signOut),
              onTap: () async {
                final router = GoRouter.of(screenContext);
                Navigator.of(context).pop();
                await ref.read(authControllerProvider.notifier).signOut();
                // Carry on browsing as a guest.
                router.go(AppRoutes.home);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_forever_outlined,
                  color: AppColors.error),
              title: Text(
                l10n.deleteAccount,
                style: const TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.of(context).pop();
                showDeleteAccountDialog(screenContext);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
