import 'dart:math';
import 'dart:ui' as ui;

import 'package:canvas_danmaku/models/danmaku_content_item.dart';
import 'package:flutter/material.dart';

abstract class DmUtils {
  static final Random random = Random();

  static String generateRandomString(int length) {
    const characters = '0123456789abcdefghijklmnopqrstuvwxyz';

    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => characters.codeUnitAt(random.nextInt(characters.length)),
      ),
    );
  }

  static ui.Paragraph generateParagraph({
    required DanmakuContentItem content,
    required double fontSize,
    required int fontWeight,
  }) {
    final ui.ParagraphBuilder builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontWeight: FontWeight.values[fontWeight],
        textDirection: TextDirection.ltr,
        maxLines: 1,
      ),
    );

    if (content.count case final count?) {
      builder
        ..pushStyle(
          ui.TextStyle(
            color: content.color,
            fontSize: fontSize * 0.6,
          ),
        )
        ..addText('($count)')
        ..pop();
    }

    builder
      ..pushStyle(ui.TextStyle(color: content.color, fontSize: fontSize))
      ..addText(content.text);

    return builder.build()
      ..layout(const ui.ParagraphConstraints(width: double.infinity));
  }

  static ui.Paragraph generateStrokeParagraph({
    required DanmakuContentItem content,
    required double fontSize,
    required int fontWeight,
    required double strokeWidth,
    Size? size,
  }) {
    final Paint strokePaint = Paint()
      ..shader = content.isColorful && size != null
          ? const LinearGradient(colors: [Color(0xFFF2509E), Color(0xFF308BCD)])
              .createShader(Rect.fromLTWH(0, 0, size.width, size.height))
          : null
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    if (!content.isColorful) {
      strokePaint.color = Colors.black;
    }

    final ui.ParagraphBuilder strokeBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontWeight: FontWeight.values[fontWeight],
        textDirection: TextDirection.ltr,
        maxLines: 1,
      ),
    );

    if (content.count case final count?) {
      strokeBuilder
        ..pushStyle(
          ui.TextStyle(fontSize: fontSize * 0.6, foreground: strokePaint),
        )
        ..addText('($count)')
        ..pop();
    }

    strokeBuilder
      ..pushStyle(ui.TextStyle(fontSize: fontSize, foreground: strokePaint))
      ..addText(content.text);

    return strokeBuilder.build()
      ..layout(const ui.ParagraphConstraints(width: double.infinity));
  }
}
