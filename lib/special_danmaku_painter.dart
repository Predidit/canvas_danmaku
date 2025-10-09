import 'dart:math';
import 'dart:ui' as ui;

import 'package:canvas_danmaku/models/danmaku_content_item.dart';
import 'package:canvas_danmaku/models/danmaku_item.dart';
import 'package:canvas_danmaku/utils/utils.dart';
import 'package:flutter/material.dart';

class SpecialDanmakuPainter extends CustomPainter {
  final int length;
  final List<DanmakuItem> specialDanmakuItems;
  final double fontSize;
  final int fontWeight;
  final double strokeWidth;
  final bool running;
  final int tick;
  final int batchThreshold;

  SpecialDanmakuPainter({
    required this.length,
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
    if (specialDanmakuItems.isEmpty) {
      return;
    }

    final Canvas pictureCanvas;
    final batch = specialDanmakuItems.length > batchThreshold;
    late final ui.PictureRecorder pictureRecorder;
    if (batch) {
      pictureRecorder = ui.PictureRecorder();
      pictureCanvas = Canvas(pictureRecorder);
    } else {
      pictureCanvas = canvas;
    }
    for (final item in specialDanmakuItems) {
      item.drawTick ??= tick;
      final elapsed = tick - item.drawTick!;
      final content = item.content as SpecialDanmakuContentItem;
      if (elapsed >= 0 && elapsed < content.duration) {
        _paintSpecialDanmaku(pictureCanvas, item, content, size, elapsed);
      }
    }
    if (batch) {
      final ui.Picture picture = pictureRecorder.endRecording();
      canvas.drawPicture(picture);
      picture.dispose();
    }
  }

  void _paintSpecialDanmaku(Canvas canvas, DanmakuItem dm,
      SpecialDanmakuContentItem item, Size size, int elapsed) {
    // 透明度动画
    late final alpha =
        item.alphaTween?.transform(elapsed / item.duration) ?? item.color.a;
    final color = item.alphaTween == null
        ? item.color
        : item.color.withValues(alpha: alpha);
    // 文本
    final ui.Paragraph paragraph;
    if (color != item.color) {
      dm.paragraph?.dispose();
      item.color = color;
      paragraph = dm.paragraph = DmUtils.generateSpecialParagraph(
          content: item,
          fontWeight: fontWeight,
          elapsed: elapsed,
          strokeWidth: strokeWidth);
    } else {
      paragraph = dm.paragraph!;
    }

    // 路径动画 TODO

    // else 位移动画
    final double dx, dy;
    if (elapsed > item.translationStartDelay) {
      late final translateProgress = item.easingType.transform(min(1.0,
          (elapsed - item.translationStartDelay) / item.translationDuration));

      double getOffset(Tween<double> tween) => tween is ConstantTween
          ? tween.begin!
          : tween.transform(translateProgress);

      dx = getOffset(item.translateXTween) * size.width;
      dy = getOffset(item.translateYTween) * size.height;
    } else {
      dx = item.translateXTween.begin! * size.width;
      dy = item.translateYTween.begin! * size.height;
    }

    if (item.rotateZ != 0 || item.matrix != null) {
      canvas
        ..save()
        ..translate(dx, dy);
      if (item.matrix != null) {
        canvas.transform(item.matrix!.storage);
      } else {
        canvas.rotate(item.rotateZ);
      }
      canvas
        ..drawParagraph(paragraph, Offset.zero)
        ..restore();
    } else {
      canvas.drawParagraph(paragraph, Offset(dx, dy));
    }
  }

  @override
  bool shouldRepaint(covariant SpecialDanmakuPainter oldDelegate) {
    return running ||
        oldDelegate.length != length ||
        oldDelegate.fontSize != fontSize ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
