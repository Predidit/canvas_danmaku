import 'package:flutter/material.dart';
import 'models/danmaku_item.dart';
import 'danmaku_painter.dart';
import 'danmaku_controller.dart';
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
  List<DanmakuItem> _danmakuItems = [];
  late double _danmakuHeight;
  late int _trackCount;
  final List<double> _trackYPositions = [];

  @override
  void initState() {
    super.initState();

    _option = widget.option;
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final textPainter = TextPainter(
        text: TextSpan(text: '弹幕', style: TextStyle(fontSize: _option.fontSize)),
        textDirection: TextDirection.ltr,
      )..layout();
      _danmakuHeight = textPainter.height;
      _trackCount =
          (MediaQuery.of(context).size.height / _danmakuHeight).floor();

      for (int i = 0; i < _trackCount; i++) {
        _trackYPositions.add(i * _danmakuHeight);
      }
    });
  }

  void addDanmaku([String content = '弹幕']) {
    final textPainter = TextPainter(
      text: TextSpan(text: content, style: TextStyle(fontSize: _option.fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();

    final danmakuWidth = textPainter.width;
    final creationTime = DateTime.now();

    bool isAdded = false;

    for (double yPosition in _trackYPositions) {
      bool canAddToTrack = _canAddToTrack(yPosition, danmakuWidth);

      if (canAddToTrack) {
        _danmakuItems.add(DanmakuItem(
            yPosition,
            MediaQuery.of(context).size.width,
            danmakuWidth,
            creationTime,
            content));
        isAdded = true;
        break;
      }
    }

    if (!isAdded && _danmakuItems.isNotEmpty) {
      _danmakuItems.sort((a, b) => a.yPosition.compareTo(b.yPosition));
      _danmakuItems.add(DanmakuItem(
          _trackYPositions.last + _danmakuHeight,
          MediaQuery.of(context).size.width,
          danmakuWidth,
          creationTime,
          content));
    }

    _danmakuItems.removeWhere((item) => item.xPosition + item.width < 0);
  }

  void pauseResumeDanmakus() {
    if (_animationController.isAnimating) {
      _animationController.stop();
    } else {
      _animationController.repeat();
    }
  }

  void clearDanmakus() {
    setState(() {
      _danmakuItems.clear();
    });
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
    return Stack(
      children: [
        RepaintBoundary(
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
                ),
                child: Container(),
              );
            },
          ),
        ),
      ],
    );
  }
}
