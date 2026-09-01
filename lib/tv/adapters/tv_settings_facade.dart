import 'package:flutter/material.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/models/common/watermark_mode.dart';

enum VideoCodec {
  auto('自动'),
  avc('AVC'),
  hevc('HEVC'),
  av1('AV1');
  const VideoCodec(this.label);
  final String label;
}

abstract final class TvSettingsFacade {
  static final useFirstFrameAsCoverNotifier = ValueNotifier<bool>(false);
  static bool useFirstFrameAsCover = Pref.useFirstFrameAsCover;
  static bool splashAnimationEnabled = false;
  static bool alwaysShowPlayerTime = false;
  static bool get autoPlay => Pref.autoPlayEnable;
  static int get defaultVideoQa => Pref.defaultVideoQa;
  static bool hideControlsOnStart = false;
  static bool hideLiveControlsOnStart = false;
  static bool showMiniProgress = true;
  static bool seekPreviewMode = false;
  static int minimumRecommendDuration = 0;
  static VideoCodec preferredCodec = VideoCodec.auto;
  static WatermarkMode get watermarkMode => Pref.watermarkMode;
  static List<String> categoryOrder = ['recommend', 'popular'];
  static List<String> enabledCategories = ['recommend', 'popular'];
  static List<String> liveCategoryOrder = ['recommend', 'following'];
  static const liveCategoryLabels = {'recommend': '推荐', 'following': '关注'};
  static const liveCategoryIds = <String, int>{};
  static bool isCategoryEnabled(String name) => enabledCategories.contains(name);
  static bool isLiveCategoryEnabled(String name) => liveCategoryOrder.contains(name);
  static Future<void> setAutoPlay(bool value) async {
    await GStorage.setting.put(SettingBoxKey.autoPlayEnable, value);
  }
  static Future<void> setDefaultVideoQa(int value) async {
    await GStorage.setting.put(SettingBoxKey.defaultVideoQa, value);
  }
  static Future<void> setHideControlsOnStart(bool value) async => hideControlsOnStart = value;
  static Future<void> setShowMiniProgress(bool value) async => showMiniProgress = value;
  static Future<void> setSeekPreviewMode(bool value) async => seekPreviewMode = value;
  static Future<void> setPreferredCodec(VideoCodec value) async => preferredCodec = value;
  static Future<void> setMinimumRecommendDuration(int value) async => minimumRecommendDuration = value;
  static Future<void> setSplashAnimationEnabled(bool value) async => splashAnimationEnabled = value;
  static Future<void> setAlwaysShowPlayerTime(bool value) async => alwaysShowPlayerTime = value;
  static Future<void> setUseFirstFrameAsCover(bool value) async {
    await GStorage.setting.put(SettingBoxKey.useFirstFrameAsCover, value);
    useFirstFrameAsCover = value;
    useFirstFrameAsCoverNotifier.value = value;
  }
  static Future<void> setCategoryOrder(List<String> value) async => categoryOrder = value;
  static Future<void> setLiveCategoryOrder(List<String> value) async => liveCategoryOrder = value;
  static Future<void> toggleCategory(String name, bool value) async { if (value && !enabledCategories.contains(name)) enabledCategories = [...enabledCategories, name]; if (!value) enabledCategories = enabledCategories.where((e) => e != name).toList(); }
  static Future<void> toggleLiveCategory(String name, bool value) async {}
  static Future<double> getImageCacheSizeMB() async => 0;
  static Future<void> clearImageCache() async {}
  static void toast(BuildContext context, String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
