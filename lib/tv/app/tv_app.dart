import 'package:flutter/material.dart';
import 'package:PiliPlus/tv/screens/home_screen.dart';

/// BiliTV 的电视端入口。
///
/// 电视端的视觉层和焦点模型从 BiliTV 迁移；数据、账号和播放能力通过
/// PiliPlus 适配层接入。这个入口刻意与旧 pages_tv 路由隔离，便于最终删除旧界面。
class TvApp extends StatelessWidget {
  const TvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PiliPlus TV',
      theme: ThemeData.dark(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}
