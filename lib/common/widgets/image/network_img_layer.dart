import 'dart:developer';
import 'dart:typed_data';
import 'package:PiliPlus/common/constants.dart';
import 'package:PiliPlus/models/common/image_type.dart';
import 'package:PiliPlus/utils/extension.dart';
import 'package:PiliPlus/utils/image_utils.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

const double _kBrightnessThreshold = 0.2;
const double _kDarkPixelPercentage = 0.5;

bool _isImageMostlyDark(Uint8List imageBytes) {
  final image = img.decodeImage(imageBytes);
  if (image == null) {
    return false;
  }
  int darkPixels = 0;
  final totalPixels = image.width * image.height;

  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      final r = pixel.r;
      final g = pixel.g;
      final b = pixel.b;
      final brightness = (r * 0.299 + g * 0.587 + b * 0.114) / 255;
      if (brightness < _kBrightnessThreshold) {
        darkPixels++;
      }
    }
  }

  return (darkPixels / totalPixels) > _kDarkPixelPercentage;
}

class NetworkImgLayer extends StatefulWidget {
  const NetworkImgLayer({
    super.key,
    required this.src,
    this.firstFrame,
    required this.width,
    this.height,
    this.type = ImageType.def,
    this.fadeOutDuration,
    this.fadeInDuration,
    // 图片质量 默认1%
    this.quality,
    this.semanticsLabel,
    this.radius,
    this.imageBuilder,
    this.isLongPic = false,
    this.forceUseCacheWidth = false,
    this.getPlaceHolder,
    this.boxFit,
  });

  final String? src;
  final String? firstFrame;
  final double width;
  final double? height;
  final ImageType type;
  final Duration? fadeOutDuration;
  final Duration? fadeInDuration;
  final int? quality;
  final String? semanticsLabel;
  final double? radius;
  final ImageWidgetBuilder? imageBuilder;
  final bool isLongPic;
  final bool forceUseCacheWidth;
  final Widget Function()? getPlaceHolder;
  final BoxFit? boxFit;

  static Color? reduceLuxColor = Pref.reduceLuxColor;
  static bool reduce = false;

  @override
  State<NetworkImgLayer> createState() => _NetworkImgLayerState();
}

class _NetworkImgLayerState extends State<NetworkImgLayer> {
  late String? _activeSrc;

  @override
  void initState() {
    super.initState();
    _activeSrc = widget.src;
    _processFirstFrame();
  }

  @override
  void didUpdateWidget(covariant NetworkImgLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.src != oldWidget.src) {
      setState(() {
        _activeSrc = widget.src;
      });
      _processFirstFrame();
    }
  }

  Future<void> _processFirstFrame() async {
    if (widget.firstFrame != null && widget.firstFrame!.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(widget.firstFrame!));
        if (response.statusCode == 200) {
          final isDark = await compute(_isImageMostlyDark, response.bodyBytes);
          if (!isDark) {
            if (mounted) {
              setState(() {
                _activeSrc = widget.firstFrame;
              });
            }
          }
        }
      } catch (e) {
        log('Failed to process first frame: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final noRadius = widget.type == ImageType.emote || widget.radius == 0;
    final Widget child;

    if (_activeSrc?.isNotEmpty == true) {
      child = noRadius
          ? _buildImage(context, noRadius)
          : widget.type == ImageType.avatar
              ? ClipOval(child: _buildImage(context, noRadius))
              : ClipRRect(
                  borderRadius: widget.radius != null
                      ? BorderRadius.circular(widget.radius!)
                      : StyleString.mdRadius,
                  child: _buildImage(context, noRadius),
                );
    } else {
      child =
          widget.getPlaceHolder?.call() ?? _placeholder(context, noRadius);
    }

    return widget.semanticsLabel?.isNotEmpty == true
        ? Semantics(
            container: true,
            image: true,
            excludeSemantics: true,
            label: widget.semanticsLabel,
            child: child,
          )
        : child;
  }

  Widget _buildImage(BuildContext context, bool noRadius) {
    int? memCacheWidth, memCacheHeight;
    if (widget.height == null ||
        widget.forceUseCacheWidth ||
        widget.width <= widget.height!) {
      memCacheWidth = widget.width.cacheSize(context);
    } else {
      memCacheHeight = widget.height?.cacheSize(context);
    }
    return CachedNetworkImage(
      imageUrl: ImageUtils.thumbnailUrl(_activeSrc, widget.quality),
      width: widget.width,
      height: widget.height,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      fit: widget.boxFit ?? BoxFit.cover,
      alignment: widget.isLongPic ? Alignment.topCenter : Alignment.center,
      fadeOutDuration:
          widget.fadeOutDuration ?? const Duration(milliseconds: 120),
      fadeInDuration:
          widget.fadeInDuration ?? const Duration(milliseconds: 120),
      filterQuality: FilterQuality.low,
      placeholder: (BuildContext context, String url) =>
          widget.getPlaceHolder?.call() ?? _placeholder(context, noRadius),
      imageBuilder: widget.imageBuilder,
      errorWidget: (context, url, error) => _placeholder(context, noRadius),
      colorBlendMode: NetworkImgLayer.reduce ? BlendMode.modulate : null,
      color:
          NetworkImgLayer.reduce ? NetworkImgLayer.reduceLuxColor : null,
    );
  }

  Widget _placeholder(BuildContext context, bool noRadius) {
    final isAvatar = widget.type == ImageType.avatar;
    return Container(
      width: widget.width,
      height: widget.height,
      clipBehavior: noRadius ? Clip.none : Clip.antiAlias,
      decoration: BoxDecoration(
        shape: isAvatar ? BoxShape.circle : BoxShape.rectangle,
        color: Theme.of(
          context,
        ).colorScheme.onInverseSurface.withValues(alpha: 0.4),
        borderRadius: noRadius || isAvatar
            ? null
            : widget.radius != null
                ? BorderRadius.circular(widget.radius!)
                : StyleString.mdRadius,
      ),
      child: Center(
        child: Image.asset(
          isAvatar
              ? 'assets/images/noface.jpeg'
              : 'assets/images/loading.png',
          width: widget.width,
          height: widget.height,
          cacheWidth: widget.width.cacheSize(context),
          colorBlendMode: NetworkImgLayer.reduce ? BlendMode.modulate : null,
          color:
              NetworkImgLayer.reduce ? NetworkImgLayer.reduceLuxColor : null,
        ),
      ),
    );
  }
}
