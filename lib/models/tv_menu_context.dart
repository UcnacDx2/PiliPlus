import 'package:PiliPlus/plugin/pl_player/controller.dart';

enum TvMenuContextType {
  player,
  videoCard,
  liveRoom,
  none,
}

class TvMenuContextData {
  final TvMenuContextType type;
  final PlPlayerController? plPlayerController;
  // Add other controllers or data as needed for different contexts
  final dynamic videoItem;

  TvMenuContextData({
    required this.type,
    this.plPlayerController,
    this.videoItem,
  });
}
