import 'package:flutter/material.dart';

abstract class TvMenuAdapter {
  List<Widget> buildMenuItems(BuildContext context);
}

class VideoCardMenuAdapter extends TvMenuAdapter {
  final dynamic videoItem;

  VideoCardMenuAdapter(this.videoItem);

  @override
  List<Widget> buildMenuItems(BuildContext context) {
    return [
      ListTile(
        autofocus: true,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: const Icon(Icons.play_arrow_outlined, size: 22),
        title: const Text('立即播放', style: TextStyle(fontSize: 16)),
        onTap: () {
          // TODO: Implement play logic
          Navigator.of(context).pop();
        },
      ),
      ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: const Icon(Icons.watch_later_outlined, size: 22),
        title: const Text('稍后再看', style: TextStyle(fontSize: 16)),
        onTap: () {
          // TODO: Implement add to "watch later" logic
          Navigator.of(context).pop();
        },
      ),
    ];
  }
}

class VideoPlayerMenuAdapter extends TvMenuAdapter {
  final dynamic videoDetail;

  VideoPlayerMenuAdapter(this.videoDetail);

  @override
  List<Widget> buildMenuItems(BuildContext context) {
    return [
      ListTile(
        autofocus: true,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: const Icon(Icons.settings_outlined, size: 22),
        title: const Text('播放设置', style: TextStyle(fontSize: 16)),
        onTap: () {
          // TODO: Show player settings
          Navigator.of(context).pop();
        },
      ),
      ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: const Icon(Icons.subtitles_outlined, size: 22),
        title: const Text('字幕设置', style: TextStyle(fontSize: 16)),
        onTap: () {
          // TODO: Show subtitle settings
          Navigator.of(context).pop();
        },
      ),
    ];
  }
}

class DefaultMenuAdapter extends TvMenuAdapter {
  @override
  List<Widget> buildMenuItems(BuildContext context) {
    return [
      ListTile(
        autofocus: true,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: const Icon(Icons.exit_to_app, size: 22),
        title: const Text('退出程序', style: TextStyle(fontSize: 16)),
        onTap: () {
          // TODO: Implement exit logic
          Navigator.of(context).pop();
        },
      ),
      ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: const Icon(Icons.account_circle_outlined, size: 22),
        title: const Text('添加账户', style: TextStyle(fontSize: 16)),
        onTap: () {
          // TODO: Implement add account logic
          Navigator.of(context).pop();
        },
      ),
    ];
  }
}
