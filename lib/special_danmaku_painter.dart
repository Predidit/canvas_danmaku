import 'dart:math';

import 'package:canvas_danmaku/models/danmaku_content_item.dart';
import 'package:canvas_danmaku/models/danmaku_item.dart';
import 'package:flutter/material.dart';

class SpecialDanmakuPainter extends CustomPainter {
  final double progress;
  final List<DanmakuItem> specialDanmakuItems;
  final double fontSize;
  final int fontWeight;
  final double strokeWidth;
  final bool running;
  final int tick;
  final int batchThreshold; // TODO

  SpecialDanmakuPainter({
    required this.progress,
    required this.specialDanmakuItems,
    required this.fontSize,
    required this.fontWeight,
    required this.strokeWidth,
    required this.running,
    required this.tick,
    this.batchThreshold = 10, // 默认值为10，可以自行调整
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final item in specialDanmakuItems) {
      final elapsed = tick - item.creationTime;
      final content = item.content as SpecialDanmakuContentItem;
      if (elapsed >= 0 && elapsed < content.duration) {
        _paintSpecialDanmaku(canvas, content, size, elapsed);
      }
    }
  }

  void _paintSpecialDanmaku(
      Canvas canvas, SpecialDanmakuContentItem item, Size size, int elapsed) {
    // 透明度动画
    final color = item.color
        .withOpacity(item.alphaTween.transform(elapsed / item.duration));

    // 文本
    final textPainter = TextPainter(
      text: TextSpan(
        text: item.text,
        style: TextStyle(
          color: color,
          fontSize: item.fontSize,
          fontWeight: FontWeight.values[fontWeight],
          shadows: item.hasStroke
              ? [Shadow(color: Colors.black, blurRadius: strokeWidth)]
              : null,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();

    // 路径动画 TODO

    // else 位移动画
    if (elapsed > item.translationStartDelay) {
      double translateProgress = 0.0;
      translateProgress = min(
          (elapsed - item.translationStartDelay) / item.translationDuration,
          1.0);
      translateProgress = item.easingType.transform(translateProgress);

      final dx = item.translateXTween.transform(translateProgress) * size.width;
      final dy =
          item.translateYTween.transform(translateProgress) * size.height;
      canvas.translate(dx, dy);
    }

    if (item.matrix != null) canvas.transform(item.matrix!.storage);

    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SpecialDanmakuPainter oldDelegate) {
    return running ||
        oldDelegate.specialDanmakuItems.length != specialDanmakuItems.length ||
        oldDelegate.fontSize != fontSize ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
