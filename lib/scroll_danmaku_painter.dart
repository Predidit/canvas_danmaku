import 'dart:ui' as ui;

import 'package:canvas_danmaku/base_danmaku_painter.dart';
import 'package:canvas_danmaku/models/danmaku_item.dart';
import 'package:canvas_danmaku/utils/utils.dart';
import 'package:flutter/material.dart';

final class ScrollDanmakuPainter extends BaseDanmakuPainter {
  final double durationInMilliseconds;

  late final Paint selfSendPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..color = Colors.green;

  ScrollDanmakuPainter({
    required super.length,
    required super.danmakuItems,
    required this.durationInMilliseconds,
    required super.fontSize,
    required super.fontWeight,
    required super.strokeWidth,
    required super.running,
    required super.tick,
    super.batchThreshold,
  });

  @override
  void paintDanmaku(ui.Canvas canvas, ui.Size size, DanmakuItem item) {
    item.generateParagraphIfNeeded(fontSize, fontWeight);
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

    if (strokeWidth > 0) {
      item.strokeParagraph ??= DmUtils.generateStrokeParagraph(
        content: item.content,
        fontSize: fontSize,
        fontWeight: fontWeight,
        strokeWidth: strokeWidth,
        size: item.content.isColorful ? Size(item.width, item.height) : null,
      );
      if (item.content.isColorful) {
        canvas
          ..save()
          ..translate(item.xPosition, item.yPosition)
          ..drawParagraph(item.strokeParagraph!, Offset.zero)
          ..restore();
      } else {
        canvas.drawParagraph(
          item.strokeParagraph!,
          Offset(item.xPosition, item.yPosition),
        );
      }
    } else {
      item.clearStrokeParagraph();
    }

    if (item.content.selfSend) {
      canvas.drawRect(
        Offset(item.xPosition - 2, item.yPosition) &
            Size(item.width + 4, item.height),
        selfSendPaint,
      );
    }
    canvas.drawParagraph(
      item.paragraph!,
      Offset(item.xPosition, item.yPosition),
    );

    item.drawTick = tick;
  }
}
