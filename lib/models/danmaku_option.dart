import 'package:canvas_danmaku/canvas_danmaku.dart';

class DanmakuOption {
  /// 默认的字体大小
  final double fontSize;

  /// 字体粗细
  final int fontWeight;

  /// 字体名称
  final String? fontFamily;

  /// 显示区域，0.1-1.0
  final double area;

  /// 滚动弹幕运行时间，秒
  final double duration;

  /// 弹幕透明度
  final double opacity;

  final double durationInMilliseconds;

  /// 静态弹幕运行时间，秒
  final double staticDuration;

  final double staticDurationInMilliseconds;

  /// 隐藏顶部弹幕
  final bool hideTop;

  /// 隐藏底部弹幕
  final bool hideBottom;

  /// 隐藏滚动弹幕
  final bool hideScroll;

  /// 隐藏高级弹幕
  final bool hideSpecial;

  /// 弹幕描边
  final double strokeWidth;

  /// 滚动弹幕速度不随内容长度变化
  final bool scrollFixedVelocity;

  /// 海量弹幕模式 (弹幕轨道占满时进行叠加)
  final bool massiveMode;

  /// 静态弹幕无法添加或宽度超出显示区域时作为滚动弹幕添加
  final bool static2Scroll;

  /// 为字幕预留空间
  final bool safeArea;

  /// 弹幕行高
  final double lineHeight;

  bool hideWhat(DanmakuItemType type) => switch (type) {
        DanmakuItemType.scroll => hideScroll,
        DanmakuItemType.top => hideTop,
        DanmakuItemType.bottom => hideBottom,
        DanmakuItemType.special => hideSpecial,
      };

  const DanmakuOption({
    this.fontSize = 16,
    this.fontWeight = 4,
    this.fontFamily,
    this.area = 1.0,
    this.duration = 10,
    this.staticDuration = 5,
    this.opacity = 1.0,
    this.hideBottom = false,
    this.hideScroll = false,
    this.hideTop = false,
    this.hideSpecial = false,
    this.strokeWidth = 1.5,
    this.scrollFixedVelocity = false,
    this.massiveMode = false,
    this.static2Scroll = false,
    this.safeArea = true,
    this.lineHeight = 1.6,
  })  : durationInMilliseconds = duration * 1000,
        staticDurationInMilliseconds = staticDuration * 1000;

  DanmakuOption copyWith({
    double? fontSize,
    int? fontWeight,
    String? fontFamily,
    double? area,
    double? duration,
    double? staticDuration,
    double? opacity,
    bool? hideTop,
    bool? hideBottom,
    bool? hideScroll,
    bool? hideSpecial,
    double? strokeWidth,
    bool? scrollFixedVelocity,
    bool? massiveMode,
    bool? static2Scroll,
    bool? safeArea,
    double? lineHeight,
  }) {
    return DanmakuOption(
      area: area ?? this.area,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      fontFamily: fontFamily ?? this.fontFamily,
      duration: duration ?? this.duration,
      staticDuration: staticDuration ?? this.staticDuration,
      opacity: opacity ?? this.opacity,
      hideTop: hideTop ?? this.hideTop,
      hideBottom: hideBottom ?? this.hideBottom,
      hideScroll: hideScroll ?? this.hideScroll,
      hideSpecial: hideSpecial ?? this.hideSpecial,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      scrollFixedVelocity: scrollFixedVelocity ?? this.scrollFixedVelocity,
      massiveMode: massiveMode ?? this.massiveMode,
      static2Scroll: static2Scroll ?? this.static2Scroll,
      safeArea: safeArea ?? this.safeArea,
      lineHeight: lineHeight ?? this.lineHeight,
    );
  }
}
