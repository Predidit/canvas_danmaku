import 'package:canvas_danmaku/models/danmaku_options.dart';

class DanmakuController {
  final Function(String) onAddItems;
  final Function onPause;
  final Function onResume;
  final Function onClear;
  DanmakuController({
    required this.onAddItems,
    required this.onPause,
    required this.onResume,
    required this.onClear,
  });

  bool _running = true;

  /// 是否运行中
  /// 可以调用pause()暂停弹幕
  bool get running => _running;
  set running(e) {
    _running = e;
  }

  DanmakuOption _option = DanmakuOption();
  DanmakuOption get option => _option;
  set option(e) {
    _option = e;
  }

  /// 暂停弹幕
  void pause() {
    onPause.call();
  }

  /// 继续弹幕
  void resume() {
    onResume.call();
  }

  /// 清空弹幕
  void clear() {
    onClear.call();
  }

  /// 添加弹幕
  void addItems(String item) {
    onAddItems.call(item);
  }
}
