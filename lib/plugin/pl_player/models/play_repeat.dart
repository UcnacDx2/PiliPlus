enum PlayRepeat {
  pause('播完暂停'),
  listOrder('顺序播放'),
  singleCycle('单个循环'),
  listCycle('列表循环'),
  autoPlayRelated('自动连播')
  ;

  final String desc;
  const PlayRepeat(this.desc);
}

extension PlayRepeatExtension on PlayRepeat {
  PlayRepeat get next {
    final values = PlayRepeat.values;
    final nextIndex = (index + 1) % values.length;
    return values[nextIndex];
  }
}
