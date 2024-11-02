class DanmakuOption {
  /// 默认的字体大小
  final double fontSize;

  /// 字体粗细
  final int fontWeight;

  /// 显示区域，0.1-1.0
  final double area;

  /// 滚动弹幕运行时间，秒
  final int duration;

  /// 不透明度，0.1-1.0
  final double opacity;

  /// 隐藏顶部弹幕
  final bool hideTop;

  /// 隐藏底部弹幕
  final bool hideBottom;

  /// 隐藏滚动弹幕
  final bool hideScroll;

  /// 弹幕描边
  final double strokeWidth;

  /// 海量弹幕模式 (弹幕轨道占满时进行叠加)
  final bool massiveMode;

  DanmakuOption({
    this.fontSize = 16,
    this.fontWeight = 5,
    this.area = 1.0,
    this.duration = 10,
    this.opacity = 1.0,
    this.hideBottom = false,
    this.hideScroll = false,
    this.hideTop = false,
    this.strokeWidth = 1.5,
    this.massiveMode = false,
  });

  DanmakuOption copyWith({
    double? fontSize,
    int? fontWeight,
    double? area,
    int? duration,
    double? opacity,
    bool? hideTop,
    bool? hideBottom,
    bool? hideScroll,
    double? strokeWidth,
    bool? massiveMode,
  }) {
    return DanmakuOption(
      area: area ?? this.area,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      duration: duration ?? this.duration,
      opacity: opacity ?? this.opacity,
      hideTop: hideTop ?? this.hideTop,
      hideBottom: hideBottom ?? this.hideBottom,
      hideScroll: hideScroll ?? this.hideScroll,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      massiveMode: massiveMode ?? this.massiveMode,
    );
  }
}
