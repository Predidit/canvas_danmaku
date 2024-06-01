import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:canvas_danmaku/models/danmaku_content_item.dart';
import 'package:flutter/material.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';

import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CanvasDanmaku Demo',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late DanmakuController _controller;
  var _key = new GlobalKey<ScaffoldState>();

  final _danmuKey = GlobalKey();

  bool _running = true;
  bool _showStroke = true;
  double _opacity = 1.0;
  int _duration = 8;
  double _fontSize = (Platform.isIOS || Platform.isAndroid) ? 16 : 25;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      appBar: AppBar(
        title: Text('CanvasDanmaku Demo'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            tooltip: 'Add',
            onPressed: () {
              _controller.addDanmaku(
                DanmakuContentItem(
                    "这是一条超长弹幕ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789这是一条超长的弹幕，这条弹幕会超出屏幕宽度",
                    color: getRandomColor()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.play_circle_outline_outlined),
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
            icon: Icon(Icons.clear),
            onPressed: () {
              _controller.clear();
            },
            tooltip: 'Clear',
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              _key.currentState?.openEndDrawer();
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      backgroundColor: Colors.grey,
      body: DanmakuScreen(
        key: _danmuKey,
        createdController: (DanmakuController e) {
          _controller = e;
        },
        option: DanmakuOption(
          opacity: _opacity,
          fontSize: _fontSize,
          duration: _duration,
          showStroke: _showStroke,
        ),
      ),
      endDrawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.all(8),
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
    List<DanmakuContentItem> _items = [];
    var jsonMap = json.decode(data);
    for (var item in jsonMap['comments']) {
      _items.add(DanmakuContentItem(
        item['m'],
        color: Colors.white,
      ));
    }
    if (timer == null) {
      timer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (!_controller.running) return;
        _controller.addDanmaku(_items[sec]);
        sec++;
      });
    }
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
