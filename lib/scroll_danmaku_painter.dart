import 'dart:ui' as ui;

import 'package:canvas_danmaku/base_danmaku_painter.dart';
import 'package:canvas_danmaku/models/danmaku_item.dart';

final class ScrollDanmakuPainter extends BaseDanmakuPainter {
  final double durationInMilliseconds;

  ScrollDanmakuPainter({
    required super.length,
    required super.danmakuItems,
    required this.durationInMilliseconds,
    required super.fontSize,
    required super.fontWeight,
    required super.strokeWidth,
    required super.devicePixelRatio,
    required super.running,
    required super.tick,
  });

  @override
  void paintDanmaku(ui.Canvas canvas, ui.Size size, DanmakuItem item) {
    if (item.image == null) return;

    if (!item.suspend) {
      final startPosition = size.width;
      final endPosition = -item.width;
      final distance = startPosition - endPosition;
      item.xPosition +=
          (((item.drawTick ??= tick) - tick) / durationInMilliseconds) *
              distance;

      if (item.xPosition < endPosition || item.xPosition > startPosition) {
        item.expired = true;
        return;
      }
    }

    BaseDanmakuPainter.paintImg(
      canvas,
      item,
      item.xPosition,
      item.yPosition,
      devicePixelRatio,
    );

    item.drawTick = tick;
  }
}
