import 'dart:async';
import 'dart:typed_data';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:PiliPlus/tv/adapters/tv_settings_facade.dart';

/// Displays a normal cover immediately, then replaces it with a meaningful
/// first frame. Black/flat first frames fall back to a videoshot frame.
class FirstFrameOrCover extends StatefulWidget {
  const FirstFrameOrCover({
    super.key,
    required this.coverUrl,
    this.firstFrameUrl,
    this.bvid,
    this.cid,
    this.resolveMissingFirstFrame = false,
    this.inspectDelay = Duration.zero,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
  });

  final String coverUrl;
  final String? firstFrameUrl;
  final String? bvid;
  final int? cid;
  final bool resolveMissingFirstFrame;
  final Duration inspectDelay;
  final double width;
  final double height;
  final BoxFit fit;

  @override
  State<FirstFrameOrCover> createState() => _FirstFrameOrCoverState();
}

class _FirstFrameOrCoverState extends State<FirstFrameOrCover> {
  String? _acceptedFirstFrame;
  int _generation = 0;
  Timer? _inspectTimer;

  @override
  void initState() {
    super.initState();
    TvSettingsFacade.useFirstFrameAsCoverNotifier.addListener(
      _onCoverSettingChanged,
    );
    _scheduleInspect();
  }

  void _scheduleInspect() {
    _inspectTimer?.cancel();
    // Invalidate any in-flight work before waiting for the next inspect.
    _generation++;
    if (!TvSettingsFacade.useFirstFrameAsCover) return;
    if (widget.inspectDelay <= Duration.zero) {
      _inspect();
    } else {
      _inspectTimer = Timer(widget.inspectDelay, _inspect);
    }
  }

  void _onCoverSettingChanged() {
    if (!mounted) return;
    _acceptedFirstFrame = null;
    _scheduleInspect();
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant FirstFrameOrCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coverUrl != widget.coverUrl ||
        oldWidget.firstFrameUrl != widget.firstFrameUrl ||
        oldWidget.bvid != widget.bvid ||
        oldWidget.cid != widget.cid ||
        oldWidget.resolveMissingFirstFrame != widget.resolveMissingFirstFrame ||
        oldWidget.inspectDelay != widget.inspectDelay) {
      _acceptedFirstFrame = null;
      _scheduleInspect();
    }
  }

  Future<void> _inspect() async {
    final generation = ++_generation;
    if (!TvSettingsFacade.useFirstFrameAsCover) return;

    var firstFrame = widget.firstFrameUrl;
    var resolvedCid = widget.cid;
    if (widget.resolveMissingFirstFrame &&
        (firstFrame == null || firstFrame.isEmpty) &&
        widget.bvid?.isNotEmpty == true) {
      return;
    }
    if (firstFrame == null || firstFrame.isEmpty) return;

    if (mounted && generation == _generation) {
      setState(() => _acceptedFirstFrame = firstFrame);
    }
  }

  @override
  void dispose() {
    _generation++;
    _inspectTimer?.cancel();
    TvSettingsFacade.useFirstFrameAsCoverNotifier.removeListener(
      _onCoverSettingChanged,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: _acceptedFirstFrame ?? widget.coverUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      memCacheWidth: widget.width.round(),
      memCacheHeight: widget.height.round(),
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (context, url) => Container(
        width: widget.width,
        height: widget.height,
        color: const Color(0xFF2d2d2d),
      ),
      errorWidget: (context, url, error) => Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey[900],
        child: const Icon(Icons.broken_image, color: Colors.white24),
      ),
    );
  }
}
