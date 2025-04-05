import 'dart:math' show pi;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

enum DanmakuItemType { scroll, top, bottom, special }

class DanmakuContentItem {
  /// 弹幕文本
  final String text;

  /// 弹幕颜色
  final Color color;

  /// 弹幕类型
  final DanmakuItemType type;

  /// 是否为自己发送
  final bool selfSend;

  /// 是否为会员弹幕
  final bool? isColorful;

  /// 弹幕数量
  final int? count;

  DanmakuContentItem(
    this.text, {
    this.color = Colors.white,
    this.type = DanmakuItemType.scroll,
    this.selfSend = false,
    this.isColorful,
    this.count,
  });
}

class SpecialDanmakuContentItem extends DanmakuContentItem {
  final int duration;

  final double fontSize; // 从弹幕内容外解析
  final bool hasStroke;
  final Tween<double> alphaTween;

  final Tween<double> translateXTween; // 相对坐标
  final Tween<double> translateYTween; // 相对坐标
  final int translationDuration;
  final int translationStartDelay;

  final Matrix4? matrix;
  final PathMetric? motionPathMetric;

  final Curve easingType;

  @override
  bool get isColorful => false;
  @override
  bool get selfSend => false;
  @override
  DanmakuItemType get type => DanmakuItemType.special;

  SpecialDanmakuContentItem(
    super.text, {
    required this.duration,
    required super.color,
    required this.fontSize,
    this.hasStroke = false,
    required this.translateXTween,
    required this.translateYTween,
    required this.alphaTween,
    this.matrix,
    this.motionPathMetric,
    int? translationDuration,
    this.translationStartDelay = 0,
    super.count,
    this.easingType = Curves.linear,
  }) : this.translationDuration = translationDuration ?? duration;

  factory SpecialDanmakuContentItem.fromList(
    Color color,
    double fontSize,
    List list, [
    double videoX = 1920,
    double videoY = 1080,
  ]) {
    double startX = _toRelative(list[0], videoX);
    double startY = _toRelative(list[1], videoY);
    List<String> alphaString = list[2].split('-');
    double startA = double.parse(alphaString[0]);
    double endA = double.parse(alphaString[1]);
    Tween<double> alphaTween = _makeTween(startA, endA);
    int duration = (double.parse(list[3]) * 1000).round();
    String text = list[4].trim();
    int rotateZ = _parseInt(list[5]);
    int rotateY = _parseInt(list[6]);
    Matrix4? matrix;
    if (rotateZ != 0 || rotateY != 0) {
      matrix = Matrix4.identity();
      if (rotateZ != 0) matrix.rotateZ(_degreeToRadian(rotateZ));
      if (rotateY != 0) matrix.rotateY(_degreeToRadian(rotateY));
    }
    double endX = _toRelative(list[7], videoX);
    double endY = _toRelative(list[8], videoY);
    var translateXTween = _makeTween(startX, endX);
    var translateYTween = _makeTween(startY, endY);
    int translationDuration = _parseInt(list[9]);
    int translationStartDelay = _parseInt(list[10]);
    bool hasStroke = list[11] == 1;
    // 字体
    // list[12];
    var easingType = list[13] == 1 ? Curves.easeInCubic : Curves.linear;
    // TODO 路径动画
    // List<Path> path;
    // if (list.length > 15) {
    //   list[14];
    // }
    return SpecialDanmakuContentItem(
      text,
      duration: duration,
      color: color,
      fontSize: fontSize,
      hasStroke: hasStroke,
      alphaTween: alphaTween,
      translateXTween: translateXTween,
      translateYTween: translateYTween,
      translationDuration: translationDuration,
      translationStartDelay: translationStartDelay,
      matrix: matrix,
      // motionPathMetric: null,
      easingType: easingType,
    );
  }

  static double _toRelative(String num, double videoSize) {
    double value = double.parse(num);
    if (value > 1 || !num.contains('.')) value /= videoSize;
    return value;
  }

  static int _parseInt(dynamic digit) => switch (digit) {
        int() => digit,
        double() => digit.toInt(),
        String() => int.parse(digit),
        _ => throw UnimplementedError()
      };

  static Tween<T> _makeTween<T>(T start, T end) {
    return start == end
        ? ConstantTween<T>(start)
        : Tween<T>(begin: start, end: end);
  }

  static double _degreeToRadian(int degree) {
    const pi180 = pi / 180;
    return degree * pi180;
  }
}
