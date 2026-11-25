import 'package:PiliPlus/fork/watermark/watermark_mode.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:hive_ce/hive.dart';

/// Preferences owned by the fork layer.
///
/// They are read directly from the shared settings box so that the upstream
/// `SettingBoxKey` / `Pref` files stay untouched, which keeps rebases small.
abstract final class ForkPref {
  static const watermarkModeKey = 'watermarkMode';
  static const useFirstFrameAsCoverKey = 'useFirstFrameAsCover';

  static Box get _setting => GStorage.setting;

  static int? _index(Object? value) =>
      value is int ? value : int.tryParse('$value');

  static WatermarkMode get watermarkMode =>
      WatermarkMode.fromStoredIndex(_index(_setting.get(watermarkModeKey)));

  static bool get useFirstFrameAsCover => _setting.get(
    useFirstFrameAsCoverKey,
    defaultValue: true,
  ) as bool;
}
