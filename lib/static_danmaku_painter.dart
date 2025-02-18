import 'package:flutter/material.dart';
import 'models/danmaku_item.dart';

class StaticDanmakuPainter extends CustomPainter {
  final double progress;
  final List<DanmakuItem> topDanmakuItems;
  final List<DanmakuItem> buttomDanmakuItems;
  final int danmakuDurationInSeconds;
  final double fontSize;
  final int fontWeight;
  final bool showStroke;
  final double danmakuHeight;
  final bool running;
  final int tick;
  final double devicePixelRatio;
  final Paint selfSendPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..color = Colors.green;

  StaticDanmakuPainter(
      this.progress,
      this.topDanmakuItems,
      this.buttomDanmakuItems,
      this.danmakuDurationInSeconds,
      this.fontSize,
      this.fontWeight,
      this.showStroke,
      this.danmakuHeight,
      this.running,
      this.tick,
      this.devicePixelRatio);

  @override
  void paint(Canvas canvas, Size size)  {
    // 绘制顶部弹幕
    for (var item in topDanmakuItems) {
      if (item.paragraphImage == null) {
        continue;
      }
      item.xPosition = (size.width - item.width) / 2;
      // 计算逻辑宽高
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

      if (item.content.selfSend) {
        canvas.drawRect(
            Offset(item.xPosition, item.yPosition).translate(-2, 2) &
                (Size(item.width, item.height) + const Offset(4, 0)),
            selfSendPaint);
      }
      canvas.drawImageRect(item.paragraphImage!, srcRect, dstRect, Paint());
    }
    // 绘制底部弹幕 (翻转绘制)
    for (var item in buttomDanmakuItems) {
      if (item.paragraphImage == null) {
        continue;
      }
      item.xPosition = (size.width - item.width) / 2;
      final double logicalWidth = item.paragraphImage!.width / devicePixelRatio;
      final double logicalHeight =
          item.paragraphImage!.height / devicePixelRatio;
      final Rect srcRect = Rect.fromLTWH(
          0,
          0,
          item.paragraphImage!.width.toDouble(),
          item.paragraphImage!.height.toDouble());
      final Rect dstRect = Rect.fromLTWH(
          item.xPosition, (size.height - item.yPosition - danmakuHeight), logicalWidth, logicalHeight);

      if (item.content.selfSend) {
        canvas.drawRect(
            Offset(item.xPosition,
                        (size.height - item.yPosition - danmakuHeight))
                    .translate(-2, 2) &
                (Size(item.width, item.height) + const Offset(4, 0)),
            selfSendPaint);
      }
      canvas.drawImageRect(item.paragraphImage!, srcRect, dstRect, Paint());
    }
  }

  @override
  bool shouldRepaint(covariant StaticDanmakuPainter oldDelegate) {
    return true;
  }
}
