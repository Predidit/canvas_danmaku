import 'dart:ui' as ui;

import 'package:canvas_danmaku/base_danmaku_painter.dart';
import 'package:canvas_danmaku/models/danmaku_item.dart';

final class ScrollDanmakuPainter extends BaseDanmakuPainter {
  ScrollDanmakuPainter({
    required super.length,
    required super.danmakuItems,
    required super.fontSize,
    required super.fontWeight,
    required super.strokeWidth,
    required super.devicePixelRatio,
    required super.running,
    required super.tick,
  });

  @override
  void paintDanmaku(ui.Canvas canvas, ui.Size size, DanmakuItem item) {
    if (!item.suspend) {
      final endPosition = -item.width;
      item.xPosition = item.scrollStartX -
          (tick - item.scrollStartTick) * item.scrollPixelsPerMillisecond;

      if (item.xPosition < endPosition || item.xPosition > size.width) {
        item.expired = true;
        return;
      }
    }

    if (item.image == null) return;

    BaseDanmakuPainter.paintImg(
      canvas,
      item,
      item.xPosition,
      item.yPosition,
      devicePixelRatio,
    );
  }
}
