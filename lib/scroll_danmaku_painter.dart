import 'dart:ui' as ui;

import 'package:canvas_danmaku/base_danmaku_painter.dart';
import 'package:canvas_danmaku/models/danmaku_item.dart';
import 'package:flutter/material.dart';

final class ScrollDanmakuPainter extends BaseDanmakuPainter {
  final double durationInMicroseconds;

  late final Paint selfSendPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..color = Colors.green;

  ScrollDanmakuPainter({
    required super.length,
    required super.danmakuItems,
    required this.durationInMicroseconds,
    required super.fontSize,
    required super.fontWeight,
    required super.strokeWidth,
    required super.devicePixelRatio,
    required super.running,
    required super.tickInMicroseconds,
    super.batchThreshold,
  });

  @override
  void paintDanmaku(ui.Canvas canvas, ui.Size size, DanmakuItem item) {
    final time = tickInMicroseconds;
    item.drawParagraphIfNeeded(
      fontSize,
      fontWeight,
      strokeWidth,
      devicePixelRatio,
    );
    if (!item.suspend) {
      final startPosition = size.width;
      final endPosition = -item.width;
      final distance = startPosition - endPosition;
      final previousTime = item.drawTimeInMicroseconds ?? time;
      item.xPosition -=
          (time - previousTime) / durationInMicroseconds * distance;

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

    item.drawTimeInMicroseconds = time;
  }
}
