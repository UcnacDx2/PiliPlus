import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class TvDebugController extends GetxController {
  final logs = <String>[].obs;

  KeyEventResult onKey(FocusNode node, RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      logs.add('Key Down: ${event.logicalKey.keyLabel}');
    } else if (event is RawKeyUpEvent) {
      logs.add('Key Up: ${event.logicalKey.keyLabel}');
    }
    return KeyEventResult.handled;
  }
}
