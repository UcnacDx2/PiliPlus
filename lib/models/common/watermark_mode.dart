import 'package:PiliPlus/models/common/enum_with_label.dart';

enum WatermarkMode with EnumWithLabel {
  disabled('关闭'),
  bilibili('普通（bilibili）'),
  advanced('进阶（全部水印）'),
  // Keep this value appended so persisted index 2 continues to mean the
  // existing advanced mode after upgrading.
  bilibiliAuto('进阶（仅 bilibili）'),
  ;

  static const selectableValues = [
    disabled,
    bilibili,
    bilibiliAuto,
    advanced,
  ];

  @override
  final String label;

  const WatermarkMode(this.label);
}
