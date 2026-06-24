import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/l10n/locale_controller.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/nosiva_button.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.blushGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: PopupMenuButton<String>(
                    tooltip: context.l10n.language,
                    icon: const Icon(Icons.language_rounded),
                    onSelected: (value) {
                      final locale = value == 'mk'
                          ? LocaleController.macedonian
                          : LocaleController.english;
                      ref
                          .read(localeControllerProvider.notifier)
                          .setLocale(locale);
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'en',
                        child: Text(context.l10n.english),
                      ),
                      PopupMenuItem(
                        value: 'mk',
                        child: Text(context.l10n.macedonian),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  height: 72,
                  width: 72,
                  decoration: BoxDecoration(
                    color: AppColors.hotPink.withValues(alpha: 0.12),
                    borderRadius: AppRadii.card,
                  ),
                  child: const Icon(
                    Icons.checkroom_outlined,
                    color: AppColors.hotPink,
                    size: 36,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Nosiva',
                  style: GoogleFonts.fraunces(
                    fontSize: 52,
                    fontWeight: FontWeight.w700,
                    color: AppColors.plum,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.l10n.welcomeSubtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: AppColors.plumSoft),
                ),
                const Spacer(),
                NosivaButton(
                  label: context.l10n.createAccount,
                  variant: NosivaButtonVariant.gradient,
                  onPressed: () => context.push(AppRoutes.signUp),
                ),
                const SizedBox(height: AppSpacing.sm),
                NosivaButton(
                  label: context.l10n.alreadyHaveAccount,
                  variant: NosivaButtonVariant.secondary,
                  onPressed: () => context.push(AppRoutes.signIn),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
