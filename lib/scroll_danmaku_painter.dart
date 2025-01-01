import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'models/danmaku_item.dart';
import '/utils/utils.dart';

class ScrollDanmakuPainter extends CustomPainter {
  final double progress;
  final List<DanmakuItem> scrollDanmakuItems;
  final int danmakuDurationInSeconds;
  final double fontSize;
  final int fontWeight;
  final double strokeWidth;
  final double opacity;
  final double danmakuHeight;
  final bool running;
  final int tick;
  final int batchThreshold;
  final double totalDuration;

  late final Paint selfSendPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..color = Colors.green;

  ScrollDanmakuPainter({
    required this.progress,
    required this.scrollDanmakuItems,
    required this.danmakuDurationInSeconds,
    required this.fontSize,
    required this.fontWeight,
    required this.strokeWidth,
    required this.opacity,
    required this.danmakuHeight,
    required this.running,
    required this.tick,
    this.batchThreshold = 10, // 默认值为10，可以自行调整
  }) : totalDuration = danmakuDurationInSeconds * 1000;

  @override
  void paint(Canvas canvas, Size size) {
    final startPosition = size.width;

    if (scrollDanmakuItems.length > batchThreshold) {
      // 弹幕数量超过阈值时使用批量绘制
      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas pictureCanvas = Canvas(pictureRecorder);

      for (DanmakuItem item in scrollDanmakuItems) {
        item.lastDrawTick ??= item.creationTime;
        final endPosition = -item.width;
        final distance = startPosition - endPosition;
        item.xPosition = item.xPosition +
            (((item.lastDrawTick! - tick) / totalDuration) * distance);

        if (item.xPosition < -item.width || item.xPosition > size.width) {
          continue;
        }

        item.paragraph ??= Utils.generateParagraph(
          content: item.content,
          danmakuWidth: size.width,
          fontSize: fontSize,
          fontWeight: fontWeight,
          // opacity: opacity,
        );

        if (strokeWidth > 0) {
          item.strokeParagraph ??= Utils.generateStrokeParagraph(
            content: item.content,
            danmakuWidth: size.width,
            fontSize: fontSize,
            fontWeight: fontWeight,
            strokeWidth: strokeWidth,
            // opacity: opacity,
          );
          pictureCanvas.drawParagraph(
            item.strokeParagraph!,
            Offset(item.xPosition, item.yPosition),
          );
        }

        if (item.content.selfSend) {
          pictureCanvas.drawRect(
            Offset(item.xPosition, item.yPosition).translate(-2, 2) &
                (Size(item.width, item.height) + const Offset(4, 0)),
            selfSendPaint,
          );
        }

        pictureCanvas.drawParagraph(
          item.paragraph!,
          Offset(item.xPosition, item.yPosition),
        );
        item.lastDrawTick = tick;
      }

      final ui.Picture picture = pictureRecorder.endRecording();
      canvas.drawPicture(picture);
    } else {
      // 弹幕数量较少时直接绘制 (节约创建 canvas 的开销)
      for (DanmakuItem item in scrollDanmakuItems) {
        item.lastDrawTick ??= item.creationTime;
        final endPosition = -item.width;
        final distance = startPosition - endPosition;
        item.xPosition = item.xPosition +
            (((item.lastDrawTick! - tick) / totalDuration) * distance);

        if (item.xPosition < -item.width || item.xPosition > size.width) {
          continue;
        }

        item.paragraph ??= Utils.generateParagraph(
          content: item.content,
          danmakuWidth: size.width,
          fontSize: fontSize,
          fontWeight: fontWeight,
          // opacity: opacity,
        );

        if (strokeWidth > 0) {
          item.strokeParagraph ??= Utils.generateStrokeParagraph(
            content: item.content,
            danmakuWidth: size.width,
            fontSize: fontSize,
            fontWeight: fontWeight,
            strokeWidth: strokeWidth,
            // opacity: opacity,
          );
          canvas.drawParagraph(
            item.strokeParagraph!,
            Offset(item.xPosition, item.yPosition),
          );
        }

        if (item.content.selfSend) {
          canvas.drawRect(
            Offset(item.xPosition, item.yPosition).translate(-2, 2) &
                (Size(item.width, item.height) + const Offset(4, 0)),
            selfSendPaint,
          );
        }

        canvas.drawParagraph(
          item.paragraph!,
          Offset(item.xPosition, item.yPosition),
        );
        item.lastDrawTick = tick;
      }
    }
  }

  @override
  bool shouldRepaint(covariant ScrollDanmakuPainter oldDelegate) {
    return running ||
        oldDelegate.scrollDanmakuItems.length != scrollDanmakuItems.length ||
        oldDelegate.fontSize != fontSize ||
        oldDelegate.fontWeight != fontWeight ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.opacity != opacity;
  }
}
