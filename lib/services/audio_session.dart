import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/plugin/pl_player/models/play_status.dart';
import 'package:audio_session/audio_session.dart';

class AudioSessionHandler {
  late AudioSession session;
  bool _playInterrupted = false;

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
      final instance = PlPlayerController.instance;
      if (instance == null) return;
      final playerStatus = PlPlayerController.getPlayerStatusIfExists(
        tag: instance.bvid,
      );
      if (event.begin) {
        if (playerStatus != PlayerStatus.playing) return;
        switch (event.type) {
          case AudioInterruptionType.duck:
            PlPlayerController.setVolumeIfExists(
              instance.bvid,
              (PlPlayerController.getVolumeIfExists(
                    tag: instance.bvid,
                  ) ??
                  0) *
                  0.5,
            );
            break;
          case AudioInterruptionType.pause:
            PlPlayerController.pauseIfExists(
              tag: instance.bvid,
              isInterrupt: true,
            );
            _playInterrupted = true;
            break;
          case AudioInterruptionType.unknown:
            PlPlayerController.pauseIfExists(
              tag: instance.bvid,
              isInterrupt: true,
            );
            _playInterrupted = true;
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.duck:
            PlPlayerController.setVolumeIfExists(
              instance.bvid,
              (PlPlayerController.getVolumeIfExists(
                    tag: instance.bvid,
                  ) ??
                  0) *
                  2,
            );
            break;
          case AudioInterruptionType.pause:
            if (_playInterrupted) {
              PlPlayerController.playIfExists(
                tag: instance.bvid,
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
      final instance = PlPlayerController.instance;
      if (instance != null) {
        PlPlayerController.pauseIfExists(tag: instance.bvid);
      }
    });
  }
}
