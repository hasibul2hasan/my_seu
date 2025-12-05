import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final sourcePath = 'assets/AppIcon/MYSEU.png';
  final outDir = Directory('web/icons');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  final file = File(sourcePath);
  if (!file.existsSync()) {
    stderr.writeln('Source icon not found at ' + sourcePath);
    exit(1);
  }

  final bytes = file.readAsBytesSync();
  final original = img.decodeImage(bytes);
  if (original == null) {
    stderr.writeln('Failed to decode source image.');
    exit(2);
  }

  // Generate standard icons
  _writeIcon(original, 192, File('web/icons/Icon-192.png'));
  _writeIcon(original, 512, File('web/icons/Icon-512.png'));

  // Generate maskable icons (reuse plain resized for simplicity)
  _writeMaskable(original, 192, File('web/icons/Icon-maskable-192.png'));
  _writeMaskable(original, 512, File('web/icons/Icon-maskable-512.png'));

  stdout.writeln('Web icons generated in web/icons/.');
}

void _writeIcon(img.Image original, int size, File outFile) {
  final resized = img.copyResize(original, width: size, height: size, interpolation: img.Interpolation.cubic);
  outFile.writeAsBytesSync(img.encodePng(resized));
}

// Create a maskable icon by placing the image centered on a square canvas
// with padding, suitable for Android maskable treatment.
void _writeMaskable(img.Image original, int size, File outFile) {
  final canvas = img.Image(width: size, height: size);
  // Transparent background
  img.fill(canvas, color: img.ColorRgba8(0, 0, 0, 0));

  // Scale original to fit inside ~80% of the canvas (10% padding each side)
  final target = (size * 0.8).round();
  final resized = img.copyResize(
    original,
    width: target,
    height: target,
    interpolation: img.Interpolation.cubic,
  );

  final dx = ((size - resized.width) / 2).round();
  final dy = ((size - resized.height) / 2).round();

  // Manually blit resized into canvas to avoid API diffs
  for (int y = 0; y < resized.height; y++) {
    for (int x = 0; x < resized.width; x++) {
      final color = resized.getPixel(x, y);
      canvas.setPixel(dx + x, dy + y, color);
    }
  }

  outFile.writeAsBytesSync(img.encodePng(canvas));
}
