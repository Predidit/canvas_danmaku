import 'dart:ui' as ui;

import 'package:canvas_danmaku/models/danmaku_item.dart';
import 'package:canvas_danmaku/utils/utils.dart';
import 'package:flutter/material.dart';

class ScrollDanmakuPainter extends CustomPainter {
  final int length;
  final List<DanmakuItem> scrollDanmakuItems;
  final double fontSize;
  final int fontWeight;
  final double strokeWidth;
  final bool running;
  final int tick;
  final int batchThreshold;
  final double durationInMilliseconds;

  late final Paint selfSendPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..color = Colors.green;

  ScrollDanmakuPainter({
    required this.length,
    required this.scrollDanmakuItems,
    required this.durationInMilliseconds,
    required this.fontSize,
    required this.fontWeight,
    required this.strokeWidth,
    required this.running,
    required this.tick,
    this.batchThreshold = 10, // 默认值为10，可以自行调整
  });

  @override
  void paint(Canvas canvas, Size size) {
    final startPosition = size.width;

    if (scrollDanmakuItems.length > batchThreshold) {
      // 弹幕数量超过阈值时使用批量绘制
      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas pictureCanvas = Canvas(pictureRecorder);

      for (DanmakuItem item in scrollDanmakuItems) {
        if (item.expired) {
          continue;
        }

        item.drawTick ??= tick;
        item.generateParagraphIfNeeded(fontSize, fontWeight);
        final endPosition = -item.width;
        final distance = startPosition - endPosition;
        item.xPosition = item.xPosition +
            (((item.drawTick! - tick) / durationInMilliseconds) * distance);

        if (item.xPosition < -item.width || item.xPosition > startPosition) {
          item.expired = true;
          continue;
        }

        if (strokeWidth > 0) {
          item.strokeParagraph ??= DmUtils.generateStrokeParagraph(
            content: item.content,
            fontSize: fontSize,
            fontWeight: fontWeight,
            strokeWidth: strokeWidth,
            size:
                item.content.isColorful ? Size(item.width, item.height) : null,
          );
          if (item.content.isColorful) {
            canvas
              ..save()
              ..translate(item.xPosition, item.yPosition)
              ..drawParagraph(item.strokeParagraph!, Offset.zero)
              ..restore();
          } else {
            canvas.drawParagraph(
              item.strokeParagraph!,
              Offset(item.xPosition, item.yPosition),
            );
          }
        } else {
          item.clearStrokeParagraph();
        }

        if (item.content.selfSend) {
          pictureCanvas.drawRect(
            Offset(item.xPosition - 2, item.yPosition) &
                Size(item.width + 4, item.height),
            selfSendPaint,
          );
        }
        pictureCanvas.drawParagraph(
          item.paragraph!,
          Offset(item.xPosition, item.yPosition),
        );

        item.drawTick = tick;
      }

      final ui.Picture picture = pictureRecorder.endRecording();
      canvas.drawPicture(picture);
    } else {
      // 弹幕数量较少时直接绘制 (节约创建 canvas 的开销)
      for (DanmakuItem item in scrollDanmakuItems) {
        if (item.expired) {
          continue;
        }

        item.drawTick ??= tick;
        item.generateParagraphIfNeeded(fontSize, fontWeight);
        final endPosition = -item.width;
        final distance = startPosition - endPosition;
        item.xPosition = item.xPosition +
            (((item.drawTick! - tick) / durationInMilliseconds) * distance);

        if (item.xPosition < -item.width || item.xPosition > startPosition) {
          item.expired = true;
          continue;
        }

        if (strokeWidth > 0) {
          item.strokeParagraph ??= DmUtils.generateStrokeParagraph(
            content: item.content,
            fontSize: fontSize,
            fontWeight: fontWeight,
            strokeWidth: strokeWidth,
            size:
                item.content.isColorful ? Size(item.width, item.height) : null,
          );
          if (item.content.isColorful) {
            canvas
              ..save()
              ..translate(item.xPosition, item.yPosition)
              ..drawParagraph(item.strokeParagraph!, Offset.zero)
              ..restore();
          } else {
            canvas.drawParagraph(
              item.strokeParagraph!,
              Offset(item.xPosition, item.yPosition),
            );
          }
        } else {
          item.clearStrokeParagraph();
        }

        if (item.content.selfSend) {
          canvas.drawRect(
            Offset(item.xPosition - 2, item.yPosition) &
                Size(item.width + 4, item.height),
            selfSendPaint,
          );
        }

        canvas.drawParagraph(
          item.paragraph!,
          Offset(item.xPosition, item.yPosition),
        );

        item.drawTick = tick;
      }
    }
  }

  @override
  bool shouldRepaint(covariant ScrollDanmakuPainter oldDelegate) {
    return running ||
        oldDelegate.length != length ||
        oldDelegate.fontSize != fontSize ||
        oldDelegate.fontWeight != fontWeight ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
