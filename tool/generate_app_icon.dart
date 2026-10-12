// Builds the Nosiva app icon from the brand artwork.
//
//   dart run tool/generate_app_icon.dart
//   dart run flutter_launcher_icons
//
// Source: assets/brand/nosiva_logo.jpg — the white "n" monogram on the brand
// rose. Writes into assets/icon/:
//   icon.png             full icon (iOS, older Android): rose + white n
//   icon_background.png  Android adaptive icon background (flat rose)
//   icon_foreground.png  Android adaptive icon foreground: the white n and its
//                        soft shadow on transparent, recovered from the artwork
//   splash_logo.png      the white n (white hanger) on transparent, at the
//                        artwork's own size, centred on a 1152 px square — the
//                        launch screen image, and the first frame of the
//                        in-app splash, which then glides it into the video

import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const brandRose = (0xC2, 0x74, 0x8C); // #c2748c

void main() {
  final src = img.decodeJpg(File('assets/brand/nosiva_logo.jpg').readAsBytesSync())!;
  stdout.writeln('source ${src.width}x${src.height}');

  final bgLum = _backgroundLuminance(src);

  // Where the white monogram sits: everything clearly brighter than the rose.
  var minX = src.width, minY = src.height, maxX = 0, maxY = 0;
  for (final p in src) {
    if (_lum(p) > bgLum + 60) {
      minX = math.min(minX, p.x);
      maxX = math.max(maxX, p.x);
      minY = math.min(minY, p.y);
      maxY = math.max(maxY, p.y);
    }
  }
  final cx = (minX + maxX) / 2, cy = (minY + maxY) / 2;
  final logoSize = math.max(maxX - minX, maxY - minY).toDouble();
  stdout.writeln('monogram x $minX..$maxX, y $minY..$maxY '
      '(${maxX - minX}x${maxY - minY}) at (${cx.round()}, ${cy.round()})');

  Directory('assets/icon').createSync(recursive: true);

  // Full icon: the monogram fills ~56% of the square, like the artwork.
  final full = _square(src, cx, cy, logoSize / 0.56, bgLum, transparent: false);
  _save('assets/icon/icon.png', img.copyResize(full, width: 1024, height: 1024,
      interpolation: img.Interpolation.cubic));

  // Adaptive foreground: Android shows only the middle two-thirds, so the
  // monogram is drawn smaller to look the same size once cropped.
  final fg = _square(src, cx, cy, logoSize / (0.56 * 0.667), bgLum, transparent: true);
  _save('assets/icon/icon_foreground.png', img.copyResize(fg, width: 1024, height: 1024,
      interpolation: img.Interpolation.cubic));

  final bg = img.Image(width: 1024, height: 1024);
  img.fill(bg, color: img.ColorRgb8(brandRose.$1, brandRose.$2, brandRose.$3));
  _save('assets/icon/icon_background.png', bg);

  // Launch screen: shown at 4x density, so 1152 px = 288 dp — the size
  // Android 12+ uses for a splash icon. White only: the intro video brings
  // its own shadow as it fades in.
  final splash = _square(src, cx, cy, 1152, bgLum, transparent: true, shadow: false);
  _save('assets/icon/splash_logo.png', splash);
  stdout.writeln('splash_logo: monogram x ${minX - (cx - 576).round()}..'
      '${maxX - (cx - 576).round()}, y ${minY - (cy - 576).round()}..'
      '${maxY - (cy - 576).round()} of 1152');
}

double _lum(img.Pixel p) => 0.2126 * p.r + 0.7152 * p.g + 0.0722 * p.b;

/// Median brightness of the four corners — the plain rose background.
double _backgroundLuminance(img.Image src) {
  final samples = <double>[];
  for (final (x, y) in [(10, 10), (src.width - 11, 10), (10, src.height - 11),
                        (src.width - 11, src.height - 11)]) {
    for (var dy = 0; dy < 8; dy++) {
      for (var dx = 0; dx < 8; dx++) {
        samples.add(_lum(src.getPixel(x + dx - 4, y + dy - 4)));
      }
    }
  }
  samples.sort();
  return samples[samples.length ~/ 2];
}

/// A square of [size] centred on (cx, cy). Areas outside the artwork are
/// filled with the brand rose (or left transparent).
img.Image _square(img.Image src, double cx, double cy, double size, double bgLum,
    {required bool transparent, bool shadow = true}) {
  final n = size.round();
  final out = img.Image(width: n, height: n, numChannels: transparent ? 4 : 3);
  final x0 = (cx - size / 2).round(), y0 = (cy - size / 2).round();
  for (var y = 0; y < n; y++) {
    for (var x = 0; x < n; x++) {
      final sx = x0 + x, sy = y0 + y;
      final inside = sx >= 0 && sy >= 0 && sx < src.width && sy < src.height;
      if (!transparent) {
        if (inside) {
          final p = src.getPixel(sx, sy);
          out.setPixelRgb(x, y, p.r, p.g, p.b);
        } else {
          out.setPixelRgb(x, y, brandRose.$1, brandRose.$2, brandRose.$3);
        }
        continue;
      }
      if (!inside) {
        out.setPixelRgba(x, y, 0, 0, 0, 0);
        continue;
      }
      // Undo the blend with the background: brighter than the rose means
      // white at some opacity, darker means the soft black shadow.
      final l = _lum(src.getPixel(sx, sy));
      if (l > bgLum + 6) {
        final a = ((l - bgLum) / (255 - bgLum)).clamp(0.0, 1.0);
        out.setPixelRgba(x, y, 255, 255, 255, (a * 255).round());
      } else if (shadow && l < bgLum - 4) {
        final a = (1 - l / bgLum).clamp(0.0, 1.0);
        out.setPixelRgba(x, y, 0, 0, 0, (a * 255).round());
      } else {
        out.setPixelRgba(x, y, 0, 0, 0, 0);
      }
    }
  }
  return out;
}

void _save(String path, img.Image image) {
  File(path).writeAsBytesSync(img.encodePng(image));
  stdout.writeln('wrote $path');
}
