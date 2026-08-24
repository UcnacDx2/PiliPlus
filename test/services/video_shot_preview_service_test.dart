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

  test('maps evenly spaced frames across sprite pages', () {
    final data = VideoShotData(
      imgXLen: 4,
      imgYLen: 2,
      imgXSize: 160,
      imgYSize: 90,
      image: const ['page-0', 'page-1', 'page-2'],
      index: List.generate(20, (index) => index * 10),
    );

    final locations = VideoShotPreviewService.evenlySpacedLocations(data, 8);

    expect(locations, hasLength(8));
    expect(
      locations.map((item) => item.frameIndex),
      orderedEquals([...locations.map((item) => item.frameIndex)]..sort()),
    );
    expect(locations.map((item) => item.frameIndex).toSet(), hasLength(8));
    final secondPage = locations.firstWhere((item) => item.frameIndex >= 8);
    expect(secondPage.spriteUrl, 'page-1');
    expect(secondPage.column, secondPage.frameIndex % 8 % 4);
    expect(secondPage.row, secondPage.frameIndex % 8 ~/ 4);
  });

  test('rejects invalid evenly spaced frame requests', () {
    final data = VideoShotData(
      imgXLen: 4,
      imgYLen: 2,
      imgXSize: 160,
      imgYSize: 90,
      image: const ['page-0'],
      index: const [0, 10, 20],
    );

    expect(VideoShotPreviewService.evenlySpacedLocations(data, 0), isEmpty);
    data.index = const [];
    expect(VideoShotPreviewService.evenlySpacedLocations(data, 8), isEmpty);
  });

  test('parses pvdata as big-endian uint16 timestamps', () {
    expect(
      parseVideoShotIndexBytes(const [0, 0, 0, 0, 0, 10, 0, 20, 0, 240]),
      const [0, 0, 10, 20, 240],
    );
  });

  test('rejects malformed or decreasing pvdata', () {
    expect(parseVideoShotIndexBytes(const [0]), isEmpty);
    expect(parseVideoShotIndexBytes(const [0, 10, 0, 5]), isEmpty);
  });

  test('pvdata count determines the valid cells on the last sprite', () {
    final index = parseVideoShotIndexBytes(
      List<int>.generate(
        234,
        (byteIndex) => byteIndex.isEven ? 0 : byteIndex ~/ 2,
      ),
    );
    const capacityPerImage = 100;
    const imageCount = 2;
    final lastPageValid =
        index.length - (imageCount - 1) * capacityPerImage;
    expect(index.length, 117);
    expect(lastPageValid, 17);
  });

  test('accepts APP videoshot metadata without explicit frame size', () {
    final data = VideoShotData.fromJson({
      'pvdata': 'https://example.com/index.bin',
      'img_x_len': 10,
      'img_y_len': 10,
      'img_x_size': 0,
      'img_y_size': 0,
      'image': ['https://example.com/sprite.webp'],
    });
    data.index = const [0, 0, 3, 6, 9];

    final locations = VideoShotPreviewService.candidateLocations(data);

    expect(locations, isNotEmpty);
    expect(locations.first.spriteUrl, 'https://example.com/sprite.webp');
  });
}
