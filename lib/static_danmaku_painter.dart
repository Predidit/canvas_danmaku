import 'package:flutter/material.dart';
import 'models/danmaku_item.dart';
import '/utils/utils.dart';

class StaticDanmakuPainter extends CustomPainter {
  final double progress;
  final List<DanmakuItem> topDanmakuItems;
  final List<DanmakuItem> bottomDanmakuItems;
  final double danmakuDurationInSeconds;
  final double fontSize;
  final int fontWeight;
  final double strokeWidth;
  final double opacity;
  final double danmakuHeight;
  final bool running;
  final int tick;

  late final Paint selfSendPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..color = Colors.green;

  StaticDanmakuPainter({
    required this.progress,
    required this.topDanmakuItems,
    required this.bottomDanmakuItems,
    required this.danmakuDurationInSeconds,
    required this.fontSize,
    required this.fontWeight,
    required this.strokeWidth,
    required this.opacity,
    required this.danmakuHeight,
    required this.running,
    required this.tick,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制顶部弹幕
    for (DanmakuItem item in topDanmakuItems) {
      item.xPosition = (size.width - item.width) / 2;
      // 如果 Paragraph 没有缓存，则创建并缓存它
      item.paragraph ??= Utils.generateParagraph(
        content: item.content,
        danmakuWidth: size.width,
        fontSize: fontSize,
        fontWeight: fontWeight,
        size: item.content.isColorful == true
            ? Size(item.width, item.height)
            : null,
        screenSize: item.content.isColorful == true ? size : null,
        // opacity: opacity,
      );

      late Offset offset = Offset.zero;

      // 黑色部分
      if (strokeWidth > 0) {
        item.strokeParagraph ??= Utils.generateStrokeParagraph(
          content: item.content,
          danmakuWidth: size.width,
          fontSize: fontSize,
          fontWeight: fontWeight,
          strokeWidth: strokeWidth,
          size: item.content.isColorful == true
              ? Size(item.width, item.height)
              : null,
          offset: item.content.isColorful == true
              ? Offset(item.xPosition, item.yPosition)
              : null,
          screenSize: item.content.isColorful == true ? size : null,
          // opacity: opacity,
        );

        if (item.content.count != null) {
          TextPainter textPainter = Utils.getCountPainter(
            isStroke: true,
            content: item.content,
            fontSize: fontSize,
            fontWeight: fontWeight,
            strokeWidth: strokeWidth,
          );
          offset =
              Offset(textPainter.width / 2, item.yPosition + danmakuHeight / 3);
          textPainter.paint(
            canvas,
            Offset(item.xPosition - offset.dx, offset.dy),
          );
          canvas.drawParagraph(
            item.strokeParagraph!,
            Offset(item.xPosition + offset.dx, item.yPosition),
          );
        } else {
          canvas.drawParagraph(
            item.strokeParagraph!,
            Offset(item.xPosition, item.yPosition),
          );
        }
      }

      if (item.content.selfSend) {
        canvas.drawRect(
          Offset(item.xPosition, item.yPosition).translate(-2, 2) &
              (Size(item.width, item.height) + const Offset(4, 0)),
          selfSendPaint,
        );
      }

      if (item.content.count != null) {
        TextPainter textPainter = Utils.getCountPainter(
          isStroke: false,
          content: item.content,
          fontSize: fontSize,
          fontWeight: fontWeight,
          strokeWidth: strokeWidth,
        );
        textPainter.paint(
          canvas,
          Offset(item.xPosition - offset.dx, offset.dy),
        );
        canvas.drawParagraph(
          item.paragraph!,
          Offset(item.xPosition + offset.dx, item.yPosition),
        );
      } else {
        // 白色部分
        canvas.drawParagraph(
          item.paragraph!,
          Offset(item.xPosition, item.yPosition),
        );
      }
    }
    // 绘制底部弹幕 (翻转绘制)
    for (DanmakuItem item in bottomDanmakuItems) {
      item.xPosition = (size.width - item.width) / 2;
      // 如果 Paragraph 没有缓存，则创建并缓存它
      item.paragraph ??= Utils.generateParagraph(
        content: item.content,
        danmakuWidth: size.width,
        fontSize: fontSize,
        fontWeight: fontWeight,
        size: item.content.isColorful == true
            ? Size(item.width, item.height)
            : null,
        screenSize: item.content.isColorful == true ? size : null,
        // opacity: opacity,
      );

      late Offset offset = Offset.zero;

      // 黑色部分
      if (strokeWidth > 0) {
        item.strokeParagraph ??= Utils.generateStrokeParagraph(
          content: item.content,
          danmakuWidth: size.width,
          fontSize: fontSize,
          fontWeight: fontWeight,
          strokeWidth: strokeWidth,
          size: item.content.isColorful == true
              ? Size(item.width, item.height)
              : null,
          offset: item.content.isColorful == true
              ? Offset(
                  item.xPosition,
                  (size.height - item.yPosition - danmakuHeight),
                )
              : null,
          screenSize: item.content.isColorful == true ? size : null,
          // opacity: opacity,
        );

        if (item.content.count != null) {
          TextPainter textPainter = Utils.getCountPainter(
            isStroke: true,
            content: item.content,
            fontSize: fontSize,
            fontWeight: fontWeight,
            strokeWidth: strokeWidth,
          );
          offset = Offset(
              textPainter.width / 2,
              (size.height - item.yPosition - danmakuHeight) +
                  danmakuHeight / 3);
          textPainter.paint(
            canvas,
            Offset(item.xPosition - offset.dx, offset.dy),
          );
          canvas.drawParagraph(
            item.strokeParagraph!,
            Offset(
              item.xPosition + offset.dx,
              size.height - item.yPosition - danmakuHeight,
            ),
          );
        } else {
          canvas.drawParagraph(
            item.strokeParagraph!,
            Offset(
              item.xPosition,
              size.height - item.yPosition - danmakuHeight,
            ),
          );
        }
      }

      if (item.content.selfSend) {
        canvas.drawRect(
          Offset(item.xPosition, (size.height - item.yPosition - danmakuHeight))
                  .translate(-2, 2) &
              (Size(item.width, item.height) + const Offset(4, 0)),
          selfSendPaint,
        );
      }

      if (item.content.count != null) {
        TextPainter textPainter = Utils.getCountPainter(
          isStroke: false,
          content: item.content,
          fontSize: fontSize,
          fontWeight: fontWeight,
          strokeWidth: strokeWidth,
        );
        textPainter.paint(
          canvas,
          Offset(item.xPosition - offset.dx, offset.dy),
        );
        canvas.drawParagraph(
          item.paragraph!,
          Offset(
            item.xPosition + offset.dx,
            size.height - item.yPosition - danmakuHeight,
          ),
        );
      } else {
        // 白色部分
        canvas.drawParagraph(
          item.paragraph!,
          Offset(
            item.xPosition,
            size.height - item.yPosition - danmakuHeight,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant StaticDanmakuPainter oldDelegate) {
    return running ||
        oldDelegate.bottomDanmakuItems.length != bottomDanmakuItems.length ||
        oldDelegate.topDanmakuItems.length != topDanmakuItems.length ||
        oldDelegate.fontSize != fontSize ||
        oldDelegate.fontWeight != fontWeight ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.opacity != opacity;
  }
}
