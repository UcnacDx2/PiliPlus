import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cached_network_image_ce/cached_network_image.dart';

/// 交错加载图片组件
/// 用于在低端硬件上避免同时解码多张图片导致的卡顿
class StaggeredImage extends StatefulWidget {
  final String imageUrl;
  final int delayMs;
  final double? width;
  final double? height;
  final BoxFit fit;
  final int? cacheWidth;
  final int? cacheHeight;

  const StaggeredImage({
    super.key,
    required this.imageUrl,
    this.delayMs = 0,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.cacheHeight,
  });

  @override
  State<StaggeredImage> createState() => _StaggeredImageState();
}

class _StaggeredImageState extends State<StaggeredImage> {
  bool _shouldLoad = false;

  @override
  void initState() {
    super.initState();
    if (widget.delayMs <= 0) {
      _shouldLoad = true;
    } else {
      Future.delayed(Duration(milliseconds: widget.delayMs), () {
        if (mounted) {
          setState(() => _shouldLoad = true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldLoad) {
      // 占位：显示灰色背景，避免布局跳动
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey[900],
      );
    }

    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 150),
      child: CachedNetworkImage(
        imageUrl: widget.imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        memCacheWidth: widget.cacheWidth,
        memCacheHeight: widget.cacheHeight, // 使用有限制的缓存管理器
        fadeInDuration: const Duration(milliseconds: 100),
        fadeOutDuration: Duration.zero,
        placeholder: (context, url) => Container(color: Colors.grey[900]),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[800],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      ),
    );
  }
}

/// Delays building an arbitrary child without changing the child's loading
/// strategy. This is important for cards that need FirstFrameOrCover logic.
class StaggeredBuilder extends StatefulWidget {
  final int delayMs;
  final WidgetBuilder builder;

  const StaggeredBuilder({
    super.key,
    required this.delayMs,
    required this.builder,
  });

  @override
  State<StaggeredBuilder> createState() => _StaggeredBuilderState();
}

class _StaggeredBuilderState extends State<StaggeredBuilder> {
  Timer? _timer;
  bool _shouldBuild = false;

  @override
  void initState() {
    super.initState();
    _scheduleBuild();
  }

  @override
  void didUpdateWidget(covariant StaggeredBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.delayMs != widget.delayMs && !_shouldBuild) {
      _timer?.cancel();
      _scheduleBuild();
    }
  }

  void _scheduleBuild() {
    if (widget.delayMs <= 0) {
      _shouldBuild = true;
    } else {
      _timer = Timer(Duration(milliseconds: widget.delayMs), () {
        if (mounted) setState(() => _shouldBuild = true);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldBuild) {
      return Container(color: Colors.grey[900]);
    }
    return widget.builder(context);
  }
}
