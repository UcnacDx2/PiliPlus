import 'dart:typed_data';

import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/services/first_frame_quality_service.dart';
import 'package:PiliPlus/services/video_shot_preview_service.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:material_ui/material_ui.dart';

/// Displays the normal cover immediately, then prefers a usable first frame.
/// If the first frame is black or has no meaningful subject, a middle video
/// shot is resolved lazily from Bilibili's sprite sheet.
class FirstFrameOrCover extends StatefulWidget {
  const FirstFrameOrCover({
    super.key,
    required this.coverUrl,
    required this.firstFrameUrl,
    required this.width,
    required this.height,
    this.bvid,
    this.cid,
    this.borderRadius = Style.mdRadius,
    this.fit = .cover,
  });

  final String? coverUrl;
  final String? firstFrameUrl;
  final String? bvid;
  final int? cid;
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final BoxFit fit;

  @override
  State<FirstFrameOrCover> createState() => _FirstFrameOrCoverState();
}

class _FirstFrameOrCoverState extends State<FirstFrameOrCover> {
  String? _acceptedFirstFrame;
  Uint8List? _acceptedVideoShot;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _inspect();
  }

  @override
  void didUpdateWidget(covariant FirstFrameOrCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.firstFrameUrl != widget.firstFrameUrl ||
        oldWidget.coverUrl != widget.coverUrl ||
        oldWidget.bvid != widget.bvid ||
        oldWidget.cid != widget.cid) {
      _acceptedFirstFrame = null;
      _acceptedVideoShot = null;
      _inspect();
    }
  }

  Future<void> _inspect() async {
    final generation = ++_generation;
    if (!Pref.useFirstFrameAsCover) return;

    var firstFrame = widget.firstFrameUrl;
    var resolvedCid = widget.cid;
    if ((firstFrame == null || firstFrame.isEmpty) &&
        widget.bvid?.isNotEmpty == true) {
      final info = await VideoHttp.getVideoFirstFrameInfo(widget.bvid);
      firstFrame = info?.url;
      resolvedCid ??= info?.cid;
      if (!mounted || generation != _generation) return;
    }
    if (firstFrame == null || firstFrame.isEmpty) return;

    final usable = await FirstFrameQualityService.isUsable(firstFrame);
    if (!mounted || generation != _generation) return;
    if (usable) {
      setState(() => _acceptedFirstFrame = firstFrame);
      return;
    }

    final bvid = widget.bvid;
    final cid = resolvedCid;
    if (bvid == null || bvid.isEmpty || cid == null) return;
    final videoShot = await VideoShotPreviewService.resolve(bvid: bvid, cid: cid);
    if (!mounted || generation != _generation || videoShot == null) return;
    setState(() => _acceptedVideoShot = videoShot.bytes);
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_acceptedVideoShot case final bytes?) {
      return ClipRRect(
        borderRadius: widget.borderRadius,
        child: Image.memory(
          bytes,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
        ),
      );
    }
    return NetworkImgLayer(
      src: _acceptedFirstFrame ?? widget.coverUrl,
      width: widget.width,
      height: widget.height,
      borderRadius: widget.borderRadius,
      fit: widget.fit,
    );
  }
}
