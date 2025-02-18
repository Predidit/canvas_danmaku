import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '/models/danmaku_content_item.dart';

class Utils {
  static Future<ui.Image> generateParagraphImage(
      DanmakuContentItem content,
      double danmakuWidth,
      double fontSize,
      int fontWeight,
      double devicePixelRatio,
      bool showStroke) async {
    // 用逻辑像素计算文本的布局（不受设备像素比缩放影响）
    final ui.ParagraphBuilder fillBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontSize: fontSize,
        fontWeight: FontWeight.values[fontWeight],
        textDirection: TextDirection.ltr,
      ),
    )
      ..pushStyle(ui.TextStyle(
        color: content.color,
      ))
      ..addText(content.text);
    final ui.Paragraph fillParagraph = fillBuilder.build()
      ..layout(ui.ParagraphConstraints(width: danmakuWidth));

    // 根据逻辑尺寸计算最终图像尺寸（物理像素）
    final int imageWidth = (danmakuWidth * devicePixelRatio).ceil();
    final int imageHeight = (fillParagraph.height * devicePixelRatio).ceil();

    // 创建 PictureRecorder 和 Canvas，并将 Canvas 按照 devicePixelRatio 进行缩放
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.scale(devicePixelRatio);

    // 如果需要描边，则先绘制描边文本
    if (showStroke) {
      final Paint strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.black;
      final ui.ParagraphBuilder strokeBuilder = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          textAlign: TextAlign.left,
          fontSize: fontSize,
          fontWeight: FontWeight.values[fontWeight],
          textDirection: TextDirection.ltr,
        ),
      )
        ..pushStyle(ui.TextStyle(
          foreground: strokePaint,
        ))
        ..addText(content.text);
      final ui.Paragraph strokeParagraph = strokeBuilder.build()
        ..layout(ui.ParagraphConstraints(width: danmakuWidth));
      canvas.drawParagraph(strokeParagraph, Offset.zero);
    }
    canvas.drawParagraph(fillParagraph, Offset.zero);

    // 将绘制内容转换为图像（此处传入的尺寸为物理像素）
    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(imageWidth, imageHeight);
    return image;
  }
}
