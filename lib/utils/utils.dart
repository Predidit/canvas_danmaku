import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '/models/danmaku_content_item.dart';

class Utils {
  static TextPainter getCountPainter({
    required bool isStroke,
    required DanmakuContentItem content,
    required double fontSize,
    required int fontWeight,
    required double strokeWidth,
  }) {
    late final Paint paint = Paint()
      ..style = ui.PaintingStyle.stroke
      ..color = Colors.black
      ..strokeWidth = strokeWidth;
    final textPainter = TextPainter(
      text: TextSpan(
        text: '(${content.count})',
        style: TextStyle(
          fontSize: fontSize * 0.6,
          color: isStroke ? null : content.color,
          fontWeight: FontWeight.values[fontWeight],
          foreground: isStroke ? paint : null,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return textPainter;
  }

  static generateParagraph({
    required DanmakuContentItem content,
    required double danmakuWidth,
    required double fontSize,
    required int fontWeight,
    Size? size,
    Size? screenSize,
    // required double opacity,
  }) {
    final ui.ParagraphBuilder builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontSize: fontSize,
        fontWeight: FontWeight.values[fontWeight],
        textDirection: TextDirection.ltr,
        maxLines: 1,
      ),
    )
      ..pushStyle(
        ui.TextStyle(color: content.color),
      )
      ..addText(content.text);
    return builder.build()
      ..layout(ui.ParagraphConstraints(
          width: content.isColorful == true && size!.width > screenSize!.width
              ? double.infinity
              : danmakuWidth));
  }

  static generateStrokeParagraph({
    required DanmakuContentItem content,
    required double danmakuWidth,
    required double fontSize,
    required int fontWeight,
    required double strokeWidth,
    Size? size,
    Offset? offset,
    Size? screenSize,
    // required double opacity,
  }) {
    final Paint strokePaint = Paint()
      ..shader = content.isColorful == true && offset != null && size != null
          ? const LinearGradient(
              colors: [Color(0xFFFF6699), Colors.blue],
            ).createShader(
              Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height),
            )
          : null
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    if (content.isColorful != true) {
      strokePaint.color = Colors.black;
    }

    final ui.ParagraphBuilder strokeBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontSize: fontSize,
        fontWeight: FontWeight.values[fontWeight],
        textDirection: TextDirection.ltr,
        maxLines: 1,
      ),
    )
      ..pushStyle(
        ui.TextStyle(foreground: strokePaint),
      )
      ..addText(content.text);

    return strokeBuilder.build()
      ..layout(ui.ParagraphConstraints(
          width: content.isColorful == true && size!.width > screenSize!.width
              ? double.infinity
              : danmakuWidth));
  }
}
