import 'package:PiliPlus/models_new/history/data.dart';
import 'package:PiliPlus/models_new/history/history.dart';
import 'package:PiliPlus/models_new/history/list.dart';
import 'package:PiliPlus/services/playback_resume_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  HistoryData data({String? bvid, int? cid, int? epId, int? progress}) =>
      HistoryData(
        list: [
          HistoryItemModel(
            history: History(bvid: bvid, cid: cid, epid: epId),
            progress: progress,
          ),
        ],
      );

  test('same account delegates progress to play-url response', () async {
    var calls = 0;
    final progress = await resolvePlaybackResumeProgress(
      sameAccount: true,
      explicitProgress: null,
      bvid: 'BV1test',
      cid: 1,
      epId: null,
      loadHistory: (_) async {
        calls++;
        return null;
      },
    );
    expect(progress, isNull);
    expect(calls, 0);
  });

  test('explicit progress has priority', () async {
    var calls = 0;
    final progress = await resolvePlaybackResumeProgress(
      sameAccount: false,
      explicitProgress: 1234,
      bvid: 'BV1test',
      cid: 1,
      epId: null,
      loadHistory: (_) async {
        calls++;
        return null;
      },
    );
    expect(progress, 1234);
    expect(calls, 0);
  });

  test('cross-account UGC matches bvid and cid', () async {
    final progress = await resolvePlaybackResumeProgress(
      sameAccount: false,
      explicitProgress: null,
      bvid: 'BV1test',
      cid: 2,
      epId: null,
      loadHistory: (_) async => data(bvid: 'bv1TEST', cid: 2, progress: 42),
    );
    expect(progress, 42000);
  });

  test('cross-account PGC matches episode id', () async {
    final progress = await resolvePlaybackResumeProgress(
      sameAccount: false,
      explicitProgress: null,
      bvid: null,
      cid: null,
      epId: 323056,
      loadHistory: (keyword) async {
        expect(keyword, '323056');
        return data(epId: 323056, progress: 88);
      },
    );
    expect(progress, 88000);
  });

  test('completed history explicitly starts at zero', () async {
    final progress = await resolvePlaybackResumeProgress(
      sameAccount: false,
      explicitProgress: null,
      bvid: 'BV1test',
      cid: 1,
      epId: null,
      loadHistory: (_) async => data(bvid: 'BV1test', cid: 1, progress: -1),
    );
    expect(progress, 0);
  });
}
