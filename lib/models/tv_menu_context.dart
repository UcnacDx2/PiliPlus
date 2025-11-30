enum TvMenuContextType {
  player,
  videoCard,
  liveRoom,
}

class TvMenuContext {
  final TvMenuContextType type;
  final dynamic data;

  const TvMenuContext({
    required this.type,
    this.data,
  });
}
