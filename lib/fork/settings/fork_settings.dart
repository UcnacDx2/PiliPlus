import 'package:PiliPlus/fork/fork_prefs.dart';
import 'package:PiliPlus/fork/watermark/watermark_mode.dart';
import 'package:PiliPlus/fork/watermark/watermark_position.dart';
import 'package:PiliPlus/pages/setting/models/model.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:material_ui/material_ui.dart';

/// Settings contributed by the fork.
///
/// They persist straight into the shared settings box through [ForkPref] keys,
/// so the upstream `SettingBoxKey` / `Pref` files stay untouched.
List<SettingsModel> get forkPlaySettings => [
  PopupModel(
    title: '水印处理',
    leading: const Icon(Icons.branding_watermark_outlined),
    value: () => ForkPref.watermarkMode,
    items: WatermarkMode.selectableValues,
    onSelected: (value, setState) {
      GStorage.setting
          .put(ForkPref.watermarkModeKey, value.index)
          .whenComplete(setState);
      SmartDialog.showToast('重新播放后生效');
    },
  ),
  PopupModel(
    title: '水印位置',
    leading: const Icon(Icons.pin_drop_outlined),
    value: () => ForkPref.watermarkPosition,
    items: WatermarkPosition.values,
    onSelected: (value, setState) {
      GStorage.setting
          .put(ForkPref.watermarkPositionKey, value.index)
          .whenComplete(setState);
    },
  ),
];

List<SettingsModel> get forkVideoSettings => [
  const SwitchModel(
    title: '使用视频第一帧作为封面',
    subtitle: '开启后会尝试获取视频第一帧，会增加网络请求',
    leading: Icon(Icons.photo_library_outlined),
    setKey: ForkPref.useFirstFrameAsCoverKey,
    defaultVal: true,
  ),
];
