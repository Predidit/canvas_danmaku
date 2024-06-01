import 'package:flutter/material.dart';

enum DanmakuItemType {
  scroll,
  top,
  bottom,
}

class DanmakuContentItem {
  final String text;
  final Color color;
  final DanmakuItemType type;
  DanmakuContentItem(
    this.text, {
    this.color = Colors.white,
    this.type = DanmakuItemType.scroll,
  });
}
