import 'package:PiliPlus/models/common/enum_with_label.dart';

/// How the creator watermark is removed.
///
/// Migration from the pre-fork.6 enum: index 0 stays disabled, the old
/// "bilibili" (1), "advanced" (2) and "bilibiliAuto" (3) all map to [stroke].
enum WatermarkMode with EnumWithLabel {
  disabled('关闭'),
  stroke('精细（笔画级修复）'),
  box('整块覆盖'),
  ;

  static const selectableValues = [disabled, stroke, box];

  static WatermarkMode fromStoredIndex(int? index) {
    return switch (index) {
      null => disabled,
      1 || 2 || 3 => stroke,
      4 => box,
      _ => disabled,
    };
  }

  @override
  final String label;

  const WatermarkMode(this.label);
}
