import 'package:PiliPlus/utils/tv/tv_detector.dart';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

class DpadPageWrapper extends StatelessWidget {
  final Widget child;
  final String? region;
  final bool enableMemory;

  const DpadPageWrapper({
    super.key,
    required this.child,
    this.region,
    this.enableMemory = false,
  });

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
