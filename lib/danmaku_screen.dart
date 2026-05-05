import 'dart:math';

import 'package:canvas_danmaku/danmaku_controller.dart';
import 'package:canvas_danmaku/models/danmaku_content_item.dart';
import 'package:canvas_danmaku/models/danmaku_item.dart';
import 'package:canvas_danmaku/models/danmaku_option.dart';
import 'package:canvas_danmaku/scroll_danmaku_painter.dart';
import 'package:canvas_danmaku/special_danmaku_painter.dart';
import 'package:canvas_danmaku/static_danmaku_painter.dart';
import 'package:canvas_danmaku/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class DanmakuScreen<T> extends StatefulWidget {
  // 创建Screen后返回控制器
  final ValueChanged<DanmakuController<T>> createdController;
  final DanmakuOption option;
  final Size size;

  const DanmakuScreen({
    super.key,
    required this.createdController,
    required this.option,
    required this.size,
  });

  @override
  State<DanmakuScreen<T>> createState() => _DanmakuScreenState<T>();
}

class _DanmakuScreenState<T> extends State<DanmakuScreen<T>>
    with SingleTickerProviderStateMixin {
  /// 视图宽度
  double _viewWidth = 0;
  double _viewHeight = 0;
  double devicePixelRatio = 1;

  /// 弹幕配置
  late DanmakuOption _option;

  /// 滚动弹幕
  final _scrollDanmakuItems = <List<DanmakuItem<T>>>[];

  /// 静态弹幕
  final _staticDanmakuItems = ListValueNotifier(<DanmakuItem<T>?>[]);

  /// 高级弹幕
  final _specialDanmakuItems = <DanmakuItem<T>>[];

  /// 弹幕高度
  double _danmakuHeight = 0;

  /// 弹幕轨道数
  int _trackCount = 0;

  /// 滚动弹幕速度或时间，负号表示速度
  double _scrollVelocityOrDuration = 0;

  late final _random = Random();

  late final Ticker _ticker;
  late final ValueNotifier<int> _notifier;
  late int _lastTick = 0;

  /// 运行状态
  bool _running = true;

  @override
  void initState() {
    super.initState();
    _option = widget.option;
    if (!_option.scrollFixedVelocity) {
      _scrollVelocityOrDuration = _option.durationInMilliseconds;
    }
    DmUtils.updateSelfSendPaint(_option.strokeWidth);

    _danmakuHeight = _textPainter.height;

    _ticker = createTicker(_tick);
    _notifier = ValueNotifier(0);

    widget.createdController(DanmakuController<T>(
      addDanmaku: _addDanmaku,
      updateOption: _updateOption,
      pause: _pause,
      resume: _resume,
      clear: _clear,
      getOption: () => _option,
      isRunning: () => _running,
      findDanmaku: findDanmaku,
      findSingleDanmaku: findSingleDanmaku,
      getTrackCount: () => _trackCount,
      scrollDanmaku: _scrollDanmakuItems,
      staticDanmaku: _staticDanmakuItems.value,
      specialDanmaku: _specialDanmakuItems,
    ));

    _init(widget.size);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    DmUtils.devicePixelRatio = devicePixelRatio;
    if (devicePixelRatio > this.devicePixelRatio) {
      for (var i in _scrollDanmakuItems) {
        for (var e in i) {
          e.dispose();
        }
      }
      for (var e in _staticDanmakuItems.value) {
        e?.dispose();
      }
      for (var item in _specialDanmakuItems) {
        item.dispose();
      }
      this.devicePixelRatio = devicePixelRatio;
    }
  }

  int _time = 0;
  void _tick(Duration elapsed) {
    _notifier.value = elapsed.inMilliseconds + _lastTick;
    if (_time++ > 10) {
      _time = 0;
      _lazyTick(_notifier.value);
    }
  }

  TextPainter get _textPainter => TextPainter(
        text: TextSpan(
          text: '弹幕',
          style: TextStyle(
            fontSize: _option.fontSize,
            height: _option.lineHeight,
            fontFamily: _option.fontFamily,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

  @override
  void dispose() {
    _running = false;
    _ticker.dispose();
    _clearDanmakus();
    _staticDanmakuItems.dispose();
    super.dispose();
  }

  bool _handleNormalDanmaku(
    DanmakuContentItem<T> content,
    bool Function(int, double) canAdd, {
    bool scroll = false,
  }) {
    bool added = false;

    final paragraph = DmUtils.generateParagraph(
      content: content,
      fontSize: _option.fontSize,
      fontWeight: _option.fontWeight,
      fontFamily: _option.fontFamily,
    );

    final danmakuWidth = (content.selfSend
            ? paragraph.maxIntrinsicWidth + 4
            : paragraph.maxIntrinsicWidth) +
        _option.strokeWidth;
    final danmakuHeight = paragraph.height + _option.strokeWidth;

    if (!scroll &&
        content.type != DanmakuItemType.scroll &&
        _option.static2Scroll &&
        danmakuWidth > _viewWidth) {
      return false;
    }

    DanmakuItem<T> getItem() => DanmakuItem<T>(
        xPosition: _viewWidth,
        width: danmakuWidth,
        height: danmakuHeight,
        content: content,
        image: DmUtils.recordDanmakuImage(
          contentParagraph: paragraph,
          content: content,
          fontSize: _option.fontSize,
          fontWeight: _option.fontWeight,
          strokeWidth: _option.strokeWidth,
          fontFamily: _option.fontFamily,
        ));

    for (var i = 0; i < _trackCount; i++) {
      final index =
          content.type == DanmakuItemType.bottom ? _trackCount - 1 - i : i;

      if (added = canAdd(index, danmakuWidth)) {
        final item = getItem();
        if (content.type == DanmakuItemType.scroll || scroll) {
          _scrollDanmakuItems[index].add(item);
        } else {
          _staticDanmakuItems.value[index] = item;
          if (_running) {
            _staticDanmakuItems.refresh();
          }
        }
        break;
      }
    }

    if (added) {
      if (_running && !_ticker.isActive) {
        _ticker.start();
      }
    } else {
      if (content.selfSend) {
        _scrollDanmakuItems[0].add(getItem());
        added = true;
      } else if ((content.type == DanmakuItemType.scroll || scroll) &&
          _option.massiveMode) {
        _scrollDanmakuItems[_random.nextInt(_trackCount)].add(getItem());
        added = true;
      }
    }

    paragraph.dispose();
    return added;
  }

  /// 添加弹幕
  bool _addDanmaku(DanmakuContentItem<T> content) {
    if (!mounted) {
      return false;
    }

    bool added;
    switch (content.type) {
      case DanmakuItemType.scroll:
        if (_option.hideScroll) return false;
        added = _handleNormalDanmaku(content, _scrollCanAddToTrack);
        break;
      case DanmakuItemType.top:
      case DanmakuItemType.bottom:
        if (_option.hideWhat(content.type)) return false;
        added = _handleNormalDanmaku(content, _staticCanAddToTrack);
        if (!added && _option.static2Scroll && !_option.hideScroll) {
          added =
              _handleNormalDanmaku(content, _scrollCanAddToTrack, scroll: true);
        }
        break;
      case DanmakuItemType.special:
        if (_option.hideSpecial) return false;
        added = true;
        _specialDanmakuItems.add(
          DanmakuItem<T>(
              width: 0,
              height: 0,
              content: content,
              image: DmUtils.recordSpecialDanmakuImg(
                content: content as SpecialDanmakuContentItem,
                fontWeight: _option.fontWeight,
                strokeWidth: _option.strokeWidth,
                fontFamily: _option.fontFamily,
              )),
        );
        if (_running && !_ticker.isActive) {
          _ticker.start();
        }
        break;
    }
    return added;
  }

  /// 暂停
  void _pause() {
    if (!mounted) return;
    _running = false;
    if (_ticker.isActive) {
      _lastTick = _notifier.value;
      _ticker.stop();
    }
  }

  /// 恢复
  void _resume() {
    if (!mounted) return;
    _running = true;
    if (!_ticker.isActive) {
      _ticker.start();
    }
    _staticDanmakuItems.refresh();
  }

  /// 清空弹幕
  void _clear() {
    if (!mounted) return;
    _clearDanmakus();
    if (_ticker.isActive) {
      // SchedulerBinding.instance.addPostFrameCallback(
      //   (_) => _ticker.stop(),
      // );
    } else {
      _notifier.refresh();
    }
  }

  /// 更新弹幕设置
  void _updateOption(DanmakuOption option) {
    if (option.durationInMilliseconds != _option.durationInMilliseconds ||
        option.scrollFixedVelocity != _option.scrollFixedVelocity) {
      _scrollVelocityOrDuration = option.scrollFixedVelocity
          ? -_viewWidth / option.durationInMilliseconds
          : option.durationInMilliseconds;
    }

    final lineHeightChanged = option.lineHeight != _option.lineHeight;
    if (lineHeightChanged) {
      _option = option;
      _danmakuHeight = _textPainter.height;
      _calcTracks();
      return;
    }

    final fontSizeChanged = option.fontSize != _option.fontSize;
    final fontFamilyChanged = option.fontFamily != _option.fontFamily;

    final clearScroll = option.hideScroll && !_option.hideScroll;

    final clearParagraph = fontSizeChanged ||
        fontFamilyChanged ||
        option.fontWeight != _option.fontWeight ||
        option.strokeWidth != _option.strokeWidth;

    final needRestart = _ticker.isActive && clearScroll && clearParagraph;
    if (needRestart) {
      _lastTick = _notifier.value;
      _ticker.stop();
    }

    /// 需要隐藏弹幕时清理已有弹幕
    if (clearScroll) {
      for (var i in _scrollDanmakuItems) {
        for (var e in i) {
          e.dispose();
        }
        i.clear();
      }
    }

    final clearTop = option.hideTop && !_option.hideTop;
    final clearBottom = option.hideBottom && !_option.hideBottom;
    if (clearTop || clearBottom) {
      _staticDanmakuItems.removeWhere((e) => e.needRemove(
            (clearTop && e.content.type == DanmakuItemType.top) ||
                (clearBottom && e.content.type == DanmakuItemType.bottom),
          ));
    }
    if (option.hideSpecial && !_option.hideSpecial) {
      for (var e in _specialDanmakuItems) {
        e.dispose();
      }
      _specialDanmakuItems.clear();
    }

    /// 清理已经存在的 Paragraph 缓存
    if (clearParagraph) {
      DmUtils.updateSelfSendPaint(_option.strokeWidth);
      for (var i in _scrollDanmakuItems) {
        for (var e in i) {
          e.dispose();
        }
      }
      for (var e in _staticDanmakuItems.value) {
        e?.dispose();
      }
      for (var item in _specialDanmakuItems) {
        item.dispose();
      }
    }

    final areaChanged = option.area != _option.area;
    final safeAreaChanged = option.safeArea != _option.safeArea;
    _option = option;
    if (fontSizeChanged) {
      _danmakuHeight = _textPainter.height;
    }
    if (fontSizeChanged || areaChanged || safeAreaChanged) {
      _calcTracks();
    }

    if (needRestart) {
      _ticker.start();
    } else {
      _notifier.refresh();
      _staticDanmakuItems.refresh();
    }
  }

  void _clearDanmakus() {
    for (var i in _scrollDanmakuItems) {
      for (var e in i) {
        e.dispose();
      }
      i.clear();
    }
    for (int i = 0; i < _trackCount; i++) {
      final item = _staticDanmakuItems[i];
      if (item != null) {
        item.dispose();
        _staticDanmakuItems[i] = null;
      }
    }
    _staticDanmakuItems.refresh();
    for (var e in _specialDanmakuItems) {
      e.dispose();
    }
    _specialDanmakuItems.clear();
  }

  /// 确定滚动弹幕是否可以添加
  bool _scrollCanAddToTrack(int index, double newDanmakuWidth) {
    final item = _scrollDanmakuItems[index].lastOrNull;
    if (item == null) return true;
    // 首先保证进入屏幕时不发生重叠
    final right = item.xPosition + item.width;
    if (_viewWidth < right) {
      return false;
    }
    // 其次保证知道移出屏幕前不与速度慢的弹幕(弹幕宽度较小)发生重叠
    if (!_option.scrollFixedVelocity && item.width < newDanmakuWidth) {
      // (1 - ((_viewWidth - item.xPosition) / (item.width + _viewWidth))) > ((_viewWidth) / (_viewWidth + newDanmakuWidth))
      if (right * newDanmakuWidth >
          _viewWidth * (_viewWidth - item.xPosition)) {
        return false;
      }
    }
    return true;
  }

  /// 确定静态弹幕是否可以添加
  bool _staticCanAddToTrack(int index, double _) {
    return _staticDanmakuItems[index] == null;
  }

  @pragma("vm:prefer-inline")
  void _lazyTick(int tick) {
    // 移除屏幕外滚动弹幕
    for (var i in _scrollDanmakuItems) {
      i.removeWhereUnsafe((item) => item.needRemove(item.expired));
    }
    // 移除静态弹幕
    _staticDanmakuItems.removeWhere((item) => item.needRemove(!item.suspend &&
        item.drawTick != null &&
        (tick - item.drawTick!) >= _option.staticDurationInMilliseconds));
    // 移除高级弹幕
    _specialDanmakuItems
        .removeWhereUnsafe((item) => item.needRemove(item.expired));
    // 暂停动画
    if (_scrollDanmakuItems.isEmpty &&
        _specialDanmakuItems.isEmpty &&
        _staticDanmakuItems.value.nonNulls.isEmpty &&
        _ticker.isActive) {
      _lastTick = tick;
      _ticker.stop();
    }
  }

  void _calcTracks() {
    final area = _viewHeight * _option.area;
    int newTrackCount = area ~/ _danmakuHeight;

    /// 为字幕留出余量
    if (_option.safeArea && _option.area == 1.0) {
      newTrackCount--;
    }
    if (newTrackCount != _trackCount) {
      // 丢弃超出屏幕范围的弹幕
      _staticDanmakuItems.value.length = newTrackCount;
      _scrollDanmakuItems.changeLength(newTrackCount);
      _trackCount = newTrackCount;
    }
  }

  @override
  void didUpdateWidget(DanmakuScreen<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.size != widget.size) {
      _init(widget.size);
    }
  }

  void _init(Size size) {
    final viewWidth = size.width;
    final viewHeight = size.height;
    if (_viewWidth != viewWidth) {
      _viewWidth = viewWidth;
      if (_option.scrollFixedVelocity) {
        _scrollVelocityOrDuration =
            -_viewWidth / _option.durationInMilliseconds;
      }
    }
    if (_viewHeight != viewHeight) {
      _viewHeight = viewHeight;
      _calcTracks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: _option.opacity,
        child: Stack(
          children: [
            RepaintBoundary.wrap(
              ValueListenableBuilder(
                valueListenable: _notifier,
                builder: (context, value, child) {
                  return CustomPaint(
                    willChange: _running,
                    painter: ScrollDanmakuPainter(
                      length: _scrollDanmakuItems.fold<int>(
                          0, (p, n) => p + n.length),
                      trackHeight: _danmakuHeight,
                      danmakuItems: _scrollDanmakuItems,
                      durationInMilliseconds: _scrollVelocityOrDuration,
                      fontSize: _option.fontSize,
                      fontWeight: _option.fontWeight,
                      strokeWidth: _option.strokeWidth,
                      running: _running,
                      tick: value,
                    ),
                    size: widget.size,
                  );
                },
              ),
              0,
            ),
            RepaintBoundary.wrap(
              ValueListenableBuilder(
                valueListenable: _staticDanmakuItems,
                builder: (context, value, child) {
                  return CustomPaint(
                    painter: StaticDanmakuPainter(
                      count: value.nonNulls.length,
                      trackHeight: _danmakuHeight,
                      danmakuItems: value,
                      staticDurationInMilliseconds:
                          _option.staticDurationInMilliseconds,
                      fontSize: _option.fontSize,
                      fontWeight: _option.fontWeight,
                      strokeWidth: _option.strokeWidth,
                      tick: _notifier.value,
                    ),
                    size: widget.size,
                  );
                },
              ),
              1,
            ),
            RepaintBoundary.wrap(
              ValueListenableBuilder(
                valueListenable: _notifier, // 与滚动弹幕共用控制器
                builder: (context, value, child) {
                  return CustomPaint(
                    willChange: _running,
                    painter: SpecialDanmakuPainter(
                      length: _specialDanmakuItems.length,
                      danmakuItems: _specialDanmakuItems,
                      fontSize: _option.fontSize,
                      fontWeight: _option.fontWeight,
                      strokeWidth: _option.strokeWidth,
                      running: _running,
                      tick: value,
                    ),
                    size: widget.size,
                  );
                },
              ),
              2,
            ),
          ],
        ),
      ),
    );
  }

  Iterable<(double, DanmakuItem<T>)> findDanmaku(Offset position) sync* {
    final index = position.dy ~/ _danmakuHeight;

    if (index >= _trackCount) {
      return;
    }

    late final trackHeight = index * _danmakuHeight;

    final dx = position.dx;
    final item = _staticDanmakuItems[index];
    if (item != null &&
        item.xPosition <= dx &&
        dx <= item.xPosition + item.width) {
      yield (trackHeight, item);
    }

    for (var i in _scrollDanmakuItems[index].reversed) {
      if (i.xPosition <= dx && dx <= i.xPosition + i.width) {
        yield (trackHeight, i);
      }
    }
  }

  (double, DanmakuItem<T>)? findSingleDanmaku(Offset position) {
    final index = position.dy ~/ _danmakuHeight;

    if (index >= _trackCount) {
      return null;
    }

    late final trackHeight = index * _danmakuHeight;

    final dx = position.dx;
    final item = _staticDanmakuItems[index];
    if (item != null &&
        item.xPosition <= dx &&
        dx <= item.xPosition + item.width) {
      return (trackHeight, item);
    }

    for (var i in _scrollDanmakuItems[index].reversed) {
      if (i.xPosition <= dx && dx <= i.xPosition + i.width) {
        return (trackHeight, i);
      }
    }
    return null;
  }
}

typedef ListValueNotifier<T extends Object> = ValueNotifier<List<T?>>;

extension<T extends Object> on ListValueNotifier<T> {
  @pragma("vm:prefer-inline")
  T? operator [](int index) {
    return value[index];
  }

  @pragma("vm:prefer-inline")
  void operator []=(int index, T? item) {
    value[index] = item;
  }

  void removeWhere(bool Function(T element) test) {
    bool remove = false;
    for (int i = 0; i < value.length; i++) {
      final item = value[i];
      if (item != null && test(item)) {
        value[i] = null;
        remove = true;
      }
    }
    if (remove) {
      refresh();
    }
  }
}

extension ValueNotifierExt<T> on ValueNotifier<T> {
  @pragma("vm:prefer-inline")
  void refresh() {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    notifyListeners();
  }
}

extension<E> on List<E> {
  bool removeWhereUnsafe(bool Function(E) test) {
    int write = 0;
    final length = this.length;
    for (int read = 0; read < length; read++) {
      final element = this[read];
      if (!test(element)) {
        if (write < read) this[write] = element;
        write++;
      }
    }
    if (length != write) {
      this.length = write;
      return true;
    }
    return false;
  }
}

extension<T> on List<List<T>> {
  @pragma("vm:prefer-inline")
  void changeLength(int length) {
    if (length > this.length) {
      addAll(Iterable.generate(length - this.length, (_) => <T>[]));
    } else {
      this.length = length;
    }
  }
}
