import 'package:PiliPlus/models/common/enum_with_label.dart';

enum WatermarkMode with EnumWithLabel {
  disabled('关闭'),
  bilibili('普通（bilibili）'),
  advanced('进阶（多帧检测）'),
  ;

  @override
  final String label;

  const WatermarkMode(this.label);
}
