import 'dart:io';

import 'package:image/image.dart' as img;

const _radiusFraction = 0.20; // 20% "squircle-ish" rounding
const _adaptiveForegroundSafeZone = 0.80; // scale into ~80% safe zone

void main(List<String> args) {
  final sourcePath = args.isNotEmpty ? args.first : 'web/icons/app-icon-source.png';
  final sourceFile = File(sourcePath);
  if (!sourceFile.existsSync()) {
    stderr.writeln('Source icon not found: $sourcePath');
    exitCode = 2;
    return;
  }

  final bytes = sourceFile.readAsBytesSync();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    stderr.writeln('Failed to decode PNG: $sourcePath');
    exitCode = 3;
    return;
  }

  final square = _cropToSquare(decoded);

  // Web
  _writePng(_roundedResized(square, 32), 'web/favicon-32.png');
  _writePng(_roundedResized(square, 48), 'web/favicon-48.png');
  _writePng(_roundedResized(square, 192), 'web/icons/Icon-192.png');
  _writePng(_roundedResized(square, 512), 'web/icons/Icon-512.png');
  _writePng(_roundedResized(square, 192), 'web/icons/Icon-maskable-192.png');
  _writePng(_roundedResized(square, 512), 'web/icons/Icon-maskable-512.png');

  // Android launcher (classic bitmap). Many launchers will mask anyway, but rounding
  // ensures a consistently rounded look where bitmaps are displayed as-is.
  _writePng(_roundedResized(square, 48), 'android/app/src/main/res/mipmap-mdpi/ic_launcher.png');
  _writePng(_roundedResized(square, 72), 'android/app/src/main/res/mipmap-hdpi/ic_launcher.png');
  _writePng(_roundedResized(square, 96), 'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png');
  _writePng(_roundedResized(square, 144), 'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png');
  _writePng(_roundedResized(square, 192), 'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png');

  // Android adaptive foreground layers (safe-zone padded, transparent background).
  _writePng(_adaptiveForeground(square, 108), 'android/app/src/main/res/mipmap-mdpi/ic_launcher_foreground.png');
  _writePng(_adaptiveForeground(square, 162), 'android/app/src/main/res/mipmap-hdpi/ic_launcher_foreground.png');
  _writePng(_adaptiveForeground(square, 216), 'android/app/src/main/res/mipmap-xhdpi/ic_launcher_foreground.png');
  _writePng(_adaptiveForeground(square, 324), 'android/app/src/main/res/mipmap-xxhdpi/ic_launcher_foreground.png');
  _writePng(_adaptiveForeground(square, 432), 'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png');

  stdout.writeln('Rounded icons generated from $sourcePath');
}

img.Image _cropToSquare(img.Image input) {
  if (input.width == input.height) return input;
  final size = input.width < input.height ? input.width : input.height;
  final x = (input.width - size) ~/ 2;
  final y = (input.height - size) ~/ 2;
  return img.copyCrop(input, x: x, y: y, width: size, height: size);
}

img.Image _roundedResized(img.Image square, int size) {
  final resized = img.copyResize(
    square,
    width: size,
    height: size,
    interpolation: img.Interpolation.cubic,
  );
  return _applyRoundedMask(resized, radius: size * _radiusFraction);
}

img.Image _applyRoundedMask(img.Image image, {required double radius}) {
  final r = radius;
  final w = image.width;
  final h = image.height;
  final r2 = r * r;

  // Ensure we have alpha.
  final out = img.Image.from(image);

  bool insideRoundedRect(int x, int y) {
    // Fast path: inside central rectangles.
    if (x >= r && x < w - r) return true;
    if (y >= r && y < h - r) return true;

    // Corner checks (quarter circles).
    final cx = (x < r) ? r : (w - r - 1);
    final cy = (y < r) ? r : (h - r - 1);
    final dx = x - cx;
    final dy = y - cy;
    return (dx * dx + dy * dy) <= r2;
  }

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (!insideRoundedRect(x, y)) {
        final p = out.getPixel(x, y);
        out.setPixelRgba(x, y, p.r, p.g, p.b, 0);
      }
    }
  }

  return out;
}

img.Image _adaptiveForeground(img.Image square, int size) {
  final canvas = img.Image(width: size, height: size);
  // Ensure fully transparent background.
  img.fill(canvas, color: img.ColorRgba8(0, 0, 0, 0));

  final fgSize = (size * _adaptiveForegroundSafeZone).round();
  final fg = _roundedResized(square, fgSize);
  final dx = ((size - fgSize) / 2).round();
  final dy = ((size - fgSize) / 2).round();
  img.compositeImage(canvas, fg, dstX: dx, dstY: dy);
  return canvas;
}

void _writePng(img.Image image, String path) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(img.encodePng(image, level: 6));
}

