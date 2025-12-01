class FocusContext {
  final String pageType;
  final String? videoId;
  final String? roomId;
  final Map<String, dynamic> extraData;

  FocusContext({
    required this.pageType,
    this.videoId,
    this.roomId,
    this.extraData = const {},
  });
}
