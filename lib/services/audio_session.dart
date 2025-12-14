import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/plugin/pl_player/models/play_status.dart';
import 'package:audio_session/audio_session.dart';

class AudioSessionHandler {
  late AudioSession session;
  bool _playInterrupted = false;
  String? bvid;

  void setBvid(String bvid) {
    this.bvid = bvid;
  }

  Future<bool> setActive(bool active) {
    return session.setActive(active);
  }

  AudioSessionHandler() {
    initSession();
  }

  Future<void> initSession() async {
    session = await AudioSession.instance;
    session.configure(const AudioSessionConfiguration.music());

    session.interruptionEventStream.listen((event) {
      final bvid = this.bvid;
      if (bvid == null) return;
      final playerStatus = PlPlayerController.getPlayerStatusIfExists(
        bvid,
      );
      if (event.begin) {
        if (playerStatus != PlayerStatus.playing) return;
        switch (event.type) {
          case AudioInterruptionType.duck:
            PlPlayerController.setVolumeIfExists(
              bvid,
              (PlPlayerController.getVolumeIfExists(
                    bvid,
                  ) ??
                  0) *
                  0.5,
            );
            break;
          case AudioInterruptionType.pause:
            PlPlayerController.pauseIfExists(
              tag: bvid,
              isInterrupt: true,
            );
            _playInterrupted = true;
            break;
          case AudioInterruptionType.unknown:
            PlPlayerController.pauseIfExists(
              tag: bvid,
              isInterrupt: true,
            );
            _playInterrupted = true;
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.duck:
            PlPlayerController.setVolumeIfExists(
              bvid,
              (PlPlayerController.getVolumeIfExists(
                    bvid,
                  ) ??
                  0) *
                  2,
            );
            break;
          case AudioInterruptionType.pause:
            if (_playInterrupted) {
              PlPlayerController.playIfExists(
                tag: bvid,
              );
            }
            break;
          case AudioInterruptionType.unknown:
            break;
        }
        _playInterrupted = false;
      }
    });

    // 耳机拔出暂停
    session.becomingNoisyEventStream.listen((_) {
      final bvid = this.bvid;
      if (bvid != null) {
        PlPlayerController.pauseIfExists(tag: bvid);
      }
    });
  }
}
