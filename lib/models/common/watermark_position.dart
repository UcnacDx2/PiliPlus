import 'package:PiliPlus/models/common/enum_with_label.dart';

enum WatermarkPosition with EnumWithLabel {
  topLeft('左上'),
  topRight('右上'),
  bottomLeft('左下'),
  bottomRight('右下');

  @override
  final String label;

  const WatermarkPosition(this.label);
}
