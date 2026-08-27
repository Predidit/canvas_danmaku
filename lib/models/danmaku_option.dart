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

  /// 滚动弹幕的最高速度，单位为 logical pixels / second。
  ///
  /// 宽屏时由 [duration] 推导出的速度可能过高；该上限避免弹幕因视图
  /// 宽度增加而产生过大的逐帧位移。
  final double maxScrollSpeed;

  /// 在显示器单次刷新中允许移动的最大物理像素数。
  ///
  /// 结合显示器刷新率与设备像素比，换算为恒定的安全滚动速度。
  final double maxScrollDistancePerFrame;

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

  final bool hideSpecial;

  /// 弹幕描边
  final double strokeWidth;

  /// 海量弹幕模式 (弹幕轨道占满时进行叠加)
  final bool massiveMode;

  /// 为字幕预留空间
  final bool safeArea;

  /// 弹幕行高
  final double lineHeight;

  const DanmakuOption({
    this.fontSize = 16,
    this.fontWeight = 4,
    this.fontFamily,
    this.area = 1.0,
    this.duration = 10,
    this.maxScrollSpeed = 480,
    this.maxScrollDistancePerFrame = 4,
    this.staticDuration = 5,
    this.opacity = 1.0,
    this.hideBottom = false,
    this.hideScroll = false,
    this.hideTop = false,
    this.hideSpecial = false,
    this.strokeWidth = 1.5,
    this.massiveMode = false,
    this.safeArea = true,
    this.lineHeight = 1.6,
  })  : assert(duration > 0),
        assert(maxScrollSpeed > 0),
        assert(maxScrollDistancePerFrame > 0),
        durationInMilliseconds = duration * 1000,
        staticDurationInMilliseconds = staticDuration * 1000;

  DanmakuOption copyWith({
    double? fontSize,
    int? fontWeight,
    String? fontFamily,
    double? area,
    double? duration,
    double? maxScrollSpeed,
    double? maxScrollDistancePerFrame,
    double? staticDuration,
    double? opacity,
    bool? hideTop,
    bool? hideBottom,
    bool? hideScroll,
    bool? hideSpecial,
    double? strokeWidth,
    bool? massiveMode,
    bool? safeArea,
    double? lineHeight,
  }) {
    return DanmakuOption(
      area: area ?? this.area,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      fontFamily: fontFamily ?? this.fontFamily,
      duration: duration ?? this.duration,
      maxScrollSpeed: maxScrollSpeed ?? this.maxScrollSpeed,
      maxScrollDistancePerFrame:
          maxScrollDistancePerFrame ?? this.maxScrollDistancePerFrame,
      staticDuration: staticDuration ?? this.staticDuration,
      opacity: opacity ?? this.opacity,
      hideTop: hideTop ?? this.hideTop,
      hideBottom: hideBottom ?? this.hideBottom,
      hideScroll: hideScroll ?? this.hideScroll,
      hideSpecial: hideSpecial ?? this.hideSpecial,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      massiveMode: massiveMode ?? this.massiveMode,
      safeArea: safeArea ?? this.safeArea,
      lineHeight: lineHeight ?? this.lineHeight,
    );
  }
}
