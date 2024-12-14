import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';

import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'CanvasDanmaku Demo',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DanmakuController? _controller;

  final _danmuKey = GlobalKey();

  bool _running = true;

  /// 弹幕描边
  double _strokeWidth = 1.5;

  /// 弹幕海量模式(弹幕轨道填满时继续绘制)
  bool _massiveMode = false;

  /// 弹幕透明度
  double _opacity = 1.0;

  /// 弹幕持续时间
  int _duration = 8;

  /// 弹幕字号
  double _fontSize = (Platform.isIOS || Platform.isAndroid) ? 16 : 25;

  /// 弹幕粗细
  int _fontWeight = 4;

  /// 隐藏滚动弹幕
  final bool _hideScroll = false;

  /// 隐藏顶部弹幕
  final bool _hideTop = false;

  /// 隐藏底部弹幕
  final bool _hideBottom = false;

  /// 为字幕预留空间
  bool _safeArea = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CanvasDanmaku Demo'),
      ),
      body: Column(
        children: [
          Wrap(
            children: [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Add Scroll',
                onPressed: () {
                  _controller?.addDanmaku(
                    DanmakuContentItem(
                      "这是一条超长弹幕ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789这是一条超长的弹幕，这条弹幕会超出屏幕宽度",
                      color: getRandomColor(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Add Top',
                onPressed: () {
                  _controller?.addDanmaku(
                    DanmakuContentItem(
                      "这是一条顶部弹幕",
                      color: getRandomColor(),
                      type: DanmakuItemType.top,
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Add Bottom',
                onPressed: () {
                  _controller?.addDanmaku(
                    DanmakuContentItem(
                      "这是一条底部弹幕",
                      color: getRandomColor(),
                      type: DanmakuItemType.bottom,
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Add Bottom',
                onPressed: () {
                  _controller?.addDanmaku(
                    DanmakuContentItem(
                      "这是一条自己发的弹幕",
                      color: getRandomColor(),
                      type: DanmakuItemType.scroll,
                      selfSend: true,
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.play_circle_outline_outlined),
                onPressed: startPlay,
                tooltip: 'Start Player',
              ),
              IconButton(
                icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                onPressed: () {
                  if (_running) {
                    _controller?.pause();
                  } else {
                    _controller?.resume();
                  }
                  setState(() {
                    _running = !_running;
                  });
                },
                tooltip: 'Play Resume',
              ),
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _controller?.clear,
                tooltip: 'Clear',
              ),
            ],
          ),
          Expanded(
            child: Container(
              color: Colors.grey,
              child: DanmakuScreen(
                key: _danmuKey,
                createdController: (DanmakuController e) {
                  _controller = e;
                },
                option: DanmakuOption(
                  opacity: _opacity,
                  fontSize: _fontSize,
                  fontWeight: _fontWeight,
                  duration: _duration,
                  strokeWidth: _strokeWidth,
                  massiveMode: _massiveMode,
                  hideScroll: _hideScroll,
                  hideTop: _hideTop,
                  hideBottom: _hideBottom,
                  safeArea: _safeArea,
                ),
              ),
            ),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: [
              Text("Stroke Width : $_strokeWidth"),
              Slider(
                value: _strokeWidth,
                min: 0,
                max: 10,
                divisions: 20,
                onChanged: (e) {
                  setState(() {
                    _strokeWidth = e;
                  });
                  _controller?.updateOption(
                    _controller!.option.copyWith(strokeWidth: _strokeWidth),
                  );
                },
              ),
              Text("Font Weight : $_fontWeight"),
              Slider(
                value: _fontWeight.toDouble(),
                min: 0,
                max: 8,
                divisions: 8,
                onChanged: (e) {
                  setState(() {
                    _fontWeight = e.toInt();
                  });
                  _controller?.updateOption(
                    _controller!.option.copyWith(fontWeight: _fontWeight),
                  );
                },
              ),
              Text("Opacity : $_opacity"),
              Slider(
                value: _opacity,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                onChanged: (e) {
                  setState(() {
                    _opacity = double.parse(e.toStringAsFixed(1));
                  });
                  _controller?.updateOption(
                    _controller!.option.copyWith(opacity: e),
                  );
                },
              ),
              Text("Font Size : $_fontSize"),
              Slider(
                value: _fontSize,
                min: 8,
                max: 36,
                divisions: 14,
                onChanged: (e) {
                  setState(() {
                    _fontSize = e;
                  });
                  _controller?.updateOption(
                    _controller!.option.copyWith(fontSize: e),
                  );
                },
              ),
              Text("Duration : $_duration"),
              Slider(
                value: _duration.toDouble(),
                min: 4,
                max: 20,
                divisions: 16,
                onChanged: (e) {
                  setState(() {
                    _duration = e.toInt();
                  });
                  _controller?.updateOption(
                    _controller!.option.copyWith(duration: e.toInt()),
                  );
                },
              ),
              SwitchListTile(
                  title: const Text('MassiveMode'),
                  value: _massiveMode,
                  onChanged: (e) {
                    setState(() {
                      _massiveMode = e;
                    });
                    _controller?.updateOption(
                      _controller!.option.copyWith(massiveMode: e),
                    );
                  }),
              SwitchListTile(
                title: const Text('SafeArea'),
                value: _safeArea,
                onChanged: (e) {
                  setState(() {
                    _safeArea = e;
                  });
                  _controller?.updateOption(
                    _controller!.option.copyWith(safeArea: e),
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  Timer? timer;
  int sec = 0;
  void startPlay() async {
    String data = await rootBundle.loadString('assets/132590001.json');
    List<DanmakuContentItem> items = [];
    Map jsonMap = json.decode(data);
    for (Map item in jsonMap['comments']) {
      items.add(
        DanmakuContentItem(
          item['m'],
          color: Colors.white,
        ),
      );
    }
    timer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_controller == null || _controller?.running == false) return;
      _controller?.addDanmaku(items[sec]);
      sec++;
    });
  }

  // 生成随机颜色
  Color getRandomColor() {
    final Random random = Random();
    return Color.fromARGB(
      255, // 固定 alpha 为 255（完全不透明）
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}
