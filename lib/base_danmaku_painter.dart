import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:flutter/material.dart';

abstract base class BaseDanmakuPainter extends CustomPainter {
  final int length;
  final double fontSize;
  final int fontWeight;
  final double strokeWidth;
  final bool running;
  final int batchThreshold;
  final int tick;

  static final Paint _paint = Paint();

  const BaseDanmakuPainter({
    required this.length,
    required this.fontSize,
    required this.fontWeight,
    required this.strokeWidth,
    required this.running,
    required this.tick,
    this.batchThreshold = 10, // 默认值为10，可以自行调整
  });

  static void paintImg(
    Canvas canvas,
    DanmakuItem item,
    double dx,
    double dy,
  ) {
    final img = item.image!;
    if (img.width == item.width.ceil()) {
      canvas.drawImage(img, Offset(dx, dy), _paint);
    } else {
      final src =
          Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
      final dst = Rect.fromLTWH(dx, dy, item.width, item.height);
      canvas.drawImageRect(img, src, dst, _paint);
    }
  }

  @override
  bool shouldRepaint(covariant BaseDanmakuPainter oldDelegate) {
    return (running && length != 0) ||
        oldDelegate.length != length ||
        oldDelegate.fontSize != fontSize ||
        oldDelegate.fontWeight != fontWeight ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
