import 'dart:ui' as ui;
import '/models/danmaku_content_item.dart';

class DanmakuItem {
  final DanmakuContentItem content;
  final int creationTime;
  final double width;
  double xPosition;
  double yPosition;

  ui.Paragraph? paragraph;
  ui.Paragraph? strokeParagraph;

  DanmakuItem({
    required this.content,
    required this.creationTime,
    required this.width,
    this.xPosition = 0,
    this.yPosition = 0,
    this.paragraph,
    this.strokeParagraph,
  });
}
