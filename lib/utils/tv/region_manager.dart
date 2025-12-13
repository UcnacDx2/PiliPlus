import 'package:dpad/dpad.dart';
import 'package:flutter/widgets.dart';

class TVRegionManager {
  static List<RegionNavigationRule> get defaultRules => [
        // Bottom navigation -> Content area
        RegionNavigationRule(
          fromRegion: 'bottom_nav',
          toRegion: 'video_grid',
          direction: TraversalDirection.up,
          strategy: RegionNavigationStrategy.memory,
          bidirectional: true,
          reverseStrategy: RegionNavigationStrategy.fixedEntry,
        ),
        // Video card -> Player controls
        RegionNavigationRule(
          fromRegion: 'video_grid',
          toRegion: 'player_controls',
          direction: TraversalDirection.down,
          strategy: RegionNavigationStrategy.fixedEntry,
        ),
      ];
}
