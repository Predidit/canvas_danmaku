import 'package:flutter/material.dart';
import 'models/danmaku_item.dart';
import 'danmaku_painter.dart';
import 'danmaku_controller.dart';
import 'dart:ui' as ui;
import 'models/danmaku_option.dart';

class DanmakuScreen extends StatefulWidget {
  // 创建Screen后返回控制器
  final Function(DanmakuController) createdController;
  final DanmakuOption option;
  const DanmakuScreen({
    required this.createdController,
    required this.option,
    Key? key,
  }) : super(key: key);

  @override
  State<DanmakuScreen> createState() => _DanmakuScreenState();
}

class _DanmakuScreenState extends State<DanmakuScreen>
    with SingleTickerProviderStateMixin {
  late DanmakuController _controller;
  late AnimationController _animationController;
  DanmakuOption _option = DanmakuOption();
  final List<DanmakuItem> _danmakuItems = [];
  late double _danmakuHeight;
  late int _trackCount;
  final List<double> _trackYPositions = [];
  bool _running = true;

  @override
  void initState() {
    super.initState();
    _option = widget.option;
    final textPainter = TextPainter(
      text: TextSpan(text: '弹幕', style: TextStyle(fontSize: _option.fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    _danmakuHeight = textPainter.height;
    _controller = DanmakuController(
      onAddItems: addDanmaku,
      onPause: pauseResumeDanmakus,
      onResume: pauseResumeDanmakus,
      onClear: clearDanmakus,
    );
    _controller.option = _option;
    widget.createdController.call(
      _controller,
    );

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _option.duration),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {});
  }

  void addDanmaku([String content = '弹幕']) {
    if (!_running) {
      return;
    }
    final textPainter = TextPainter(
      text:
          TextSpan(text: content, style: TextStyle(fontSize: _option.fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();

    final danmakuWidth = textPainter.width;
    final creationTime = DateTime.now();

    final ui.ParagraphBuilder builder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.left,
      fontSize: _option.fontSize,
      textDirection: TextDirection.ltr,
    ))
      ..pushStyle(ui.TextStyle(
        color: Colors.white,
      ))
      ..addText(content);

    final ui.Paragraph paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: danmakuWidth));

    ui.Paragraph? strokeParagraph;
    if (_option.showStroke) {
      final Paint strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.black;

      final ui.ParagraphBuilder strokeBuilder =
          ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontSize: _option.fontSize,
        textDirection: TextDirection.ltr,
      ))
            ..pushStyle(ui.TextStyle(
              foreground: strokePaint,
            ))
            ..addText(content);

      strokeParagraph = strokeBuilder.build()
        ..layout(ui.ParagraphConstraints(width: danmakuWidth));
    }

    for (double yPosition in _trackYPositions) {
      bool canAddToTrack = _canAddToTrack(yPosition, danmakuWidth);

      if (canAddToTrack) {
        _danmakuItems.add(DanmakuItem(
            yPosition: yPosition,
            xPosition: MediaQuery.of(context).size.width,
            width: danmakuWidth,
            creationTime: creationTime,
            content: content,
            paragraph: paragraph,
            strokeParagraph: strokeParagraph));
        break;
      }
    }

    if (_danmakuItems.isNotEmpty && !_animationController.isAnimating) {
      _animationController.repeat();
    }

    _danmakuItems.removeWhere((item) => item.xPosition + item.width < 0);
  }

  void pauseResumeDanmakus() {
    setState(() {
      _running = !_running;
    });

    /// 弃用 此方法会导致恢复后动画无法正常刷新
    // if (_animationController.isAnimating) {
    //   _animationController.stop(canceled: false);
    // } else {
    //   _animationController.forward(from: _animationController.value);
    // }
  }

  void clearDanmakus() {
    setState(() {
      _danmakuItems.clear();
    });
    _animationController.stop();
  }

  bool _canAddToTrack(double yPosition, double newDanmakuWidth) {
    for (var item in _danmakuItems) {
      if (item.yPosition == yPosition) {
        final existingEndPosition = item.xPosition + item.width;
        if (MediaQuery.of(context).size.width - existingEndPosition <
            newDanmakuWidth) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      // 为字幕留出余量
      _trackCount = (constraints.maxHeight / _danmakuHeight).floor() - 1;

      _trackYPositions.clear();
      for (int i = 0; i < _trackCount; i++) {
        _trackYPositions.add(i * _danmakuHeight);
      }
      return RepaintBoundary(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return CustomPaint(
              painter: DanmakuPainter(
                  _animationController.value,
                  _danmakuItems,
                  _option.duration,
                  _option.fontSize,
                  _option.showStroke,
                  _running),
              child: Container(),
            );
          },
        ),
      );
    });
  }
}
