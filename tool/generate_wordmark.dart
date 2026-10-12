// Builds the "nosiva" wordmark used inside the app.
//
//   dart run tool/generate_wordmark.dart
//
// Source: assets/brand/nosiva_wordmark_on_white.webp — the lettering in rose
// on white. Writes assets/brand/wordmark.png: the lettering in white on
// transparent, cropped tight. The app tints it to any colour (see
// NosivaWordmark), so one image serves light mode, dark mode and coloured
// backgrounds alike.

import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

void main() {
  final src = img.decodeWebP(
      File('assets/brand/nosiva_wordmark_on_white.webp').readAsBytesSync())!;
  stdout.writeln('source ${src.width}x${src.height}');

  double lum(img.Pixel p) => 0.2126 * p.r + 0.7152 * p.g + 0.0722 * p.b;

  // The ink colour: the darkest pixels are fully covered by lettering.
  var inkLum = 255.0;
  for (final p in src) {
    inkLum = math.min(inkLum, lum(p));
  }
  stdout.writeln('ink luminance ${inkLum.round()}');

  // Coverage of each pixel = how far it moved from white towards the ink.
  final alpha = List<int>.filled(src.width * src.height, 0);
  var minX = src.width, minY = src.height, maxX = 0, maxY = 0;
  for (final p in src) {
    final a = ((255 - lum(p)) / (255 - inkLum)).clamp(0.0, 1.0);
    final value = a < 0.03 ? 0 : (a * 255).round(); // drop compression noise
    alpha[p.y * src.width + p.x] = value;
    if (value > 0) {
      minX = math.min(minX, p.x);
      maxX = math.max(maxX, p.x);
      minY = math.min(minY, p.y);
      maxY = math.max(maxY, p.y);
    }
  }

  // Thicken every stroke slightly (each pixel takes the strongest coverage
  // within [weight] px). The artwork's hairlines are ~2 px, which fade away
  // when the logo is shown small; this keeps them visible and the shapes
  // intact.
  const weight = 3;
  final bold = List<int>.filled(alpha.length, 0);
  final offsets = <(int, int)>[
    for (var dy = -weight; dy <= weight; dy++)
      for (var dx = -weight; dx <= weight; dx++)
        if (dx * dx + dy * dy <= weight * weight) (dx, dy),
  ];
  for (var y = math.max(0, minY - weight); y <= math.min(src.height - 1, maxY + weight); y++) {
    for (var x = math.max(0, minX - weight); x <= math.min(src.width - 1, maxX + weight); x++) {
      var best = 0;
      for (final (dx, dy) in offsets) {
        final sx = x + dx, sy = y + dy;
        if (sx < 0 || sy < 0 || sx >= src.width || sy >= src.height) continue;
        final v = alpha[sy * src.width + sx];
        if (v > best) best = v;
      }
      bold[y * src.width + x] = best;
    }
  }
  alpha.setAll(0, bold);
  minX -= weight;
  minY -= weight;
  maxX += weight;
  maxY += weight;

  const pad = 4;
  final x0 = math.max(0, minX - pad), y0 = math.max(0, minY - pad);
  final x1 = math.min(src.width - 1, maxX + pad), y1 = math.min(src.height - 1, maxY + pad);
  final out = img.Image(width: x1 - x0 + 1, height: y1 - y0 + 1, numChannels: 4);
  for (var y = y0; y <= y1; y++) {
    for (var x = x0; x <= x1; x++) {
      out.setPixelRgba(x - x0, y - y0, 255, 255, 255, alpha[y * src.width + x]);
    }
  }

  File('assets/brand/wordmark.png').writeAsBytesSync(img.encodePng(out));
  stdout.writeln('wrote assets/brand/wordmark.png ${out.width}x${out.height} '
      '(aspect ${(out.width / out.height).toStringAsFixed(3)})');
}
