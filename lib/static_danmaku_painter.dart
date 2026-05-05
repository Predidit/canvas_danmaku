import 'package:canvas_danmaku/base_danmaku_painter.dart';
import 'package:canvas_danmaku/models/danmaku_item.dart';
import 'package:flutter/material.dart';

final class StaticDanmakuPainter extends CustomPainter {
  final int count;
  final double trackHeight;
  final List<DanmakuItem?> danmakuItems;
  final double staticDurationInMilliseconds;
  final double fontSize;
  final int fontWeight;
  final double strokeWidth;
  final int tick;

  StaticDanmakuPainter({
    required this.count,
    required this.trackHeight,
    required this.danmakuItems,
    required this.staticDurationInMilliseconds,
    required this.fontSize,
    required this.fontWeight,
    required this.strokeWidth,
    required this.tick,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < danmakuItems.length; i++) {
      final item = danmakuItems[i];
      if (item != null) {
        item
          ..drawTick ??= tick
          ..drawParagraphIfNeeded(
            fontSize,
            fontWeight,
            strokeWidth,
          )
          ..xPosition = (size.width - item.width) / 2;

        BaseDanmakuPainter.paintImg(
          canvas,
          item,
          item.xPosition,
          trackHeight * i,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant StaticDanmakuPainter oldDelegate) =>
      oldDelegate.count != count ||
      oldDelegate.fontSize != fontSize ||
      oldDelegate.fontWeight != fontWeight ||
      oldDelegate.strokeWidth != strokeWidth;
}
