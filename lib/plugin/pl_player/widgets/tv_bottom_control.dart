import 'package:flutter/material.dart';
import 'package:PiliPlus/plugin/pl_player/models/bottom_control_type.dart';
import 'package:PiliPlus/plugin/pl_player/tv_controller.dart';

class TvBottomControl extends StatelessWidget {
  final TvPlayerController controller;

  const TvBottomControl({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dynamically build the list of controls
    List<BottomControlType> controls = [
      BottomControlType.playOrPause,
      BottomControlType.pre,
      BottomControlType.next,
      BottomControlType.episode,
      BottomControlType.fit,
      BottomControlType.subtitle,
      BottomControlType.speed,
      BottomControlType.fullscreen,
      BottomControlType.viewPoints,
      BottomControlType.qa,
      BottomControlType.aiTranslate,
    ];

    return Focus(
      focusNode: controller.focusNodeC,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        color: Colors.black.withOpacity(0.5),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: controls.map((type) => buildBottomControlButton(type)).toList(),
          ),
        ),
      ),
    );
  }

  Widget buildBottomControlButton(BottomControlType type) {
    // You can customize icons and labels based on the control type
    IconData icon;
    String label;
    VoidCallback onPressed;

    switch (type) {
      case BottomControlType.playOrPause:
        icon = Icons.play_arrow;
        label = 'Play/Pause';
        onPressed = () => controller.plPlayerController.onDoubleTapCenter();
        break;
      case BottomControlType.pre:
        icon = Icons.skip_previous;
        label = 'Previous';
        onPressed = () {/* TODO */};
        break;
      case BottomControlType.next:
        icon = Icons.skip_next;
        label = 'Next';
        onPressed = () {/* TODO */};
        break;
      case BottomControlType.episode:
        icon = Icons.video_library;
        label = 'Episodes';
        onPressed = () {/* TODO */};
        break;
      case BottomControlType.fit:
        icon = Icons.aspect_ratio;
        label = 'Fit';
        onPressed = () {/* TODO */};
        break;
      case BottomControlType.subtitle:
        icon = Icons.subtitles;
        label = 'Subtitles';
        onPressed = () {/* TODO */};
        break;
      case BottomControlType.speed:
        icon = Icons.slow_motion_video;
        label = 'Speed';
        onPressed = () {/* TODO */};
        break;
      case BottomControlType.fullscreen:
        icon = Icons.fullscreen;
        label = 'Fullscreen';
        onPressed = () => controller.plPlayerController.triggerFullScreen();
        break;
      case BottomControlType.viewPoints:
        icon = Icons.playlist_play;
        label = 'View Points';
        onPressed = () {/* TODO */};
        break;
      case BottomControlType.qa:
        icon = Icons.high_quality;
        label = 'Quality';
        onPressed = () {/* TODO */};
        break;
      case BottomControlType.aiTranslate:
        icon = Icons.translate;
        label = 'Translate';
        onPressed = () {/* TODO */};
        break;
      default:
        return const SizedBox.shrink();
    }

    return _buildFocusableButton(
      icon: icon,
      label: label,
      onPressed: onPressed,
    );
  }

  Widget _buildFocusableButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return FocusableActionDetector(
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
