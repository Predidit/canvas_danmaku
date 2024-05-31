import 'dart:ui' as ui;

class DanmakuItem {
  final String content;
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
