import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/nosiva_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.blushGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                const Spacer(),
                Text('💖', style: theme.textTheme.displayLarge),
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
                  'Buy & sell pre-loved fashion with\na community that gets your vibe.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: AppColors.plumSoft),
                ),
                const Spacer(),
                NosivaButton(
                  label: 'Create account',
                  variant: NosivaButtonVariant.gradient,
                  onPressed: () => context.push(AppRoutes.signUp),
                ),
                const SizedBox(height: AppSpacing.sm),
                NosivaButton(
                  label: 'I already have an account',
                  variant: NosivaButtonVariant.secondary,
                  onPressed: () => context.push(AppRoutes.signIn),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => context.push(AppRoutes.designSystem),
                  child: const Text('Peek the design system ✨'),
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
