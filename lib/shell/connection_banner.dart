import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/l10n_extensions.dart';
import '../core/network/connection_status.dart';
import '../core/theme/app_colors.dart';
import '../features/auth/presentation/splash_screen.dart'
    show introFinishedProvider;

/// Slides a thin "No internet connection" bar in above every screen while
/// the app is offline, and a short "Back online" when it reconnects. The
/// screen below moves down to make room instead of being covered.
class ConnectionBanner extends ConsumerStatefulWidget {
  const ConnectionBanner({super.key, required this.child});

  final Widget child;

  static const barHeight = 30.0;

  @override
  ConsumerState<ConnectionBanner> createState() => _ConnectionBannerState();
}

class _ConnectionBannerState extends ConsumerState<ConnectionBanner> {
  bool _backOnline = false;
  Timer? _hideBackOnline;

  @override
  void dispose() {
    _hideBackOnline?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(isOfflineProvider, (previous, offline) {
      _hideBackOnline?.cancel();
      if (previous == true && !offline) {
        setState(() => _backOnline = true);
        _hideBackOnline = Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _backOnline = false);
        });
      } else if (offline && _backOnline) {
        setState(() => _backOnline = false);
      }
    });

    final offline = ref.watch(isOfflineProvider);
    // Kept off the opening animation so the logo hand-off stays seamless.
    final ready = ref.watch(introFinishedProvider);
    final visible = ready && (offline || _backOnline);

    final media = MediaQuery.of(context);
    final top = media.padding.top;
    final fullHeight = top + ConnectionBanner.barHeight;

    final bar = _Bar(offline: offline, topInset: top);

    return TweenAnimationBuilder<double>(
      tween: Tween(end: visible ? 1 : 0),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: widget.child,
      builder: (context, t, child) {
        // The bar takes over the status-bar area, so the screen below loses
        // that much top padding as the bar grows.
        final childTop = top * (1 - t);
        return Column(
          children: [
            SizedBox(
              height: fullHeight * t,
              child: t == 0
                  ? null
                  : ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.bottomCenter,
                        minHeight: fullHeight,
                        maxHeight: fullHeight,
                        child: bar,
                      ),
                    ),
            ),
            Expanded(
              child: MediaQuery(
                data: media.copyWith(
                  padding: media.padding.copyWith(top: childTop),
                  viewPadding: media.viewPadding.copyWith(top: childTop),
                ),
                child: child!,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.offline, required this.topInset});

  final bool offline;
  final double topInset;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = offline ? l10n.offlineBanner : l10n.backOnline;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Material(
        color: offline ? AppColors.plum : AppColors.success,
        child: Padding(
          padding: EdgeInsets.only(top: topInset),
          child: Semantics(
            liveRegion: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  offline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
