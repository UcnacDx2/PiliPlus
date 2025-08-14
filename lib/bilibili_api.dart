// lib/bilibili_api.dart

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

Uint8List? _processImageIsolate(Map<String, dynamic> params) {
  // ... 这个顶层函数保持不变 ...
  final Uint8List imageBuffer = params['buffer'];
  final int x = params['x'];
  final int y = params['y'];
  final int width = params['width'];
  final int height = params['height'];

  try {
    final img.Image? decodedImage = img.decodeImage(imageBuffer);
    if (decodedImage == null) return null;
    final crop = img.copyCrop(
      decodedImage,
      x: x,
      y: y,
      width: width,
      height: height,
    );
    return Uint8List.fromList(img.encodeJpg(crop));
  } catch (e) {
    print("Error in image processing isolate: $e");
    return null;
  }
}

class BilibiliApi {
  // [修改 1] 实现单例模式
  // 创建一个私有的静态实例
  static final BilibiliApi _instance = BilibiliApi._internal();

  // 提供一个工厂构造函数，总是返回同一个实例
  factory BilibiliApi() {
    return _instance;
  }

  // 创建一个私有的命名构造函数
  BilibiliApi._internal();

  // [修改 2] 添加一个缓存 Map
  // Key 是视频的唯一标识 (e.g., "b_BV1GJ411x7h7")
  // Value 是 Future<Uint8List?> 本身
  final Map<String, Future<Uint8List?>> _cache = {};

  // getThumbnail 现在是缓存的入口
  Future<Uint8List?> getThumbnail({String? aid, String? bvid}) async {
    // [修改 3] 缓存逻辑
    if ((aid == null || aid.isEmpty) && (bvid == null || bvid.isEmpty)) {
      return null;
    }

    // 创建唯一的缓存 Key
    final key = bvid != null ? 'b_$bvid' : 'a_$aid';

    // 如果缓存中已存在这个 key，直接返回缓存的 Future
    if (_cache.containsKey(key)) {
      // print('✅ Cache HIT for key: $key');
      return _cache[key]!;
    }

    // 如果缓存中没有，创建一个新的 Future，并存入缓存
    // print('❌ Cache MISS for key: $key. Fetching...');
    final future = _fetchAndProcessThumbnail(aid: aid, bvid: bvid);
    _cache[key] = future;

    // 同时返回这个新的 Future
    return future;
  }

  // [修改 4] 将原始的逻辑封装到一个私有方法中
  Future<Uint8List?> _fetchAndProcessThumbnail({
    String? aid,
    String? bvid,
  }) async {
    // 这里的代码就是你原来的 getThumbnail 的完整逻辑
    try {
      final apiUrl = Uri.https('api.bilibili.com', '/x/player/videoshot', {
        if (aid != null) 'aid': aid,
        if (bvid != null) 'bvid': bvid,
        'index': '1',
      });
      final res = await http.get(apiUrl);
      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.body);
      if (json['code'] != 0 || json['data']?['image'] == null) return null;

      final data = json['data'];
      final List? imageList = data['image'];
      final List? indexList = data['index'];
      if (imageList == null ||
          imageList.isEmpty ||
          indexList == null ||
          indexList.isEmpty) {
        return null;
      }

      final List<String> image = List<String>.from(imageList);
      final List<dynamic> index = List<dynamic>.from(indexList);
      final int imgXLen = data['img_x_len'];
      final int imgYLen = data['img_y_len'];
      final int imgXSize = data['img_x_size'];
      final int imgYSize = data['img_y_size'];
      final totalPerImage = imgXLen * imgYLen;
      if (totalPerImage <= 0) return null;
      final mid = (index.length - 1) ~/ 2;
      final pageIndex = mid ~/ totalPerImage;
      if (pageIndex >= image.length) return null;
      final indexInPage = mid % totalPerImage;
      final xIndex = indexInPage % imgXLen;
      final yIndex = indexInPage ~/ imgXLen;
      String fullImageUrl = image[pageIndex];
      if (fullImageUrl.startsWith('//')) {
        fullImageUrl = 'https:$fullImageUrl';
      }
      final imageRes = await http.get(Uri.parse(fullImageUrl));
      if (imageRes.statusCode != 200) return null;
      final Uint8List imageBuffer = imageRes.bodyBytes;

      final Map<String, dynamic> params = {
        'buffer': imageBuffer,
        'x': xIndex * imgXSize,
        'y': yIndex * imgYSize,
        'width': imgXSize,
        'height': imgYSize,
      };

      return await compute(_processImageIsolate, params);
    } catch (e) {
      print('An unexpected error occurred in _fetchAndProcessThumbnail: $e');
      // 如果获取失败，从缓存中移除这个失败的 Future，以便下次可以重试
      final key = bvid != null ? 'b_$bvid' : 'a_$aid';
      _cache.remove(key);
      return null;
    }
  }
}
