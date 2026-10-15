// Generates Android's small notification icon (the white "n" shown in the
// status bar) from assets/icon/splash_logo.png.
//
// Android draws this icon using only its transparency, so it must be pure
// white on transparent. Run from the project root:
//   dart run tool/generate_notification_icon.dart
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const _sizes = {
  'mdpi': 24,
  'hdpi': 36,
  'xhdpi': 48,
  'xxhdpi': 72,
  'xxxhdpi': 96,
};

void main() {
  final src = img.decodePng(File('assets/icon/splash_logo.png').readAsBytesSync())!;

  // Tight box around the visible logo.
  var minX = src.width, minY = src.height, maxX = -1, maxY = -1;
  for (final p in src) {
    if (p.a > 24) {
      minX = math.min(minX, p.x);
      maxX = math.max(maxX, p.x);
      minY = math.min(minY, p.y);
      maxY = math.max(maxY, p.y);
    }
  }
  final side = math.max(maxX - minX, maxY - minY) + 1;
  // Android's guideline keeps a small margin around the glyph (2dp of 24).
  final canvasSide = (side / 20 * 24).round();
  final canvas = img.Image(width: canvasSide, height: canvasSide, numChannels: 4);
  final ox = ((canvasSide - (maxX - minX + 1)) / 2).round();
  final oy = ((canvasSide - (maxY - minY + 1)) / 2).round();
  for (var y = minY; y <= maxY; y++) {
    for (var x = minX; x <= maxX; x++) {
      final a = src.getPixel(x, y).a;
      canvas.setPixelRgba(x - minX + ox, y - minY + oy, 255, 255, 255, a);
    }
  }

  // Status-bar icons are tiny (24 px at normal density); thicken the thin
  // hanger strokes so they survive the shrink.
  final bold = _dilate(canvas, (side * 0.014).round());

  for (final entry in _sizes.entries) {
    final out = img.copyResize(bold,
        width: entry.value,
        height: entry.value,
        interpolation: img.Interpolation.average);
    final dir = Directory('android/app/src/main/res/drawable-${entry.key}');
    dir.createSync(recursive: true);
    File('${dir.path}/ic_notification.png')
        .writeAsBytesSync(img.encodePng(out));
  }
  stdout.writeln('ic_notification: logo ${maxX - minX + 1}x${maxY - minY + 1} '
      'from ${src.width}x${src.height}');
}

/// Grows every visible pixel by [r] in each direction (alpha max filter, done
/// as a horizontal then a vertical pass).
img.Image _dilate(img.Image src, int r) {
  img.Image pass(img.Image from, bool horizontal) {
    final out = img.Image(width: from.width, height: from.height, numChannels: 4);
    for (var y = 0; y < from.height; y++) {
      for (var x = 0; x < from.width; x++) {
        num a = 0;
        for (var d = -r; d <= r; d++) {
          final sx = horizontal ? x + d : x;
          final sy = horizontal ? y : y + d;
          if (sx < 0 || sy < 0 || sx >= from.width || sy >= from.height) continue;
          a = math.max(a, from.getPixel(sx, sy).a);
        }
        out.setPixelRgba(x, y, 255, 255, 255, a);
      }
    }
    return out;
  }

  return pass(pass(src, true), false);
}
