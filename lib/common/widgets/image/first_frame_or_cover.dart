import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/services/first_frame_quality_service.dart';
import 'package:material_ui/material_ui.dart';

/// Displays the normal cover first, and only switches to a first frame after
/// a bounded low-resolution quality check accepts it.
class FirstFrameOrCover extends StatefulWidget {
  const FirstFrameOrCover({
    super.key,
    required this.coverUrl,
    required this.firstFrameUrl,
    required this.width,
    required this.height,
    this.borderRadius = Style.mdRadius,
    this.fit = .cover,
  });

  final String? coverUrl;
  final String? firstFrameUrl;
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final BoxFit fit;

  @override
  State<FirstFrameOrCover> createState() => _FirstFrameOrCoverState();
}

class _FirstFrameOrCoverState extends State<FirstFrameOrCover> {
  String? _acceptedFirstFrame;
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
        oldWidget.coverUrl != widget.coverUrl) {
      _acceptedFirstFrame = null;
      _inspect();
    }
  }

  Future<void> _inspect() async {
    final generation = ++_generation;
    final firstFrame = widget.firstFrameUrl;
    if (firstFrame == null || firstFrame.isEmpty) return;

    final usable = await FirstFrameQualityService.isUsable(firstFrame);
    if (!mounted || generation != _generation) return;
    if (usable) setState(() => _acceptedFirstFrame = firstFrame);
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => NetworkImgLayer(
    src: _acceptedFirstFrame ?? widget.coverUrl,
    width: widget.width,
    height: widget.height,
    borderRadius: widget.borderRadius,
    fit: widget.fit,
  );
}