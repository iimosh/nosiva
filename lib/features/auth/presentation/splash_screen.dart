import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/state_views.dart';
import '../../profile/presentation/current_profile_provider.dart';

/// True once the opening animation has played (or been skipped because the
/// video couldn't load). The router keeps the app on the splash until then.
final introFinishedProvider = StateProvider<bool>((ref) => false);

/// The opening, one continuous sequence:
///
/// 1. Tapping the app icon shows the phone's launch screen: the white n on
///    rose (flutter_native_splash in pubspec.yaml).
/// 2. This screen takes over with the identical logo in the identical place,
///    so the handover can't be seen.
/// 3. The logo glides onto the n in the brand intro video and melts into it
///    (its hanger turns wine), then the video carries on: "osiva" and the
///    tagline appear.
/// 4. The app moves on once the tagline is complete and the session has
///    loaded, whichever is later.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Video background: flat at the top, darkening towards the bottom.
  // Top = the launch screen colour.
  static const _top = Color(0xFFB86982);
  static const _bottom = Color(0xFF91465E);

  static const _videoAsset = 'assets/splash/nosiva_intro.mp4';
  static const _logoAsset = 'assets/icon/splash_logo.png';

  // The launch screen draws the 1152 px logo at 4x density: 288 dp, centred.
  static const _logoDp = 288.0;
  static const _logoPx = 1152.0;

  // Where the n's stems sit, measured in the logo image and in the video
  // frame at [_handoff] (1210 x 1712). Lining these up makes the glide land
  // exactly on the video's n. Re-measure if either artwork changes.
  static const _logoN = (left: 337.0, right: 815.0, bottom: 850.0);
  static const _videoN = (left: 402.0, right: 810.0, bottom: 1058.0);
  static const _videoWidthPx = 1210.0;
  static const _handoff = Duration(milliseconds: 400);

  // The tagline finishes typing at about 2.6 s of the video.
  static const _introEnd = Duration(milliseconds: 2800);
  // If the video hasn't loaded by then, carry on with just the logo.
  static const _loadTimeout = Duration(milliseconds: 2500);

  late final VideoPlayerController _video = VideoPlayerController.asset(
    _videoAsset,
    videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
  );
  late final AnimationController _glide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  late final bool _alreadyPlayed = ref.read(introFinishedProvider);
  Timer? _fallback;
  bool _logoReady = false;
  bool _videoReady = false;
  bool _playing = false;
  bool _precached = false;

  @override
  void initState() {
    super.initState();
    _fallback = Timer(_loadTimeout, () {
      if (!_videoReady) _finish();
    });
    _loadVideo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    // Draw the logo first, then lift the launch screen off it.
    precacheImage(const AssetImage(_logoAsset), context).whenComplete(() {
      if (!mounted) return;
      setState(() => _logoReady = true);
      WidgetsBinding.instance
          .addPostFrameCallback((_) => FlutterNativeSplash.remove());
      _maybeStartGlide();
    });
  }

  Future<void> _loadVideo() async {
    try {
      await _video.initialize();
      await _video.setVolume(0);
      // Back on the splash later (e.g. while signing in): show the finished
      // logo instead of replaying the intro.
      await _video.seekTo(_alreadyPlayed ? _introEnd : _handoff);
      if (!mounted) return;
      _fallback?.cancel();
      setState(() {
        _videoReady = true;
        _playing = _alreadyPlayed;
      });
      _maybeStartGlide();
    } catch (_) {
      _finish();
    }
  }

  void _maybeStartGlide() {
    if (_alreadyPlayed || !_logoReady || !_videoReady || _glide.isAnimating) return;
    _glide.forward().whenComplete(() async {
      if (!mounted) return;
      setState(() => _playing = true);
      _video.addListener(_onProgress);
      await _video.play();
    });
  }

  void _onProgress() {
    if (_video.value.position >= _introEnd) {
      _video.removeListener(_onProgress);
      _finish();
    }
  }

  void _finish() {
    if (!mounted || ref.read(introFinishedProvider)) return;
    ref.read(introFinishedProvider.notifier).state = true;
  }

  @override
  void dispose() {
    _fallback?.cancel();
    _video.removeListener(_onProgress);
    _video.dispose();
    _glide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final introDone = ref.watch(introFinishedProvider);
    final profileAsync = ref.watch(currentProfileProvider);

    if (introDone && profileAsync.hasError) {
      return Scaffold(
        body: ErrorStateView(
          message: friendlyError(context.l10n, profileAsync.error),
          onRetry: () =>
              ref.read(currentProfileProvider.notifier).refreshProfile(),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _top,
        body: LayoutBuilder(
          builder: (context, box) {
            final screen = Size(box.maxWidth, box.maxHeight);
            final videoRect = _videoRectFor(screen);
            return AnimatedBuilder(
              animation: _glide,
              builder: (context, _) {
                final t = Curves.easeInOutCubic.transform(_glide.value);
                // The video melts in over the second half of the glide; the
                // logo melts out as it lands on the video's own n.
                final videoOpacity = _playing
                    ? 1.0
                    : const Interval(0.45, 1.0, curve: Curves.easeOut)
                        .transform(_glide.value);
                final logoOpacity = 1 -
                    const Interval(0.55, 1.0, curve: Curves.easeIn)
                        .transform(_glide.value);
                return Stack(
                  children: [
                    if (_videoReady)
                      Opacity(
                        opacity: videoOpacity,
                        child: _VideoLayer(
                          video: _video,
                          rect: videoRect,
                          screen: screen,
                          top: _top,
                          bottom: _bottom,
                        ),
                      ),
                    if (_logoReady && !_playing)
                      Positioned.fromRect(
                        rect: Rect.lerp(
                          _logoStartRect(screen),
                          _logoEndRect(videoRect),
                          t,
                        )!,
                        child: Opacity(
                          opacity: logoOpacity,
                          child: Image.asset(_logoAsset),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Where the video is drawn: always the full screen width, centred. On
  /// phones (taller than the video) the background continues above and
  /// below; on wider screens the plain top and bottom are trimmed instead.
  Rect _videoRectFor(Size screen) {
    final aspect = _videoReady ? _video.value.aspectRatio : 1210 / 1712;
    final height = screen.width / aspect;
    return Rect.fromLTWH(0, (screen.height - height) / 2, screen.width, height);
  }

  /// Same place and size as the launch screen's logo.
  Rect _logoStartRect(Size screen) => Rect.fromCenter(
        center: screen.center(Offset.zero),
        width: _logoDp,
        height: _logoDp,
      );

  /// The logo sized and placed so its n sits exactly on the video's n.
  Rect _logoEndRect(Rect videoRect) {
    final k = videoRect.width / _videoWidthPx; // dp per video pixel
    final size = (_videoN.right - _videoN.left) * k *
        _logoPx / (_logoN.right - _logoN.left);
    final perPx = size / _logoPx;
    return Rect.fromLTWH(
      videoRect.left + _videoN.left * k - _logoN.left * perPx,
      videoRect.top + _videoN.bottom * k - _logoN.bottom * perPx,
      size,
      size,
    );
  }
}

class _VideoLayer extends StatelessWidget {
  const _VideoLayer({
    required this.video,
    required this.rect,
    required this.screen,
    required this.top,
    required this.bottom,
  });

  final VideoPlayerController video;
  final Rect rect;
  final Size screen;
  final Color top;
  final Color bottom;

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: screen,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Below the video, its darker bottom colour carries on.
          Positioned(
            left: 0,
            right: 0,
            top: rect.bottom - 1,
            bottom: 0,
            child: ColoredBox(color: bottom),
          ),
          Positioned.fromRect(rect: rect, child: VideoPlayer(video)),
          // Soft fades over the video's top and bottom edges (plain
          // background there), so compression at the very edge never shows
          // as a line against the background.
          Positioned(
            left: 0,
            right: 0,
            top: rect.top - 1,
            height: 32,
            child: _EdgeFade(from: top),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: rect.bottom - 40,
            height: 41,
            child: _EdgeFade(from: bottom, upwards: true),
          ),
        ],
      ),
    );
  }
}

/// A solid colour melting into transparent — down from the top edge, or up
/// from the bottom edge.
class _EdgeFade extends StatelessWidget {
  const _EdgeFade({required this.from, this.upwards = false});
  final Color from;
  final bool upwards;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: upwards ? Alignment.bottomCenter : Alignment.topCenter,
            end: upwards ? Alignment.topCenter : Alignment.bottomCenter,
            colors: [from, from.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
