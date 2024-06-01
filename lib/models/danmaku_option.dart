class DanmakuOption {
  /// 默认的字体大小
  final double fontSize;

  /// 显示区域，0.1-1.0
  final double area;

  /// 滚动弹幕运行时间，秒
  final int duration;

  /// 不透明度，0.1-1.0
  final double opacity;

  /// 弹幕描边
  final bool showStroke;

  DanmakuOption({
    this.fontSize = 16,
    this.area = 1.0,
    this.duration = 10,
    this.opacity = 1.0,
    this.showStroke = true,
  });

  DanmakuOption copyWith({
    double? fontSize,
    double? area,
    int? duration,
    double? opacity,
    bool? showStroke,
  }) {
    return DanmakuOption(
      area: area ?? this.area,
      fontSize: fontSize ?? this.fontSize,
      duration: duration ?? this.duration,
      opacity: opacity ?? this.opacity,
      showStroke: showStroke ?? this.showStroke,
    );
  }
}
