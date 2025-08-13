import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

class LocalServer {
  static final LocalServer _instance = LocalServer._internal();
  factory LocalServer() => _instance;
  LocalServer._internal();

  HttpServer? _server;

  Future<void> start() async {
    if (_server != null) {
      print("Server already running");
      return;
    }

    final app = Router();

    app.get('/', _handleImageRequest);

    final handler = const Pipeline().addHandler(app);

    try {
      _server = await io.serve(handler, '127.0.0.1', 8080);
      print('Server running on localhost:${_server!.port}');
    } catch (e) {
      print('Error starting server: $e');
    }
  }

  Future<Response> _handleImageRequest(Request request) async {
    final aid = request.url.queryParameters['aid'];
    final bvid = request.url.queryParameters['bvid'];

    if (aid == null && bvid == null) {
      return Response(400, body: 'Missing aid or bvid');
    }

    try {
      final apiUrl = Uri.parse('https://api.bilibili.com/x/player/videoshot');
      final params = {'index': '1'};
      if (bvid != null) {
        params['bvid'] = bvid;
      } else if (aid != null) {
        params['aid'] = aid;
      }
      
      final res = await http.get(apiUrl.replace(queryParameters: params));
      final json = jsonDecode(res.body);

      if (json['code'] != 0 || json['data']?['image'] == null || json['data']?['index'] == null) {
        return Response(502, body: 'Failed to fetch bilibili data');
      }

      final data = json['data'];
      final List<String> image = List<String>.from(data['image']);
      final List<int> index = List<int>.from(data['index']);
      final int imgXLen = data['img_x_len'];
      final int imgYLen = data['img_y_len'];
      final int imgXSize = data['img_x_size'];
      final int imgYSize = data['img_y_size'];

      if (index.isEmpty || image.isEmpty) {
        return Response(404, body: 'No image/index data');
      }

      final totalPerImage = imgXLen * imgYLen;
      final mid = (index.length - 1) ~/ 2;
      final pageIndex = mid ~/ totalPerImage;
      final indexInPage = mid % totalPerImage;
      final xIndex = indexInPage % imgXLen;
      final yIndex = indexInPage ~/ imgXLen;

      String fullImageUrl = image[pageIndex];
      if (fullImageUrl.startsWith("//")) {
        fullImageUrl = "https:" + fullImageUrl;
      }

      final imageRes = await http.get(Uri.parse(fullImageUrl));
      final imageBuffer = imageRes.bodyBytes;

      final img.Image? baseImage = img.decodeImage(imageBuffer);
      if (baseImage == null) {
        return Response(500, body: 'Failed to decode image');
      }
      
      final crop = img.copyCrop(baseImage, x: xIndex * imgXSize, y: yIndex * imgYSize, width: imgXSize, height: imgYSize);
      final jpeg = img.encodeJpg(crop);

      return Response.ok(jpeg, headers: {
        'Content-Type': 'image/jpeg',
        'Cache-Control': 'public, max-age=3600',
      });
    } catch (e) {
      return Response(500, body: 'Internal server error: $e');
    }
  }

  void stop() {
    _server?.close();
    _server = null;
    print('Server stopped');
  }
}