import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The upstream files only keep small, marked hook calls into `lib/fork/`.
///
/// This test pins those integration points down: if a rebase drops or renames
/// one of them, the suite fails instead of the feature silently disappearing.
void main() {
  String read(String path) => File(path).readAsStringSync();

  const hooks = <String, List<String>>{
    'lib/plugin/pl_player/controller.dart': [
      '// FORK:',
      'late final fork = PlPlayerFork(this);',
      'await fork.beforeOpen();',
      'fork.afterOpen(video, isLive: isLive);',
      'fork.started(',
      'await fork.afterShaderChanged(pp);',
      'if (fork.onStreamError(event)) return;',
      'fork.dispose();',
    ],
    'lib/pages/video/controller.dart': [
      '// FORK:',
      'ForkAccountPlayback.videoUrl(',
      'bindRenewer(forkRenewStream)',
      'get forkVideoType',
    ],
    'lib/http/video.dart': [
      '// FORK:',
      'Account? account',
      "Options(extra: {'account': account})",
    ],
    'lib/utils/page_utils.dart': [
      '// FORK:',
      'ForkAccountPlayback.pgcProgress(',
    ],
    'lib/common/widgets/video_card/video_card_v.dart': [
      '// FORK:',
      'FirstFrameOrCover(',
    ],
    'lib/common/widgets/video_card/video_card_h.dart': [
      '// FORK:',
      'FirstFrameOrCover(',
    ],
    'lib/pages/dynamics/widgets/video_panel.dart': [
      '// FORK:',
      'FirstFrameOrCover(',
    ],
    'lib/pages/setting/models/play_settings.dart': [
      '// FORK:',
      '...forkPlaySettings',
    ],
    'lib/pages/setting/models/video_settings.dart': [
      '// FORK:',
      '...forkVideoSettings',
    ],
  };

  for (final entry in hooks.entries) {
    test('${entry.key} keeps the fork integration points', () {
      final content = read(entry.key);
      for (final hook in entry.value) {
        expect(
          content,
          contains(hook),
          reason: '${entry.key} lost the fork hook "$hook"',
        );
      }
    });
  }
}
