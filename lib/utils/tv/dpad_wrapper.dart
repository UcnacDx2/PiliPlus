import 'package:flutter/material.dart';
import 'package:dpad/dpad.dart';
import 'package:PiliPlus/utils/tv/tv_detector.dart';

class DpadPageWrapper extends StatelessWidget {
  final Widget child;
  final String? region;
  final bool enableMemory;

  const DpadPageWrapper({
    Key? key,
    required this.child,
    this.region,
    this.enableMemory = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!TVDetector.isTV) return child;

    return DpadRegionScope(
      region: region,
      enableMemory: enableMemory,
      child: child,
    );
  }
}
