import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// The "nosiva" logo lettering (from the brand artwork, built by
/// tool/generate_wordmark.dart with slightly strengthened strokes so it stays
/// crisp at small sizes). Drawn in [color]; by default deep wine in light
/// mode and soft rose in dark mode, for clear contrast on both.
class NosivaWordmark extends StatelessWidget {
  const NosivaWordmark({super.key, this.height = 28, this.color});

  final double height;
  final Color? color;

  static const _asset = 'assets/brand/wordmark.png';
  static const aspectRatio = 802 / 217; // width / height of the image

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _asset,
      height: height,
      width: height * aspectRatio,
      color: color ?? context.palette.emphasis,
      colorBlendMode: BlendMode.srcIn,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'Nosiva',
    );
  }
}
