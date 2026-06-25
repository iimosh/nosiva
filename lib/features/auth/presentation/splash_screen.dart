import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/state_views.dart';
import '../../profile/presentation/current_profile_provider.dart';

/// Splash with the Nosiva wordmark. Shown while the session +
/// profile resolve; the router redirects away once state settles.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    if (profileAsync.hasError) {
      return Scaffold(
        body: ErrorStateView(
          message: '${profileAsync.error}',
          onRetry: () =>
              ref.read(currentProfileProvider.notifier).refreshProfile(),
        ),
      );
    }

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.splashGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Nosiva',
                style: GoogleFonts.fraunces(
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.splashTagline,
                style: GoogleFonts.notoSans(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 40),
              const SizedBox(
                height: 26,
                width: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
