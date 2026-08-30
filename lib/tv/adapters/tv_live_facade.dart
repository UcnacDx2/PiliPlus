import 'dart:async';
import 'package:PiliPlus/http/live.dart';
import 'package:PiliPlus/models_new/live/live_feed_index/card_data_list_item.dart';
import 'package:PiliPlus/models_new/live/live_follow/item.dart';

/// Live UI facade. Its implementation is intentionally narrow so the BiliTV
/// live presentation does not import a second API/account stack.
abstract final class TvLiveFacade {
  static Map<String, dynamic> _room(CardLiveItem room) => {
    'roomid': room.roomid ?? 0, 'uid': room.uid ?? 0, 'uname': room.uname ?? '',
    'face': room.face ?? '', 'cover': room.cover ?? room.systemCover ?? '',
    'title': room.title ?? '', 'area_name': room.areaName ?? '', 'online': 0,
  };
  static Map<String, dynamic> _followed(LiveFollowItem room) => {
    'roomid': room.roomid ?? 0, 'uname': room.uname ?? '', 'title': room.title ?? '',
    'room_cover': room.roomCover ?? '', 'online': room.textSmall ?? 0,
  };
  static Future<List<Map<String, dynamic>>> getFollowedLive({int page = 1, int pageSize = 20}) async {
    final state = await LiveHttp.liveFollow(page);
    return state.dataOrNull?.list?.map(_followed).toList() ?? const <Map<String, dynamic>>[];
  }
  static Future<List<Map<String, dynamic>>> getRecommended({int page = 1, int pageSize = 30, int? parentId}) async {
    if (parentId != null) {
      final state = await LiveHttp.liveSecondList(pn: page, areaId: null, parentAreaId: parentId);
      return state.dataOrNull?.cardList?.map(_room).toList() ?? const <Map<String, dynamic>>[];
    }
    final state = await LiveHttp.liveFeedIndex(pn: page);
    final data = state.dataOrNull;
    if (data == null) return const <Map<String, dynamic>>[];
    return data.cardList
            ?.expand((item) => item.cardData?.smallCardV1 == null
                ? const <CardLiveItem>[]
                : [item.cardData!.smallCardV1!])
            .map(_room)
            .toList() ??
        const <Map<String, dynamic>>[];
  }
  static Future<Map<String, dynamic>?> getRoomInfo(int roomId) async {
    final state = await LiveHttp.liveRoomInfoH5(roomId: roomId);
    final data = state.dataOrNull;
    final room = data?.roomInfo;
    return room == null ? null : {'room_id': roomId, 'uid': room.uid ?? 0, 'title': room.title ?? '', 'cover': room.cover ?? ''};
  }
  static Future<Map<String, dynamic>?> getPlayUrl(int roomId, {int qn = 10000}) async {
    final state = await LiveHttp.liveRoomInfo(roomId: roomId, qn: qn);
    final data = state.dataOrNull;
    final playurl = data?.playurlInfo?.playurl;
    if (playurl == null) return null;
    return {'playurl_info': {'playurl': {'stream': playurl.stream.map((stream) => {
      'protocol_name': stream.protocolName,
      'format': stream.format.map((format) => {'format_name': format.formatName, 'codec': format.codec.map((codec) => {
        'codec_name': codec.codecName, 'current_qn': codec.currentQn, 'accept_qn': codec.acceptQn,
        'base_url': codec.baseUrl, 'url_info': codec.urlInfo.map((url) => {'host': url.host, 'extra': url.extra}).toList(),
      }).toList()}).toList(),
    }).toList()}}};
  }
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
