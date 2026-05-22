// Generates app_icon.png, app_icon_fg.png and splash_logo.png from code.
// Run: dart run tool/generate_icon.dart
//
// Design: dark background + 3 concentric BLE/signal arcs + center dot
// Colors match the app theme (AppColors).

import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

// ── palette ─────────────────────────────────────────────────────────────────
const _bgR = 11;  const _bgG = 11;  const _bgB = 16;  // #0B0B10
const _acR = 124; const _acG = 92;  const _acB = 255; // #7C5CFF (accent)
const _hiR = 182; const _hiG = 158; const _hiB = 255; // #B69EFF (highlight)

void main() {
  _save('assets/images/app_icon.png',    1024, opaqueBg: true);
  _save('assets/images/app_icon_fg.png', 1024, opaqueBg: false);
  _save('assets/images/splash_logo.png',  512, opaqueBg: true);
  print('\nDone! Now run:\n  dart run flutter_launcher_icons');
}

// ── top-level renderer ───────────────────────────────────────────────────────

void _save(String path, int sz, {required bool opaqueBg}) {
  final im = img.Image(width: sz, height: sz, numChannels: 4);
  final cx = sz ~/ 2;
  final cy = (sz * 0.56).round(); // center dot sits slightly below vertical middle
  final s  = sz / 1024.0;        // scale factor

  // Background
  if (opaqueBg) {
    img.fill(im, color: img.ColorRgba8(_bgR, _bgG, _bgB, 255));
    _glow(im, cx, cy, (290 * s).round());
  } else {
    img.fill(im, color: img.ColorRgba8(0, 0, 0, 0));
  }

  // Signal arcs (outer → inner, increasingly opaque)
  _arc(im, cx, cy, (310 * s).round(), (13 * s).round().clamp(8, 24), 80,  opaqueBg: opaqueBg);
  _arc(im, cx, cy, (220 * s).round(), (17 * s).round().clamp(10, 30), 155, opaqueBg: opaqueBg);
  _arc(im, cx, cy, (130 * s).round(), (21 * s).round().clamp(12, 36), 220, opaqueBg: opaqueBg);

  // Center dot: accent ring + highlight core
  _disc(im, cx, cy, (38 * s).round(), _acR, _acG, _acB, 255, opaqueBg: opaqueBg);
  _disc(im, cx, cy, (20 * s).round(), _hiR, _hiG, _hiB, 255, opaqueBg: opaqueBg);

  Directory(File(path).parent.path).createSync(recursive: true);
  File(path).writeAsBytesSync(img.encodePng(im));
  print('  ✓  $path');
}

// ── drawing primitives ───────────────────────────────────────────────────────

// Radial purple glow blended into the dark background.
void _glow(img.Image im, int cx, int cy, int maxR) {
  for (var dy = -maxR; dy <= maxR; dy++) {
    for (var dx = -maxR; dx <= maxR; dx++) {
      final d = math.sqrt(dx * dx + dy * dy);
      if (d >= maxR) continue;
      final x = cx + dx;
      final y = cy + dy;
      if (!_inBounds(im, x, y)) continue;
      final t = 1.0 - d / maxR;
      _blend(im, x, y, _acR, _acG, _acB, (t * t * 55).round(), opaqueBg: true);
    }
  }
}

// Thick arc spanning from lower-left → top → lower-right
// (like a wifi / BLE signal symbol pointing upward from the center dot).
void _arc(img.Image im, int cx, int cy, int radius, int thick, int alpha,
    {required bool opaqueBg}) {
  // Angles in screen-coord radians (y-axis points DOWN):
  //   π        → directly left  (same height as cy)
  //   3π/2     → directly above (smallest y)
  //   2π / 0   → directly right (same height as cy)
  // The arc goes from (π - 0.42) counterclockwise to (2π + 0.42),
  // which dips ~24° below horizontal on each side, forming the signal shape.
  const startAngle = math.pi - 0.42;
  const endAngle   = math.pi * 2 + 0.42;
  final steps = (radius * 8).clamp(700, 6000);

  for (var i = 0; i <= steps; i++) {
    final angle = startAngle + (endAngle - startAngle) * i / steps;
    for (var t = 0; t < thick; t++) {
      final r  = radius - thick ~/ 2 + t;
      final px = (cx + r * math.cos(angle)).round();
      final py = (cy + r * math.sin(angle)).round();
      if (!_inBounds(im, px, py)) continue;
      // Soft anti-aliased edges
      final edge = (t < 2 || t >= thick - 2) ? 0.45 : 1.0;
      _blend(im, px, py, _acR, _acG, _acB, (alpha * edge).round(),
          opaqueBg: opaqueBg);
    }
  }
}

// Anti-aliased filled circle.
void _disc(img.Image im, int cx, int cy, int radius, int r, int g, int b,
    int alpha, {required bool opaqueBg}) {
  for (var dy = -radius; dy <= radius; dy++) {
    for (var dx = -radius; dx <= radius; dx++) {
      final d = math.sqrt(dx * dx + dy * dy);
      if (d > radius) continue;
      final x = cx + dx;
      final y = cy + dy;
      if (!_inBounds(im, x, y)) continue;
      final edge = d > radius - 2.0 ? (radius - d) / 2.0 : 1.0;
      _blend(im, x, y, r, g, b, (alpha * edge).round(), opaqueBg: opaqueBg);
    }
  }
}

// ── helpers ──────────────────────────────────────────────────────────────────

bool _inBounds(img.Image im, int x, int y) =>
    x >= 0 && x < im.width && y >= 0 && y < im.height;

// Alpha-composite (r, g, b, alpha) onto pixel (x, y).
// opaqueBg=true  → blends into an opaque dark background (result stays opaque).
// opaqueBg=false → proper RGBA pre-multiplied composite onto transparent canvas.
void _blend(img.Image im, int x, int y, int r, int g, int b, int alpha,
    {required bool opaqueBg}) {
  if (alpha <= 0) return;

  final src = alpha / 255.0;
  final px  = im.getPixel(x, y);

  if (!opaqueBg) {
    // Porter-Duff source-over on transparent canvas
    final dst = px.a / 255.0;
    final outA = src + dst * (1 - src);
    if (outA <= 0) return;
    im.setPixel(x, y, img.ColorRgba8(
      ((r * src + px.r * dst * (1 - src)) / outA).round(),
      ((g * src + px.g * dst * (1 - src)) / outA).round(),
      ((b * src + px.b * dst * (1 - src)) / outA).round(),
      (outA * 255).round(),
    ));
  } else {
    // Straight composite over opaque pixel
    im.setPixel(x, y, img.ColorRgba8(
      (px.r * (1 - src) + r * src).round(),
      (px.g * (1 - src) + g * src).round(),
      (px.b * (1 - src) + b * src).round(),
      255,
    ));
  }
}
