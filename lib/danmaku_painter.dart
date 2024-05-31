import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'models/danmaku_item.dart';

class DanmakuPainter extends CustomPainter {
  final double progress;
  final List<DanmakuItem> danmakuItems;
  final int danmakuDurationInSeconds;
  final double fontSize;
  final bool showStroke;
  final bool running;

  DanmakuPainter(this.progress, this.danmakuItems, this.danmakuDurationInSeconds, this.fontSize, this.showStroke, this.running);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.black;

    for (var item in danmakuItems) {
      final elapsedTime = DateTime.now().difference(item.creationTime).inMilliseconds;
      final totalDuration = danmakuDurationInSeconds * 1000;
      final startPosition = size.width;
      final endPosition = -item.width;
      final distance = startPosition - endPosition;

      item.xPosition = startPosition - (elapsedTime / totalDuration) * distance;

      // 如果 Paragraph 没有缓存，则创建并缓存它
      if (item.paragraph == null) {
        final ui.ParagraphBuilder builder = ui.ParagraphBuilder(ui.ParagraphStyle(
          textAlign: TextAlign.left,
          fontSize: fontSize,
          textDirection: TextDirection.ltr,
        ))
          ..pushStyle(ui.TextStyle(
            color: Colors.white,
          ))
          ..addText(item.content);

        item.paragraph = builder.build()
          ..layout(ui.ParagraphConstraints(width: size.width));
      }

      // 黑色部分
      if (showStroke) {
        if (item.strokeParagraph == null) {
          final ui.ParagraphBuilder strokeBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
            textAlign: TextAlign.left,
            fontSize: fontSize,
            textDirection: TextDirection.ltr,
          ))
            ..pushStyle(ui.TextStyle(
              foreground: strokePaint,
            ))
            ..addText(item.content);

          item.strokeParagraph = strokeBuilder.build()
            ..layout(ui.ParagraphConstraints(width: size.width));
        }

        canvas.drawParagraph(item.strokeParagraph!, Offset(item.xPosition, item.yPosition));
      }

      // 白色部分
      canvas.drawParagraph(item.paragraph!, Offset(item.xPosition, item.yPosition));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return running;
  }
}
