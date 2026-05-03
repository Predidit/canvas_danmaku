import 'dart:ui' as ui;

import 'package:canvas_danmaku/models/danmaku_content_item.dart';
import 'package:canvas_danmaku/utils/utils.dart';

class DanmakuItem<T> {
  /// 弹幕内容
  final DanmakuContentItem<T> content;

  /// 弹幕宽度
  double width;

  /// 弹幕高度
  double height;

  /// 弹幕水平方向位置
  double xPosition;

  /// 弹幕竖直方向位置
  double yPosition;

  /// 静态和高级弹幕的起始绘制时间。
  double? drawTick;

  /// 滚动弹幕创建时的动画时间，位置由它和冻结速度直接计算。
  double scrollStartTick;

  /// 滚动弹幕创建时的起始横坐标。
  double scrollStartX;

  /// 滚动弹幕创建时冻结的移动速度。
  double scrollPixelsPerMillisecond;

  /// 弹幕栅格化图片缓存。
  ui.Image? image;

  int trackIndex = -1;

  bool rasterQueued = false;

  bool disposeQueued = false;

  bool expired = false;

  bool suspend = false;

  void dispose() {
    image?.dispose();
    image = null;
  }

  DanmakuItem({
    required this.content,
    required this.height,
    required this.width,
    this.xPosition = 0,
    this.yPosition = 0,
    this.trackIndex = -1,
    this.image,
    this.drawTick,
    this.scrollStartTick = 0,
    this.scrollStartX = 0,
    this.scrollPixelsPerMillisecond = 0,
  });

  void drawParagraphIfNeeded(
    double fontSize,
    int fontWeight,
    double strokeWidth,
    double devicePixelRatio,
    String? fontFamily,
  ) {
    if (image == null) {
      final paragraph = DmUtils.generateParagraph(
        content: content,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontFamily: fontFamily,
      );
      image = DmUtils.recordDanmakuImage(
        contentParagraph: paragraph,
        content: content,
        fontSize: fontSize,
        fontWeight: fontWeight,
        strokeWidth: strokeWidth,
        devicePixelRatio: devicePixelRatio,
        fontFamily: fontFamily,
      );
      width = paragraph.maxIntrinsicWidth +
          strokeWidth +
          (content.selfSend ? 4.0 : 0.0);
      height = paragraph.height + strokeWidth;
      paragraph.dispose();
    }
  }

  void updateScrollMetrics({
    required double tick,
    required double xPosition,
    required double viewWidth,
    required double durationInMilliseconds,
  }) {
    scrollStartTick = tick;
    scrollStartX = xPosition;
    this.xPosition = xPosition;
    scrollPixelsPerMillisecond = durationInMilliseconds <= 0
        ? 0
        : (viewWidth + width) / durationInMilliseconds;
  }

  @override
  String toString() {
    return 'DanmakuItem(content=$content, xPos=$xPosition, yPos=$yPosition, size=${ui.Size(width, height)}, drawTick=$drawTick)';
  }
}
