import 'package:canvas_danmaku/models/danmaku_content_item.dart';
import 'package:canvas_danmaku/models/danmaku_option.dart';
import 'package:flutter/material.dart';

class DanmakuController {
  final ValueChanged<DanmakuContentItem> addDanmaku;
  final ValueChanged<DanmakuOption> updateOption;
  final VoidCallback pause;
  final VoidCallback resume;
  final VoidCallback clear;
  final DanmakuOption Function() getOption;
  final bool Function() isRunning;

  DanmakuOption get option => getOption();

  bool get running => isRunning();

  DanmakuController({
    required this.addDanmaku,
    required this.updateOption,
    required this.pause,
    required this.resume,
    required this.clear,
    required this.getOption,
    required this.isRunning,
  });
}
