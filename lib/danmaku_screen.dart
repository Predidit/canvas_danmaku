import 'dart:collection';
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

  const DanmakuScreen({
    required this.createdController,
    required this.option,
    super.key,
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
  DanmakuOption _option = const DanmakuOption();

  /// 滚动弹幕
  final _scrollDanmakuItems = <DanmakuItem<T>>[];

  /// 分帧处理栅格化和资源释放，避免单帧耗时尖峰。
  final _pendingRasterItems = Queue<DanmakuItem<T>>();
  final _pendingDisposeItems = Queue<DanmakuItem<T>>();

  /// 静态弹幕
  final _staticDanmakuItems = ListValueNotifier(<DanmakuItem<T>>[]);

  /// 高级弹幕
  final _specialDanmakuItems = <DanmakuItem<T>>[];

  /// 弹幕高度
  late double _danmakuHeight;

  /// 弹幕轨道数
  late int _trackCount;

  /// 弹幕轨道位置
  late List<double> _trackYPositions;

  late List<DanmakuItem<T>?> _scrollTrackTails;

  late final _random = Random();

  late final Ticker _ticker;
  late final ValueNotifier<int> _notifier;
  late int _lastTick = 0;

  static const int _maxRasterizePerFrame = 2;
  static const int _maxDisposePerFrame = 8;

  /// 运行状态
  bool _running = true;

  @override
  void initState() {
    super.initState();
    _option = widget.option;
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
      getViewWidth: () => _viewWidth,
      getViewHeight: () => _viewHeight,
      scrollDanmaku: _scrollDanmakuItems,
      staticDanmaku: _staticDanmakuItems.value,
      specialDanmaku: _specialDanmakuItems,
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    if (devicePixelRatio != this.devicePixelRatio) {
      this.devicePixelRatio = devicePixelRatio;
      for (var item in _scrollDanmakuItems) {
        _disposeImageNow(item);
        _enqueueRaster(item);
      }
      for (var item in _staticDanmakuItems.value) {
        _disposeImageNow(item);
        _enqueueRaster(item);
      }
      for (var item in _specialDanmakuItems) {
        _disposeImageNow(item);
        _enqueueRaster(item);
      }
    }
  }

  int _time = 0;
  void _tick(Duration elapsed) {
    _drainRasterQueue();
    _drainDisposeQueue();
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
    while (_pendingDisposeItems.isNotEmpty) {
      _pendingDisposeItems.removeFirst().dispose();
    }
    _pendingRasterItems.clear();
    _staticDanmakuItems.dispose();
    super.dispose();
  }

  void _handleAddDanmaku(
    DanmakuContentItem<T> content,
    bool Function(double, double) canAdd,
  ) {
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

    DanmakuItem<T> getItem(double yPos, int trackIndex) => DanmakuItem<T>(
        yPosition: yPos,
        xPosition: _viewWidth,
        trackIndex: trackIndex,
        width: danmakuWidth,
        height: danmakuHeight,
        content: content);

    for (var i = 0; i < _trackYPositions.length; i++) {
      final yPosition = _trackYPositions[i];

      if (added = canAdd(yPosition, danmakuWidth)) {
        final item = getItem(yPosition, i);
        _enqueueRaster(item);
        if (content.type == DanmakuItemType.scroll) {
          _scrollDanmakuItems.add(item);
          _scrollTrackTails[i] = item;
        } else {
          if (_running) {
            _staticDanmakuItems.add(item);
          } else {
            _staticDanmakuItems.value.add(item);
          }
        }
        break;
      }

      if (content.type == DanmakuItemType.scroll &&
          i == _trackYPositions.length - 1) {
        if (content.selfSend) {
          added = true;
          final item = getItem(_trackYPositions[0], 0);
          _enqueueRaster(item);
          _scrollDanmakuItems.add(item);
          _scrollTrackTails[0] = item;
          break;
        }

        if (_option.massiveMode) {
          added = true;
          final trackIndex = _random.nextInt(_trackYPositions.length);
          final item = getItem(_trackYPositions[trackIndex], trackIndex);
          _enqueueRaster(item);
          _scrollDanmakuItems.add(item);
          _scrollTrackTails[trackIndex] = item;
          break;
        }
      }
    }

    paragraph.dispose();

    if (_running && added) {
      if (!_ticker.isActive) {
        _ticker.start();
      }
    }
  }

  /// 添加弹幕
  void _addDanmaku(DanmakuContentItem<T> content) {
    if (!mounted) {
      return;
    }

    switch (content.type) {
      case DanmakuItemType.scroll:
        if (_option.hideScroll) return;
        _handleAddDanmaku(content, _scrollCanAddToTrack);
        break;
      case DanmakuItemType.top:
        if (_option.hideTop) return;
        _handleAddDanmaku(
          content,
          (yPosition, danmakuWidth) {
            return _topCanAddToTrack(yPosition);
          },
        );
        break;
      case DanmakuItemType.bottom:
        if (_option.hideBottom) return;
        _handleAddDanmaku(
          content,
          (yPosition, danmakuWidth) {
            if (_option.safeArea && yPosition <= _danmakuHeight) {
              return false;
            }
            return _bottomCanAddToTrack(yPosition);
          },
        );
        break;
      case DanmakuItemType.special:
        if (_option.hideSpecial) return;
        _specialDanmakuItems.add(
          _enqueueRaster(DanmakuItem<T>(width: 0, height: 0, content: content)),
        );
        if (_running) {
          if (!_ticker.isActive) {
            _ticker.start();
          }
        }
        break;
    }
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
      return;
    } else {
      _drainDisposeQueue(limit: _pendingDisposeItems.length);
      _notifier.refresh();
    }
  }

  /// 更新弹幕设置
  void _updateOption(DanmakuOption option) {
    final lineHeightChanged = option.lineHeight != _option.lineHeight;
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
      for (var e in _scrollDanmakuItems) {
        _disposeLater(e);
      }
      _scrollDanmakuItems.clear();
      _clearScrollTrackTails();
    }

    final clearTop = option.hideTop && !_option.hideTop;
    final clearBottom = option.hideBottom && !_option.hideBottom;
    if (clearTop || clearBottom) {
      _staticDanmakuItems.removeWhere((e) {
        final needRemove =
            (clearTop && e.content.type == DanmakuItemType.top) ||
                (clearBottom && e.content.type == DanmakuItemType.bottom);
        if (needRemove) {
          _disposeLater(e);
        }
        return needRemove;
      });
    }
    if (option.hideSpecial && !_option.hideSpecial) {
      for (var e in _specialDanmakuItems) {
        _disposeLater(e);
      }
      _specialDanmakuItems.clear();
    }

    /// 清理已经存在的 Paragraph 缓存
    if (clearParagraph) {
      DmUtils.updateSelfSendPaint(option.strokeWidth);
      for (var item in _scrollDanmakuItems) {
        _disposeImageNow(item);
        _enqueueRaster(item);
      }
      for (var item in _staticDanmakuItems.value) {
        _disposeImageNow(item);
        _enqueueRaster(item);
      }
      for (var item in _specialDanmakuItems) {
        _disposeImageNow(item);
        _enqueueRaster(item);
      }
    }

    final areaChanged = option.area != _option.area;
    final safeAreaChanged = option.safeArea != _option.safeArea;
    _option = option;
    if (fontSizeChanged || lineHeightChanged) {
      _danmakuHeight = _textPainter.height;
    }
    if (fontSizeChanged ||
        lineHeightChanged ||
        areaChanged ||
        safeAreaChanged) {
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
    for (var e in _scrollDanmakuItems) {
      _disposeLater(e);
    }
    _scrollDanmakuItems.clear();
    _clearScrollTrackTails();
    for (var e in _staticDanmakuItems.value) {
      _disposeLater(e);
    }
    _staticDanmakuItems.clear();
    for (var e in _specialDanmakuItems) {
      _disposeLater(e);
    }
    _specialDanmakuItems.clear();
  }

  /// 确定滚动弹幕是否可以添加
  bool _scrollCanAddToTrack(double yPosition, double newDanmakuWidth) {
    final trackIndex = _trackIndexForY(yPosition);
    final item = _scrollTrackTails[trackIndex];
    if (item == null || item.expired) {
      return true;
    }
    final existingEndPosition = item.xPosition + item.width;
    // 首先保证进入屏幕时不发生重叠，其次保证知道移出屏幕前不与速度慢的弹幕(弹幕宽度较小)发生重叠
    if (_viewWidth - existingEndPosition < 0) {
      return false;
    }
    if (item.width < newDanmakuWidth) {
      if ((1 - ((_viewWidth - item.xPosition) / (item.width + _viewWidth))) >
          ((_viewWidth) / (_viewWidth + newDanmakuWidth))) {
        return false;
      }
    }
    return true;
  }

  /// 确定顶部弹幕是否可以添加
  bool _topCanAddToTrack(double yPosition) {
    for (DanmakuItem item in _staticDanmakuItems.value) {
      if (item.content.type == DanmakuItemType.top &&
          item.yPosition == yPosition) {
        return false;
      }
    }
    return true;
  }

  /// 确定底部弹幕是否可以添加
  bool _bottomCanAddToTrack(double yPosition) {
    for (DanmakuItem item in _staticDanmakuItems.value) {
      if (item.content.type == DanmakuItemType.bottom &&
          item.yPosition == yPosition) {
        return false;
      }
    }
    return true;
  }

  @pragma("vm:prefer-inline")
  void _lazyTick(int tick) {
    // 移除屏幕外滚动弹幕
    _scrollDanmakuItems.removeWhere((item) {
      if (!item.expired) return false;
      if (item.trackIndex >= 0 && _scrollTrackTails[item.trackIndex] == item) {
        _scrollTrackTails[item.trackIndex] = null;
      }
      _disposeLater(item);
      return true;
    });
    // 移除静态弹幕
    _staticDanmakuItems.removeWhere((item) {
      final shouldRemove = !item.suspend &&
          item.drawTick != null &&
          (tick - item.drawTick!) >= _option.staticDurationInMilliseconds;
      if (shouldRemove) {
        _disposeLater(item);
      }
      return shouldRemove;
    });
    // 移除高级弹幕
    _specialDanmakuItems.removeWhere((item) {
      if (!item.expired) return false;
      _disposeLater(item);
      return true;
    });
    // 暂停动画
    if (_scrollDanmakuItems.isEmpty &&
        _specialDanmakuItems.isEmpty &&
        _staticDanmakuItems.value.isEmpty &&
        _ticker.isActive) {
      _lastTick = tick;
      _ticker.stop();
    }
  }

  void _calcTracks() {
    _trackCount = (_viewHeight * _option.area / _danmakuHeight).floor();

    /// 为字幕留出余量
    if (_option.safeArea && _option.area == 1.0) {
      _trackCount = _trackCount - 1;
    }

    _trackYPositions = List<double>.generate(
        _trackCount, (i) => i * _danmakuHeight,
        growable: false);
    _scrollTrackTails = List<DanmakuItem<T>?>.filled(_trackCount, null);
    for (final item in _scrollDanmakuItems) {
      final trackIndex = _trackIndexForY(item.yPosition);
      item.trackIndex = trackIndex;
      _scrollTrackTails[trackIndex] = item;
    }
  }

  DanmakuItem<T> _enqueueRaster(DanmakuItem<T> item) {
    if (!item.rasterQueued && item.image == null) {
      item.rasterQueued = true;
      _pendingRasterItems.add(item);
    }
    return item;
  }

  void _drainRasterQueue() {
    var remaining = _maxRasterizePerFrame;
    while (remaining > 0 && _pendingRasterItems.isNotEmpty) {
      final item = _pendingRasterItems.removeFirst();
      // ignore: cascade_invocations
      item.rasterQueued = false;
      final shouldSkip =
          item.expired || item.disposeQueued || item.image != null;
      if (shouldSkip) {
        continue;
      }
      _rasterizeItem(item);
      remaining--;
    }
  }

  void _rasterizeItem(DanmakuItem<T> item) {
    final content = item.content;
    if (content is SpecialDanmakuContentItem) {
      item.image = DmUtils.recordSpecialDanmakuImg(
        content: content as SpecialDanmakuContentItem<dynamic>,
        fontWeight: _option.fontWeight,
        strokeWidth: _option.strokeWidth,
        devicePixelRatio: devicePixelRatio,
        fontFamily: _option.fontFamily,
      );
    } else {
      item.drawParagraphIfNeeded(
        _option.fontSize,
        _option.fontWeight,
        _option.strokeWidth,
        devicePixelRatio,
        _option.fontFamily,
      );
    }
  }

  void _disposeLater(DanmakuItem<T> item) {
    item.expired = true;
    if (!item.disposeQueued) {
      item.disposeQueued = true;
      _pendingDisposeItems.add(item);
    }
  }

  void _drainDisposeQueue({int limit = _maxDisposePerFrame}) {
    var remaining = limit;
    while (remaining > 0 && _pendingDisposeItems.isNotEmpty) {
      final item = _pendingDisposeItems.removeFirst();
      // ignore: cascade_invocations
      item
        ..disposeQueued = false
        ..dispose();
      remaining--;
    }
  }

  void _disposeImageNow(DanmakuItem<T> item) {
    item
      ..image?.dispose()
      ..image = null;
  }

  int _trackIndexForY(double yPosition) {
    if (_trackCount <= 1) return 0;
    return (yPosition / _danmakuHeight).round().clamp(0, _trackCount - 1);
  }

  void _clearScrollTrackTails() {
    for (var i = 0; i < _scrollTrackTails.length; i++) {
      _scrollTrackTails[i] = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        /// 计算视图宽度
        _viewWidth = constraints.maxWidth;
        final viewHeight = constraints.maxHeight;
        if (_viewHeight != viewHeight) {
          _viewHeight = viewHeight;
          _calcTracks();
        }

        return ClipRect(
          child: Opacity(
            opacity: _option.opacity,
            child: IgnorePointer(
              child: Stack(
                children: [
                  RepaintBoundary.wrap(
                    ValueListenableBuilder(
                      valueListenable: _notifier,
                      builder: (context, value, child) {
                        return CustomPaint(
                          willChange: _running,
                          painter: ScrollDanmakuPainter(
                            length: _scrollDanmakuItems.length,
                            danmakuItems: _scrollDanmakuItems,
                            durationInMilliseconds:
                                _option.durationInMilliseconds,
                            fontSize: _option.fontSize,
                            fontWeight: _option.fontWeight,
                            strokeWidth: _option.strokeWidth,
                            devicePixelRatio: devicePixelRatio,
                            running: _running,
                            tick: value,
                          ),
                          size: Size.infinite,
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
                            length: value.length,
                            danmakuItems: value,
                            staticDurationInMilliseconds:
                                _option.staticDurationInMilliseconds,
                            fontSize: _option.fontSize,
                            fontWeight: _option.fontWeight,
                            strokeWidth: _option.strokeWidth,
                            devicePixelRatio: devicePixelRatio,
                            tick: _notifier.value,
                          ),
                          size: Size.infinite,
                        );
                      },
                    ),
                    1,
                  ),
                  RepaintBoundary.wrap(
                    IgnorePointer(
                        child: ValueListenableBuilder(
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
                            devicePixelRatio: devicePixelRatio,
                            running: _running,
                            tick: value,
                          ),
                          size: Size.infinite,
                        );
                      },
                    )),
                    2,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Iterable<DanmakuItem<T>> hitDanmaku(
      List<DanmakuItem<T>> danmakuItems, Offset position) sync* {
    if (danmakuItems.isNotEmpty) {
      final dy = position.dy;
      for (var i in danmakuItems.reversed) {
        final double danmakuY0;
        final double danmakuY1;
        if (i.content.type == DanmakuItemType.bottom) {
          danmakuY1 = _viewHeight - i.yPosition;
          danmakuY0 = danmakuY1 - i.height;
        } else {
          assert(i.content.type != DanmakuItemType.special);
          danmakuY0 = i.yPosition;
          danmakuY1 = danmakuY0 + i.height;
        }

        if (danmakuY0 <= dy && dy <= danmakuY1) {
          final dx = position.dx;
          if (i.xPosition <= dx && dx <= i.xPosition + i.width) {
            yield i;
          }
        }
      }
    }
  }

  DanmakuItem<T>? hitSingleDanmaku(
      List<DanmakuItem<T>> danmakuItems, Offset position) {
    if (danmakuItems.isNotEmpty) {
      final dy = position.dy;
      for (var i in danmakuItems.reversed) {
        final double danmakuY0;
        final double danmakuY1;
        if (i.content.type == DanmakuItemType.bottom) {
          danmakuY1 = _viewHeight - i.yPosition;
          danmakuY0 = danmakuY1 - i.height;
        } else {
          assert(i.content.type != DanmakuItemType.special);
          danmakuY0 = i.yPosition;
          danmakuY1 = danmakuY0 + i.height;
        }

        if (danmakuY0 <= dy && dy <= danmakuY1) {
          final dx = position.dx;
          if (i.xPosition <= dx && dx <= i.xPosition + i.width) {
            return i;
          }
        }
      }
    }
    return null;
  }

  Iterable<DanmakuItem<T>> findDanmaku(Offset pos) =>
      hitDanmaku(_staticDanmakuItems.value, pos)
          .followedBy(hitDanmaku(_scrollDanmakuItems, pos));

  DanmakuItem<T>? findSingleDanmaku(Offset pos) =>
      hitSingleDanmaku(_staticDanmakuItems.value, pos) ??
      hitSingleDanmaku(_scrollDanmakuItems, pos);
}

class ListValueNotifier<T> extends ValueNotifier<List<T>> {
  ListValueNotifier(super.value);

  void add(T item) {
    value.add(item);
    notifyListeners();
  }

  void clear() {
    if (value.isNotEmpty) {
      value.clear();
      notifyListeners();
    }
  }

  void removeWhere(bool Function(T element) test) {
    if (value.removeWhereUnsafe(test)) {
      notifyListeners();
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
