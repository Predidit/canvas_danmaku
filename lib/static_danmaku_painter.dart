import 'package:canvas_danmaku/models/danmaku_content_item.dart';
import 'package:canvas_danmaku/models/danmaku_item.dart';
import 'package:canvas_danmaku/utils/utils.dart';
import 'package:flutter/material.dart';

class StaticDanmakuPainter extends CustomPainter {
  final int length;
  final List<DanmakuItem> staticDanmakuItems;
  final double staticDurationInMilliseconds;
  final double fontSize;
  final int fontWeight;
  final double strokeWidth;
  final bool running;
  final int tick;

  late final Paint selfSendPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..color = Colors.green;

  StaticDanmakuPainter({
    required this.length,
    required this.staticDanmakuItems,
    required this.staticDurationInMilliseconds,
    required this.fontSize,
    required this.fontWeight,
    required this.strokeWidth,
    required this.running,
    required this.tick,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (DanmakuItem item in staticDanmakuItems) {
      switch (item.content.type) {
        case DanmakuItemType.top:
          item
            ..drawTick ??= tick
            ..generateParagraphIfNeeded(fontSize, fontWeight)
            ..xPosition = (size.width - item.width) / 2;

          // 黑色部分
          if (strokeWidth > 0) {
            item.strokeParagraph ??= DmUtils.generateStrokeParagraph(
              content: item.content,
              fontSize: fontSize,
              fontWeight: fontWeight,
              strokeWidth: strokeWidth,
              size: item.content.isColorful
                  ? Size(item.width, item.height)
                  : null,
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

          // 白色部分
          canvas.drawParagraph(
            item.paragraph!,
            Offset(item.xPosition, item.yPosition),
          );
          break;
        case DanmakuItemType.bottom:
          item
            ..drawTick ??= tick
            ..generateParagraphIfNeeded(fontSize, fontWeight)
            ..xPosition = (size.width - item.width) / 2;

          // 黑色部分
          if (strokeWidth > 0) {
            item.strokeParagraph ??= DmUtils.generateStrokeParagraph(
              content: item.content,
              fontSize: fontSize,
              fontWeight: fontWeight,
              strokeWidth: strokeWidth,
              size: item.content.isColorful
                  ? Size(item.width, item.height)
                  : null,
            );
            if (item.content.isColorful) {
              canvas
                ..save()
                ..translate(
                  item.xPosition,
                  size.height - item.yPosition - item.height,
                )
                ..drawParagraph(item.strokeParagraph!, Offset.zero)
                ..restore();
            } else {
              canvas.drawParagraph(
                item.strokeParagraph!,
                Offset(
                  item.xPosition,
                  size.height - item.yPosition - item.height,
                ),
              );
            }
          } else {
            item.clearStrokeParagraph();
          }

          if (item.content.selfSend) {
            canvas.drawRect(
              Offset(item.xPosition - 2,
                      (size.height - item.yPosition - item.height)) &
                  Size(item.width + 4, item.height),
              selfSendPaint,
            );
          }

          // 白色部分
          canvas.drawParagraph(
            item.paragraph!,
            Offset(
              item.xPosition,
              size.height - item.yPosition - item.height,
            ),
          );
          break;
        case DanmakuItemType.special:
        case DanmakuItemType.scroll:
          throw UnsupportedError('type error');
      }
    }
  }

  @override
  bool shouldRepaint(covariant StaticDanmakuPainter oldDelegate) {
    return oldDelegate.length != length ||
        oldDelegate.fontSize != fontSize ||
        oldDelegate.fontWeight != fontWeight ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
