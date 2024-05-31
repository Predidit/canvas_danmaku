<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

## 概述

一个使用 `CustomPainter` 进行直接绘制的简易高性能 `flutter` 弹幕组件

## 示例

``` yaml
dependencies: 
  # 请使用Git引用此包
  canvas_danmaku: 
    git: 
        url: https://github.com/Predidit/canvas_danmaku.git
        ref: main
```

Example:

```dart

import 'package:canvas_danmaku/canvas_danmaku.dart';

class _DanmakuPageState extends State<DanmakuPage> {
    late DanmakuController _controller;
    @override
    Widget build(BuildContext context) {
        return Stack(
        children: [
            // 你的自定义组件，例如一个播放器
            Container(),
            // 弹幕组件
            DanmakuScreen(
            createdController: (e) {
                _controller = e;
            },
            option: DanmakuOption(),
            ),
        ],
        );
    }
}

```

## 说明

本项目接口设计参考 `ns_danmaku` ，支持 `ns_danmaku` 除顶部弹幕和底部弹幕的大部分功能。本项目与其的区别在于弹幕绘制原理。

`ns_danmaku` 将每条弹幕作为单个 `widget` 进行维护。这样较为灵活，但同时有着较高的性能开销。

`canvas_danmaku` 通过 `CustomPainter` 直接绘制弹幕。这可以减少 Flutter 框架中组件的数量，降低了组件树的复杂度，从而提高性能。

此外本项目使用单个控制器管理所有弹幕的动画，这也减少了性能开销。

## 局限

如前文所述，本项目维护的每条弹幕的本质是一段动画，而非一个小组件。本项目绘制的弹幕不具有交互性，如果您需要点击弹幕来实现的弹幕点赞，弹幕举报，查看弹幕作者等功能，本项目并不能满足需求。

## 致谢

[xiaoyaocz/ns_danmaku](https://github.com/xiaoyaocz/flutter_ns_danmaku) 本项目的灵感来自 ns_danmaku ，一个非常优秀的项目。

