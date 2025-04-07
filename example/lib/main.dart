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
  static final _random = Random();

  late DanmakuController _controller;

  final _danmuKey = GlobalKey();

  bool _running = true;

  /// 弹幕描边
  bool _showStroke = true;

  /// 弹幕海量模式(弹幕轨道填满时继续绘制)
  bool _massiveMode = false;

  /// 弹幕透明度
  double _opacity = 1.0;

  /// 弹幕持续时间
  int _duration = 8;

  /// 弹幕字号
  double _fontSize = (Platform.isIOS || Platform.isAndroid) ? 16 : 25;

  /// 弹幕粗细
  final int _fontWeight = 4;

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
                  _controller.addDanmaku(
                    DanmakuContentItem(
                        "这是一条超长弹幕ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789这是一条超长的弹幕，这条弹幕会超出屏幕宽度",
                        color: getRandomColor()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Add Top',
                onPressed: () {
                  _controller.addDanmaku(
                    DanmakuContentItem("这是一条顶部弹幕",
                        color: getRandomColor(), type: DanmakuItemType.top),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Add Bottom',
                onPressed: () {
                  _controller.addDanmaku(
                    DanmakuContentItem("这是一条底部弹幕",
                        color: getRandomColor(), type: DanmakuItemType.bottom),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Add Special',
                onPressed: () {
                  _controller.addDanmaku(randSpecialDanmaku());
                },
                onLongPress: () {
                  for (var i = 0; i < 100; i++) {
                    _controller.addDanmaku(randSpecialDanmaku());
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Add Special Circle',
                onPressed: () {
                  Iterable.generate(
                    36,
                    (i) => SpecialDanmakuContentItem(
                      '测试',
                      duration: 4000,
                      color: Colors.red,
                      fontSize: 64 * 2,
                      translateXTween: Tween<double>(begin: 0.5, end: 0.5),
                      translateYTween: Tween<double>(begin: 0.5, end: 0.5),
                      alphaTween: Tween<double>(begin: 1, end: 0),
                      matrix: Matrix4.identity()..rotateZ(i * pi / 18),
                      easingType: Curves.linear,
                      hasStroke: true,
                    ),
                  ).forEach(_controller.addDanmaku);
                },
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Add Special Star',
                onPressed: () {
                  _controller.addDanmaku(
                      SpecialDanmakuContentItem.fromList(getRandomColor(), 44, [
                    "0.939",
                    "0.083",
                    "1-1",
                    "6",
                    "☆——————\n" * 14,
                    "342",
                    "0",
                    "0.002",
                    "0.271",
                    500,
                    0,
                    1,
                    "SimHei",
                    1
                  ]));
                },
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Add Special Literal DanMu',
                onPressed: () async {
                  String data = await rootBundle.loadString('assets/dm.json');
                  final danmaku = jsonDecode(data) as List;
                  final dan = danmaku.last as List;
                  final mu = danmaku.first as List;
                  for (var item in dan) {
                    _controller.addDanmaku(SpecialDanmakuContentItem.fromList(
                        Colors.orange, 16, item));
                  }
                  await Future.delayed(const Duration(seconds: 2));
                  for (var item in mu) {
                    _controller.addDanmaku(SpecialDanmakuContentItem.fromList(
                        Colors.orange, 16, item));
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Add Self',
                onPressed: () {
                  _controller.addDanmaku(
                    DanmakuContentItem("这是一条自己发的弹幕",
                        color: getRandomColor(),
                        type: DanmakuItemType.scroll,
                        selfSend: true),
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
                    _controller.pause();
                  } else {
                    _controller.resume();
                  }
                  setState(() {
                    _running = !_running;
                  });
                },
                tooltip: 'Play Resume',
              ),
              IconButton(
                icon: Icon(_showStroke
                    ? Icons.font_download
                    : Icons.font_download_rounded),
                onPressed: () {
                  _controller.updateOption(
                      _controller.option.copyWith(showStroke: !_showStroke));
                  setState(() {
                    _showStroke = !_showStroke;
                  });
                },
                tooltip: 'Stroke',
              ),
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                },
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
                showStroke: _showStroke,
                massiveMode: _massiveMode,
                hideScroll: _hideScroll,
                hideTop: _hideTop,
                hideBottom: _hideBottom,
                safeArea: _safeArea,
              ),
            ),
          )),
        ],
      ),
      endDrawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: [
              Text("Opacity : $_opacity"),
              Slider(
                value: _opacity,
                max: 1.0,
                min: 0.1,
                divisions: 9,
                onChanged: (e) {
                  setState(() {
                    _opacity = e;
                  });
                  _controller
                      .updateOption(_controller.option.copyWith(opacity: e));
                },
              ),
              Text("FontSize : $_fontSize"),
              Slider(
                value: _fontSize,
                min: 8,
                max: 36,
                divisions: 14,
                onChanged: (e) {
                  setState(() {
                    _fontSize = e;
                  });
                  _controller
                      .updateOption(_controller.option.copyWith(fontSize: e));
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
                  _controller.updateOption(
                      _controller.option.copyWith(duration: e.toInt()));
                },
              ),
              SwitchListTile(
                  title: const Text('MassiveMode'),
                  value: _massiveMode,
                  onChanged: (e) {
                    setState(() {
                      _massiveMode = e;
                    });
                    _controller.updateOption(
                        _controller.option.copyWith(massiveMode: e));
                  }),
              SwitchListTile(
                  title: const Text('SafeArea'),
                  value: _safeArea,
                  onChanged: (e) {
                    setState(() {
                      _safeArea = e;
                    });
                    _controller
                        .updateOption(_controller.option.copyWith(safeArea: e));
                  })
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
    var jsonMap = json.decode(data);
    for (var item in jsonMap['comments']) {
      items.add(DanmakuContentItem(
        item['m'],
        color: Colors.white,
      ));
    }
    timer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_controller.running) return;
      _controller.addDanmaku(items[sec]);
      sec++;
    });
  }

  // 生成随机颜色
  static Color getRandomColor() {
    return Color(0xFF000000 | _random.nextInt(0x1000000));
  }

  static randSpecialDanmaku() {
    final translationStartDelay = _random.nextInt(1000);
    final translationDuration = _random.nextInt(14000);
    final duration =
        translationStartDelay + translationDuration + _random.nextInt(1000);
    return SpecialDanmakuContentItem(
      '这是一条特殊弹幕',
      color: getRandomColor(),
      fontSize: _random.nextInt(50) + 25,
      translateXTween: Tween<double>(
        begin: _random.nextDouble(),
        end: _random.nextDouble(),
      ),
      translateYTween: Tween<double>(
        begin: _random.nextDouble(),
        end: _random.nextDouble(),
      ),
      alphaTween:
          Tween<double>(begin: _random.nextDouble(), end: _random.nextDouble()),
      matrix: Matrix4.identity()
        ..rotateZ(_random.nextDouble() * pi)
        ..rotateY(_random.nextDouble() * pi),
      duration: duration,
      translationDuration: translationDuration,
      translationStartDelay: translationStartDelay,
      easingType: const [Curves.linear, Curves.easeInCubic][_random.nextInt(2)],
      hasStroke: _random.nextBool(),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}
