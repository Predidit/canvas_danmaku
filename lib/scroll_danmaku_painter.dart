import 'dart:ui' as ui;

import 'package:canvas_danmaku/base_danmaku_painter.dart';
import 'package:canvas_danmaku/models/danmaku_item.dart';
import 'package:flutter/material.dart';
import 'package:canvas_danmaku/utils/scroll_speed.dart';

final class ScrollDanmakuPainter extends BaseDanmakuPainter {
  final double durationInMilliseconds;
  final double maxScrollSpeed;
  final double maxScrollDistancePerFrame;
  final double displayRefreshRate;

  late final Paint selfSendPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..color = Colors.green;

  ScrollDanmakuPainter({
    required super.length,
    required super.danmakuItems,
    required this.durationInMilliseconds,
    required this.maxScrollSpeed,
    required this.maxScrollDistancePerFrame,
    required this.displayRefreshRate,
    required super.fontSize,
    required super.fontWeight,
    required super.strokeWidth,
    required super.devicePixelRatio,
    required super.running,
    required super.tick,
    super.batchThreshold,
  });

  @override
  void paintDanmaku(ui.Canvas canvas, ui.Size size, DanmakuItem item) {
    item.drawParagraphIfNeeded(
      fontSize,
      fontWeight,
      strokeWidth,
      devicePixelRatio,
    );
    if (!item.suspend) {
      final startPosition = size.width;
      final endPosition = -item.width;
      final previousTick = item.drawTick ??= tick;
      final elapsedMilliseconds = tick - previousTick;
      final speed = calculateScrollSpeed(
        viewportWidth: startPosition,
        itemWidth: item.width,
        durationInMilliseconds: durationInMilliseconds,
        maxScrollSpeed: maxScrollSpeed,
        maxScrollDistancePerFrame: maxScrollDistancePerFrame,
        displayRefreshRate: displayRefreshRate,
        devicePixelRatio: devicePixelRatio,
      );
      final distanceThisFrame = speed * elapsedMilliseconds / 1000;
      item.xPosition -= distanceThisFrame;

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

    item.drawTick = tick;
  }
}
