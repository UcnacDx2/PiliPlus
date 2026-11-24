import 'package:PiliPlus/fork/watermark/watermark_mode.dart';
import 'package:PiliPlus/fork/watermark/watermark_position.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:hive_ce/hive.dart';

/// Preferences owned by the fork layer.
///
/// They are read directly from the shared settings box so that the upstream
/// `SettingBoxKey` / `Pref` files stay untouched, which keeps rebases small.
abstract final class ForkPref {
  static const watermarkModeKey = 'watermarkMode';
  static const watermarkPositionKey = 'watermarkPosition';
  static const useFirstFrameAsCoverKey = 'useFirstFrameAsCover';

  static Box get _setting => GStorage.setting;

  static int? _index(Object? value) =>
      value is int ? value : int.tryParse('$value');

  static WatermarkMode get watermarkMode {
    final index = _index(_setting.get(watermarkModeKey));
    return index == null
        ? WatermarkMode.disabled
        : WatermarkMode.values.elementAtOrNull(index) ?? WatermarkMode.disabled;
  }

  static WatermarkPosition get watermarkPosition {
    final index = _index(_setting.get(watermarkPositionKey));
    return index == null
        ? WatermarkPosition.topLeft
        : WatermarkPosition.values.elementAtOrNull(index) ??
              WatermarkPosition.topLeft;
  }

  static bool get useFirstFrameAsCover => _setting.get(
    useFirstFrameAsCoverKey,
    defaultValue: true,
  ) as bool;
}
