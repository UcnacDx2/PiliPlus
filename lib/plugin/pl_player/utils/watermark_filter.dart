import 'package:PiliPlus/plugin/pl_player/models/watermark_region.dart';
import 'package:media_kit/media_kit.dart';

abstract final class WatermarkFilter {
  static const _labelPrefix = 'piliplus-watermark-';
  static const maxRegions = 4;

  static Future<void> clear(Player player) async {
    for (var index = 0; index < maxRegions; index++) {
      try {
        await player.command(['vf', 'remove', '@$_labelPrefix$index']);
      } catch (_) {
        // Removing a label which is not currently present is harmless.
      }
    }
  }

  static Future<void> apply(
    Player player,
    List<WatermarkRegion> regions,
    int videoWidth,
    int videoHeight,
  ) async {
    await clear(player);
    for (var index = 0; index < regions.length && index < maxRegions; index++) {
      await player.command(
        commandFor(regions[index], index, videoWidth, videoHeight),
      );
    }
  }

  static List<String> commandFor(
    WatermarkRegion region,
    int index,
    int videoWidth,
    int videoHeight,
  ) {
    final rect = region.toPixelRegion(videoWidth, videoHeight);
    return [
      'vf',
      'add',
      '@$_labelPrefix$index:lavfi=[delogo=x=${rect.x}:y=${rect.y}:'
          'w=${rect.width}:h=${rect.height}:show=0]',
    ];
  }
}
