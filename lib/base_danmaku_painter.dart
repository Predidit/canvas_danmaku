import 'dart:ui' as ui;

import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:flutter/material.dart';

abstract base class BaseDanmakuPainter extends CustomPainter {
  final int length;
  final List<DanmakuItem> danmakuItems;
  final double fontSize;
  final int fontWeight;
  final double strokeWidth;
  final double devicePixelRatio;
  final bool running;
  final double tick;

  static final Paint _paint = Paint();

  static double snapToPhysicalPixel(double value, double devicePixelRatio) {
    if (devicePixelRatio <= 0) return value;
    return (value * devicePixelRatio).roundToDouble() / devicePixelRatio;
  }

  static Offset snapOffsetToPhysicalPixel(
    double dx,
    double dy,
    double devicePixelRatio,
  ) {
    return Offset(
      snapToPhysicalPixel(dx, devicePixelRatio),
      snapToPhysicalPixel(dy, devicePixelRatio),
    );
  }

  const BaseDanmakuPainter({
    required this.length,
    required this.danmakuItems,
    required this.fontSize,
    required this.fontWeight,
    required this.strokeWidth,
    required this.devicePixelRatio,
    required this.running,
    required this.tick,
  });

  static void paintImg(
    Canvas canvas,
    DanmakuItem item,
    double dx,
    double dy,
    double devicePixelRatio,
  ) {
    paintImage(
      canvas,
      item.image!,
      dx,
      dy,
      item.width,
      item.height,
      devicePixelRatio,
      _paint,
    );
  }

  static void paintImage(
    Canvas canvas,
    ui.Image image,
    double dx,
    double dy,
    double width,
    double height,
    double devicePixelRatio,
    Paint paint,
  ) {
    // Rasterized text shimmers when sampled from fractional physical pixels.
    // Keep animation state continuous, and only snap the final draw position.
    final offset = snapOffsetToPhysicalPixel(dx, dy, devicePixelRatio);
    if (devicePixelRatio == 1.0) {
      canvas.drawImage(image, offset, paint);
    } else {
      final src =
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
      final dst = Rect.fromLTWH(offset.dx, offset.dy, width, height);
      canvas.drawImageRect(image, src, dst, paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    DanmakuItem? suspend;
    for (var i in danmakuItems) {
      if (i.expired) continue;

      if (i.suspend) {
        suspend = i;
        continue;
      }

      paintDanmaku(canvas, size, i);
    }

    if (suspend case final suspend?) {
      paintDanmaku(canvas, size, suspend);
    }
  }

  void paintDanmaku(Canvas canvas, Size size, DanmakuItem item);

  @override
  bool shouldRepaint(covariant BaseDanmakuPainter oldDelegate) {
    return (running && length != 0) ||
        oldDelegate.length != length ||
        oldDelegate.fontSize != fontSize ||
        oldDelegate.fontWeight != fontWeight ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.devicePixelRatio != devicePixelRatio;
  }
}
