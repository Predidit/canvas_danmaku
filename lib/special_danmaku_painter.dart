import 'dart:math' show min;
import 'dart:ui' as ui;

import 'package:canvas_danmaku/base_danmaku_painter.dart';
import 'package:canvas_danmaku/models/danmaku_content_item.dart';
import 'package:canvas_danmaku/models/danmaku_item.dart';
import 'package:canvas_danmaku/utils/utils.dart';
import 'package:flutter/material.dart';

final class SpecialDanmakuPainter extends BaseDanmakuPainter {
  List<DanmakuItem> danmakuItems;

  SpecialDanmakuPainter({
    required super.length,
    required this.danmakuItems,
    required super.fontSize,
    required super.fontWeight,
    required super.strokeWidth,
    required super.running,
    required super.tick,
    super.batchThreshold,
  });

  static final _paint = Paint();

  void paintDanmaku(ui.Canvas canvas, ui.Size size, DanmakuItem item) {
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
      SpecialDanmakuContentItem item, Size size, int elapsed) {
    // 透明度动画
    final color = item.alphaTween == null
        ? item.color
        : item.color.withValues(
            alpha: item.alphaTween!.transform(
            elapsed / item.duration,
          ));

    // 位移动画
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
      dm.image ??= DmUtils.recordSpecialDanmakuImg(
        content: item,
        fontWeight: fontWeight,
        strokeWidth: strokeWidth,
      ),
      dx,
      dy,
      item.rect.width,
      item.rect.height,
      _paint..color = color,
    );
  }

  void paintImg(
    ui.Canvas canvas,
    ui.Image image,
    double dx,
    double dy,
    double imgW,
    double imgH,
    Paint paint,
  ) {
    if (image.width == imgW.ceil()) {
      canvas.drawImage(image, Offset(dx, dy), paint);
    } else {
      final src =
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
      final dst = Rect.fromLTWH(dx, dy, imgW, imgH);
      canvas.drawImageRect(image, src, dst, paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final ui.PictureRecorder? pictureRecorder;
    final Canvas pictureCanvas;
    final length = danmakuItems.length;

    if (length > batchThreshold) {
      pictureRecorder = ui.PictureRecorder();
      pictureCanvas = Canvas(pictureRecorder);
    } else {
      pictureRecorder = null;
      pictureCanvas = canvas;
    }
    for (var i in danmakuItems) {
      if (i.expired) continue;

      paintDanmaku(pictureCanvas, size, i);
    }

    if (pictureRecorder != null) {
      final ui.Picture picture = pictureRecorder.endRecording();
      canvas.drawPicture(picture);
      picture.dispose();
    }
  }
}
