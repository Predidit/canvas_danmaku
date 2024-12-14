import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '/models/danmaku_content_item.dart';

class Utils {
  static generateParagraph({
    required DanmakuContentItem content,
    required double danmakuWidth,
    required double fontSize,
    required int fontWeight,
    required double opacity,
  }) {
    final ui.ParagraphBuilder builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontSize: fontSize,
        fontWeight: FontWeight.values[fontWeight],
        textDirection: TextDirection.ltr,
      ),
    )
      ..pushStyle(
        ui.TextStyle(color: content.color.withOpacity(opacity)),
      )
      ..addText(content.text);
    return builder.build()
      ..layout(ui.ParagraphConstraints(width: danmakuWidth));
  }

  static generateStrokeParagraph({
    required DanmakuContentItem content,
    required double danmakuWidth,
    required double fontSize,
    required int fontWeight,
    required double strokeWidth,
    required double opacity,
  }) {
    final Paint strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = Colors.black.withOpacity(opacity);

    final ui.ParagraphBuilder strokeBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontSize: fontSize,
        fontWeight: FontWeight.values[fontWeight],
        textDirection: TextDirection.ltr,
      ),
    )
      ..pushStyle(
        ui.TextStyle(foreground: strokePaint),
      )
      ..addText(content.text);

    return strokeBuilder.build()
      ..layout(ui.ParagraphConstraints(width: danmakuWidth));
  }
}
