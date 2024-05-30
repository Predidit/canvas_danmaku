import 'package:flutter/material.dart';
import 'package:canvas_danmaku/models/danmaku_item.dart';

class DanmakuPainter extends CustomPainter {
  final double progress;
  final List<DanmakuItem> danmakuItems;
  final int danmakuDurationInSeconds;
  final double fontSize;
  final bool showStroke;

  DanmakuPainter(this.progress, this.danmakuItems, this.danmakuDurationInSeconds, this.fontSize, this.showStroke);

  @override
  void paint(Canvas canvas, Size size) {
    for (var item in danmakuItems) {
      final elapsedTime = DateTime.now().difference(item.creationTime).inMilliseconds;
      final totalDuration = danmakuDurationInSeconds * 1000;
      final startPosition = size.width;
      final endPosition = -item.width;
      final distance = startPosition - endPosition;

      item.xPosition = startPosition - (elapsedTime / totalDuration) * distance;

      if (showStroke) {
        final strokePainter = TextPainter(
          text: TextSpan(
            text: item.content,
            style: TextStyle(
              fontSize: fontSize,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2
                ..color = Colors.black,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        strokePainter.layout();
        strokePainter.paint(canvas, Offset(item.xPosition, item.yPosition));
      }

      final textPainter = TextPainter(
        text: TextSpan(
          text: item.content,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(item.xPosition, item.yPosition));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}