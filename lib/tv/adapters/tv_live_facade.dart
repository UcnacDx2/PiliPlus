import 'dart:async';

/// Live UI facade. Its implementation is intentionally narrow so the BiliTV
/// live presentation does not import a second API/account stack.
abstract final class TvLiveFacade {
  static Future<List<Map<String, dynamic>>> getFollowedLive({int page = 1, int pageSize = 20}) async => const [];
  static Future<List<Map<String, dynamic>>> getRecommended({int page = 1, int pageSize = 30, int? parentId}) async => const [];
  static Future<Map<String, dynamic>?> getRoomInfo(int roomId) async => null;
  static Future<Map<String, dynamic>?> getPlayUrl(int roomId, {int qn = 10000}) async => null;
  static Future<Map<String, dynamic>?> getRelation(int mid) async => null;
  static Future<bool> modifyRelation(int mid, int action) async => false;
}

abstract final class TvLiveValueFacade {
  static int toInt(dynamic value) => value is int ? value : int.tryParse('$value') ?? 0;
}

class TvLiveSocketFacade {
  bool isConnected = false;
  final StreamController<Map<String, dynamic>> _messages = StreamController.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _messages.stream;
  void connect(int roomId) => isConnected = true;
  Future<void> dispose() async { isConnected = false; await _messages.close(); }
}
