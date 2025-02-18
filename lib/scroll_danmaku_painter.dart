import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'models/danmaku_item.dart';

class ScrollDanmakuPainter extends CustomPainter {
  final double progress;
  final List<DanmakuItem> scrollDanmakuItems;
  final int danmakuDurationInSeconds;
  final double fontSize;
  final int fontWeight;
  final bool showStroke;
  final double danmakuHeight;
  final bool running;
  final int tick;
  final double devicePixelRatio;

  final double totalDuration;
  final Paint selfSendPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..color = Colors.green;

  ScrollDanmakuPainter(
    this.progress,
    this.scrollDanmakuItems,
    this.danmakuDurationInSeconds,
    this.fontSize,
    this.fontWeight,
    this.showStroke,
    this.danmakuHeight,
    this.running,
    this.tick,
    this.devicePixelRatio,
  ) : totalDuration = danmakuDurationInSeconds * 1000;

  @override
  void paint(Canvas canvas, Size size) {
    final startPosition = size.width;

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas pictureCanvas = Canvas(pictureRecorder);

    for (var item in scrollDanmakuItems) {
      if (item.paragraphImage == null) {
        continue;
      }
      item.lastDrawTick ??= item.creationTime;
      final endPosition = -item.width;
      final distance = startPosition - endPosition;
      item.xPosition = item.xPosition +
          (((item.lastDrawTick! - tick) / totalDuration) * distance);
      final double logicalWidth = item.paragraphImage!.width / devicePixelRatio;
      final double logicalHeight =
          item.paragraphImage!.height / devicePixelRatio;
      final Rect srcRect = Rect.fromLTWH(
          0,
          0,
          item.paragraphImage!.width.toDouble(),
          item.paragraphImage!.height.toDouble());
      final Rect dstRect = Rect.fromLTWH(
          item.xPosition, item.yPosition, logicalWidth, logicalHeight);

      if (item.xPosition < -item.width || item.xPosition > size.width) {
        continue;
      }

      if (item.content.selfSend) {
        pictureCanvas.drawRect(
            Offset(item.xPosition, item.yPosition).translate(-2, 2) &
                (Size(item.width, item.height) + const Offset(4, 0)),
            selfSendPaint);
      }
      pictureCanvas.drawImageRect(
          item.paragraphImage!, srcRect, dstRect, Paint());
      item.lastDrawTick = tick;
    }

    final ui.Picture picture = pictureRecorder.endRecording();
    canvas.drawPicture(picture);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
