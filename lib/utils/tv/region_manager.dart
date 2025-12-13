import 'package:dpad/dpad.dart';

class TVRegionManager {
  static List<RegionNavigationRule> get defaultRules => [
        // 底部导航 → 内容区
        RegionNavigationRule(
          fromRegion: 'bottom_nav',
          toRegion: 'video_grid',
          direction: TraversalDirection.up,
          strategy: RegionNavigationStrategy.memory,
          bidirectional: true,
          reverseStrategy: RegionNavigationStrategy.fixedEntry,
        ),
        // 视频卡片 → 播放器控制
        RegionNavigationRule(
          fromRegion: 'video_grid',
          toRegion: 'player_controls',
          direction: TraversalDirection.down,
          strategy: RegionNavigationStrategy.fixedEntry,
        ),
      ];
}
