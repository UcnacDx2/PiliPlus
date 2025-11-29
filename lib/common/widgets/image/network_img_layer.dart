import 'package:PiliPlus/common/constants.dart';
import 'package:PiliPlus/models/common/image_type.dart';
import 'package:PiliPlus/modules/cover_replace/cover_replace.dart';
import 'package:PiliPlus/utils/extension.dart';
import 'package:PiliPlus/utils/image_utils.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class NetworkImgLayer extends StatefulWidget {
  const NetworkImgLayer({
    super.key,
    required this.src,
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
    this.bvid,
    this.cid,
    this.aid,
  });

  final String? src;
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
  final String? bvid;
  final int? cid;
  final int? aid;

  static Color? reduceLuxColor = Pref.reduceLuxColor;
  static bool reduce = false;

  @override
  State<NetworkImgLayer> createState() => _NetworkImgLayerState();
}

class _NetworkImgLayerState extends State<NetworkImgLayer> {
  late String? _effectiveSrc;

  @override
  void initState() {
    super.initState();
    _effectiveSrc = widget.src;
    _fetchReplacedCover();
  }

  @override
  void didUpdateWidget(NetworkImgLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bvid != oldWidget.bvid ||
        widget.src != oldWidget.src ||
        widget.cid != oldWidget.cid ||
        widget.aid != oldWidget.aid) {
      setState(() {
        _effectiveSrc = widget.src;
      });
      _fetchReplacedCover();
    }
  }

  Future<void> _fetchReplacedCover() async {
    final replacedCover = await CoverReplaceService.getReplacedCover(
        widget.bvid, widget.cid, widget.aid);
    if (replacedCover != null && mounted) {
      setState(() {
        _effectiveSrc = replacedCover;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final noRadius = widget.type == ImageType.emote || widget.radius == 0;
    final Widget child;

    if (_effectiveSrc?.isNotEmpty == true) {
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
      imageUrl: ImageUtils.thumbnailUrl(_effectiveSrc, widget.quality),
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
      color: NetworkImgLayer.reduce ? NetworkImgLayer.reduceLuxColor : null,
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
