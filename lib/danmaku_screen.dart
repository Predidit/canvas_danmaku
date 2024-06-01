import 'package:canvas_danmaku/utils/utils.dart';
import 'package:flutter/material.dart';
import 'models/danmaku_item.dart';
import 'scroll_danmaku_painter.dart';
import 'static_danmaku_painter.dart';
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
  // 弹幕控制器
  late AnimationController _animationController;
  DanmakuOption _option = DanmakuOption();
  // 滚动弹幕
  final List<DanmakuItem> _scrollDanmakuItems = [];
  // 顶部弹幕
  final List<DanmakuItem> _topDanmakuItems = [];
  // 底部弹幕
  final List<DanmakuItem> _bottomDanmakuItems = [];
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
      if (content.type == DanmakuItemType.scroll) {
        bool scrollCanAddToTrack =
            _scrollCanAddToTrack(yPosition, danmakuWidth);

        if (scrollCanAddToTrack) {
          _scrollDanmakuItems.add(DanmakuItem(
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

      if (content.type == DanmakuItemType.top) {
        bool topCanAddToTrack = _topCanAddToTrack(yPosition);

        if (topCanAddToTrack) {
          _topDanmakuItems.add(DanmakuItem(
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

      if (content.type == DanmakuItemType.bottom) {
        bool bottomCanAddToTrack = _bottomCanAddToTrack(yPosition);

        if (bottomCanAddToTrack) {
          _bottomDanmakuItems.add(DanmakuItem(
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
    }

    if ((_scrollDanmakuItems.isNotEmpty ||
            _topDanmakuItems.isNotEmpty ||
            _bottomDanmakuItems.isNotEmpty) &&
        !_animationController.isAnimating) {
      _animationController.repeat();
    }
    // 移除屏幕外滚动弹幕
    _scrollDanmakuItems.removeWhere((item) => item.xPosition + item.width < 0);
    // 移除顶部弹幕
    _topDanmakuItems.removeWhere(
        (item) => ((_tick - item.creationTime) > (_option.duration * 1000)));
    // 移除底部弹幕
    _bottomDanmakuItems.removeWhere(
        (item) => ((_tick - item.creationTime) > (_option.duration * 1000)));
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
    for (DanmakuItem item in _scrollDanmakuItems) {
      if (item.paragraph != null) {
        item.paragraph = null;
      }
      if (item.strokeParagraph != null) {
        item.strokeParagraph = null;
      }
    }
    for (DanmakuItem item in _topDanmakuItems) {
      if (item.paragraph != null) {
        item.paragraph = null;
      }
      if (item.strokeParagraph != null) {
        item.strokeParagraph = null;
      }
    }
    for (DanmakuItem item in _bottomDanmakuItems) {
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
      _scrollDanmakuItems.clear();
      _topDanmakuItems.clear();
      _bottomDanmakuItems.clear();
    });
    _animationController.stop();
  }

  /// 确定滚动弹幕是否可以添加
  bool _scrollCanAddToTrack(double yPosition, double newDanmakuWidth) {
    for (var item in _scrollDanmakuItems) {
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

  /// 确定顶部弹幕是否可以添加
  bool _topCanAddToTrack(double yPosition) {
    for (var item in _topDanmakuItems) {
      if (item.yPosition == yPosition) {
        return false;
      }
    }
    return true;
  }

  /// 确定底部弹幕是否可以添加
  bool _bottomCanAddToTrack(double yPosition) {
    for (var item in _bottomDanmakuItems) {
      if (item.yPosition == yPosition) {
        return false;
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
      return Opacity(
        opacity: _option.opacity,
        child: Stack(children: [
          RepaintBoundary(
              child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return CustomPaint(
                painter: ScrollDanmakuPainter(
                    _animationController.value,
                    _scrollDanmakuItems,
                    _option.duration,
                    _option.fontSize,
                    _option.showStroke,
                    _danmakuHeight,
                    _running,
                    _tick),
                child: Container(),
              );
            },
          )),
          RepaintBoundary(
              child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return CustomPaint(
                painter: StaticDanmakuPainter(
                    _animationController.value,
                    _topDanmakuItems,
                    _bottomDanmakuItems,
                    _option.duration,
                    _option.fontSize,
                    _option.showStroke,
                    _danmakuHeight,
                    _running,
                    _tick),
                child: Container(),
              );
            },
          )),
        ]),
      );
    });
  }
}
