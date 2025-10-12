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

  /// 上次绘制时间
  int? drawTick;

  /// 弹幕布局缓存
  ui.Paragraph? paragraph;
  ui.Paragraph? strokeParagraph;

  bool expired = false;

  bool suspend = false;

  @pragma("vm:prefer-inline")
  bool needRemove(bool needRemove) {
    if (needRemove) {
      dispose();
    }
    return needRemove;
  }

  void dispose() {
    paragraph?.dispose();
    paragraph = null;
    clearStrokeParagraph();
  }

  void clearStrokeParagraph() {
    strokeParagraph?.dispose();
    strokeParagraph = null;
  }

  DanmakuItem({
    required this.content,
    required this.height,
    required this.width,
    this.xPosition = 0,
    this.yPosition = 0,
    this.paragraph,
    this.strokeParagraph,
    this.drawTick,
  });

  void generateParagraphIfNeeded(double fontSize, int fontWeight) {
    if (paragraph == null) {
      final paragraph = DmUtils.generateParagraph(
        content: content,
        fontSize: fontSize,
        fontWeight: fontWeight,
      );
      this.paragraph = paragraph;
      width = paragraph.maxIntrinsicWidth;
      height = paragraph.height;
    }
  }

  @override
  String toString() {
    return 'DanmakuItem(content=$content, xPos=$xPosition, yPos=$yPosition, size=${ui.Size(width, height)}, drawTick=$drawTick)';
  }
}
