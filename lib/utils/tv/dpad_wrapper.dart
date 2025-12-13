import 'package:flutter/material.dart';

import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/utils/tv/tv_detector.dart';
import 'package:dpad/dpad.dart';

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
    if (!TVDetector.isTV && !Pref.enableTVMode) return child;

    return DpadRegionScope(
      region: region,
      enableMemory: enableMemory,
      child: child,
    );
  }
}
