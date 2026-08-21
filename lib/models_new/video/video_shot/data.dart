import 'dart:typed_data';

import 'package:PiliPlus/utils/extension/iterable_ext.dart';
import 'package:PiliPlus/utils/extension/string_ext.dart';

List<int> parseVideoShotIndexBytes(List<int> bytes) {
  if (bytes.isEmpty || bytes.length.isOdd) return const [];
  final data = ByteData.sublistView(Uint8List.fromList(bytes));
  final index = List<int>.generate(
    bytes.length ~/ 2,
    (offset) => data.getUint16(offset * 2, Endian.big),
    growable: false,
  );
  for (var i = 1; i < index.length; i++) {
    if (index[i] < index[i - 1]) return const [];
  }
  return index;
}

class VideoShotData {
  String? pvdata;
  int imgXLen;
  int imgYLen;
  double imgXSize;
  double imgYSize;
  late final int totalPerImage = imgXLen * imgYLen;
  List<String> image;
  List<int> index;

  VideoShotData({
    this.pvdata,
    required this.imgXLen,
    required this.imgYLen,
    required this.imgXSize,
    required this.imgYSize,
    required this.image,
    required this.index,
  });

  factory VideoShotData.fromJson(Map<String, dynamic> json) => VideoShotData(
    pvdata: json["pvdata"],
    imgXLen: json["img_x_len"],
    imgYLen: json["img_y_len"],
    imgXSize: (json["img_x_size"] as num).toDouble(),
    imgYSize: (json["img_y_size"] as num).toDouble(),
    image: (json["image"] as List)
        .map((e) => (e as String).http2https)
        .toList(),
    index: (json["index"] as List).fromCast(),
  );
}