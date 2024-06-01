import 'package:canvas_danmaku/utils/utils.dart';
import 'package:flutter/material.dart';
import 'models/danmaku_item.dart';
import 'danmaku_painter.dart';
import 'danmaku_controller.dart';
import 'dart:ui' as ui;
import 'models/danmaku_option.dart';
import '/models/danmaku_content_item.dart';

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
  // 内部计时器
  late int _tick;
  bool _running = true;

  @override
  void initState() {
    super.initState();
    // 计时器初始化
    _tick = 0;
    _startTick();
    _option = widget.option;
    final textPainter = TextPainter(
      text: TextSpan(text: '弹幕', style: TextStyle(fontSize: _option.fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    _danmakuHeight = textPainter.height;
    _controller = DanmakuController(
      onAddDanmaku: addDanmaku,
      onUpdateOption: updateOption,
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

  /// 添加弹幕
  void addDanmaku(DanmakuContentItem content) {
    if (!_running) {
      return;
    }
    // 在这里提前创建 Paragraph 缓存防止卡顿
    final textPainter = TextPainter(
      text: TextSpan(
          text: content.text, style: TextStyle(fontSize: _option.fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    final danmakuWidth = textPainter.width;

    final ui.Paragraph paragraph =
        Utils.generateParagraph(content, danmakuWidth, _option.fontSize);

    ui.Paragraph? strokeParagraph;
    if (_option.showStroke) {
      strokeParagraph = Utils.generateStrokeParagraph(
          content, danmakuWidth, _option.fontSize);
    }

    for (double yPosition in _trackYPositions) {
      bool canAddToTrack = _canAddToTrack(yPosition, danmakuWidth);

      if (canAddToTrack) {
        _danmakuItems.add(DanmakuItem(
            yPosition: yPosition,
            xPosition: MediaQuery.of(context).size.width,
            width: danmakuWidth,
            creationTime: _tick,
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
    if (_running) {
      // 重启计时器
      _startTick();
    }

    if (_animationController.isAnimating) {
      _animationController.stop();
    } else {
      _animationController.repeat();
    }
  }

  /// 更新弹幕设置
  void updateOption(DanmakuOption option) {
    _option = option;
    _controller.option = _option;

    /// 清理已经存在的 Paragraph 缓存
    _animationController.stop();
    for (DanmakuItem item in _danmakuItems) {
      if (item.paragraph != null) {
        item.paragraph = null;
      }
      if (item.strokeParagraph != null) {
        item.strokeParagraph = null;
      }
    }
    _animationController.repeat();
    setState(() {});
  }

  /// 清空弹幕
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

  // 基于Stopwatch的计时器同步
  void _startTick() async {
    final stopwatch = Stopwatch()..start();
    int lastElapsedTime = 0;

    while (_running) {
      await Future.delayed(const Duration(milliseconds: 1));
      int currentElapsedTime = stopwatch.elapsedMilliseconds; // 获取当前的已用时间
      int delta = currentElapsedTime - lastElapsedTime; // 计算自上次记录以来的时间差
      _tick += delta;
      lastElapsedTime = currentElapsedTime; // 更新最后记录的时间
    }

    stopwatch.stop();
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
        child: Opacity(
          opacity: _option.opacity,
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
                    _running,
                    _tick),
                child: Container(),
              );
            },
          ),
        ),
      );
    });
  }
}
