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
      if (event.begin) {
        if (instance.playerStatus.value != PlayerStatus.playing) return;
        switch (event.type) {
          case AudioInterruptionType.duck:
            instance.setVolume(instance.volume.value * 0.5);
            break;
          case AudioInterruptionType.pause:
            instance.pause(isInterrupt: true);
            _playInterrupted = true;
            break;
          case AudioInterruptionType.unknown:
            instance.pause(isInterrupt: true);
            _playInterrupted = true;
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.duck:
            instance.setVolume(instance.volume.value * 2);
            break;
          case AudioInterruptionType.pause:
            if (_playInterrupted) {
              instance.play();
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
      PlPlayerController.instance?.pause();
    });
  }
}
