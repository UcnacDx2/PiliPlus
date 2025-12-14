import 'package:PiliPlus/pages/common/common_intro_controller.dart';
import 'package:PiliPlus/models_new/video/video_detail/stat_detail.dart';
import 'package:flutter/material.dart';

class DummyIntroController extends CommonIntroController {
  @override
  void actionLikeVideo() {
    // Do nothing
  }

  @override
  void actionTriple() {
    // Do nothing
  }

  @override
  StatDetail? getStat() {
    return null;
  }

  @override
  void queryVideoIntro() {
    // Do nothing
  }

  @override
  bool prevPlay() {
    return false;
  }

  @override
  bool nextPlay() {
    return false;
  }

  @override
  void actionCoinVideo() {
    // Do nothing
  }

  @override
  void actionShareVideo(BuildContext context) {
    // Do nothing
  }

  @override
  (Object, int) get getFavRidType => ('', 0);
}
