import 'dart:ui' as ui;

import 'package:canvas_danmaku/base_danmaku_painter.dart';
import 'package:canvas_danmaku/models/danmaku_item.dart';
import 'package:flutter/material.dart';

final class ScrollDanmakuPainter extends BaseDanmakuPainter {
  final double trackHeight;
  final List<List<DanmakuItem>> danmakuItems;
  final double durationInMilliseconds;

  const ScrollDanmakuPainter({
    required super.length,
    required this.trackHeight,
    required this.danmakuItems,
    required this.durationInMilliseconds,
    required super.fontSize,
    required super.fontWeight,
    required super.strokeWidth,
    required super.running,
    required super.tick,
    super.batchThreshold,
  });

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final ui.PictureRecorder? pictureRecorder;
    final Canvas pictureCanvas;

    if (length > batchThreshold) {
      pictureRecorder = ui.PictureRecorder();
      pictureCanvas = Canvas(pictureRecorder);
    } else {
      pictureRecorder = null;
      pictureCanvas = canvas;
    }

    DanmakuItem? suspend;
    int suspendIndex = 0;
    for (int index = 0; index < danmakuItems.length; index++) {
      for (var i in danmakuItems[index]) {
        if (i.expired) continue;

        if (i.suspend) {
          suspend = i;
          suspendIndex = index;
          continue;
        }

        paintDanmaku(pictureCanvas, size, i, index * trackHeight);
      }
    }

    if (suspend case final suspend?) {
      paintDanmaku(pictureCanvas, size, suspend, suspendIndex * trackHeight);
    }

    if (pictureRecorder != null) {
      final ui.Picture picture = pictureRecorder.endRecording();
      canvas.drawPicture(picture);
      picture.dispose();
    }
  }

  void paintDanmaku(
    ui.Canvas canvas,
    ui.Size size,
    DanmakuItem item,
    double yPos,
  ) {
    item.drawParagraphIfNeeded(
      fontSize,
      fontWeight,
      strokeWidth,
    );
    if (!item.suspend) {
      final startPosition = size.width;
      final endPosition = -item.width;

      if (durationInMilliseconds.isNegative) {
        item.xPosition +=
            (tick - (item.drawTick ??= tick)) * durationInMilliseconds;
      } else {
        final distance = startPosition - endPosition;
        item.xPosition +=
            (((item.drawTick ??= tick) - tick) / durationInMilliseconds) *
                distance;
      }

      if (item.xPosition < endPosition || item.xPosition > startPosition) {
        item.expired = true;
        return;
      }
    }

    BaseDanmakuPainter.paintImg(
      canvas,
      item,
      item.xPosition,
      yPos,
    );

    item.drawTick = tick;
  }
}
