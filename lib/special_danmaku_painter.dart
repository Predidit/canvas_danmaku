import 'dart:math' show min;
import 'dart:ui' as ui;

import 'package:canvas_danmaku/base_danmaku_painter.dart';
import 'package:canvas_danmaku/models/danmaku_content_item.dart';
import 'package:canvas_danmaku/models/danmaku_item.dart';
import 'package:flutter/material.dart';

final class SpecialDanmakuPainter extends BaseDanmakuPainter {
  SpecialDanmakuPainter({
    required super.length,
    required super.danmakuItems,
    required super.fontSize,
    required super.fontWeight,
    required super.strokeWidth,
    required super.devicePixelRatio,
    required super.running,
    required super.tick,
  });

  static final _paint = Paint();

  @override
  void paintDanmaku(ui.Canvas canvas, ui.Size size, DanmakuItem item) {
    if (item.image == null) return;

    final elapsed = tick - (item.drawTick ??= tick);
    final content = item.content as SpecialDanmakuContentItem;
    if (0 <= elapsed && elapsed < content.duration) {
      _paintSpecialDanmaku(canvas, item, content, size, elapsed);
    } else {
      item.expired = true;
    }
  }

  @pragma("vm:prefer-inline")
  void _paintSpecialDanmaku(Canvas canvas, DanmakuItem dm,
      SpecialDanmakuContentItem item, Size size, double elapsed) {
    final color = item.alphaTween == null
        ? item.color
        : item.color.withValues(
            alpha: item.alphaTween!.transform(
            elapsed / item.duration,
          ));

    double dx, dy;
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
    dx += item.rect.left;
    dy += item.rect.top;

    paintImg(
      canvas,
      dm.image!,
      dx,
      dy,
      _paint..color = color,
    );
  }

  void paintImg(
    ui.Canvas canvas,
    ui.Image image,
    double dx,
    double dy,
    Paint paint,
  ) {
    BaseDanmakuPainter.paintImage(
      canvas,
      image,
      dx,
      dy,
      image.width / devicePixelRatio,
      image.height / devicePixelRatio,
      devicePixelRatio,
      paint,
    );
  }
}
