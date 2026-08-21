import 'package:PiliPlus/models_new/video/video_shot/data.dart';
import 'package:PiliPlus/services/video_shot_preview_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps middle candidates using the sprite column count', () {
    final data = VideoShotData(
      imgXLen: 4,
      imgYLen: 3,
      imgXSize: 160,
      imgYSize: 90,
      image: const ['page-0', 'page-1'],
      index: List.generate(20, (index) => index * 10),
    );

    final locations = VideoShotPreviewService.candidateLocations(data);

    expect(locations.first.frameIndex, 10);
    expect(locations.first.spriteUrl, 'page-0');
    expect(locations.first.column, 2);
    expect(locations.first.row, 2);

    final secondPage = locations.singleWhere((item) => item.frameIndex == 12);
    expect(secondPage.spriteUrl, 'page-1');
    expect(secondPage.column, 0);
    expect(secondPage.row, 0);
  });

  test('deduplicates candidate indexes for short videos', () {
    final data = VideoShotData(
      imgXLen: 5,
      imgYLen: 2,
      imgXSize: 160,
      imgYSize: 90,
      image: const ['page-0'],
      index: const [0, 10],
    );

    final locations = VideoShotPreviewService.candidateLocations(data);

    expect(locations.map((item) => item.frameIndex).toSet().length,
        locations.length);
  });
}
