import 'package:flutter/material.dart';
import 'package:PiliPlus/tv/adapters/tv_settings_facade.dart';
import 'package:PiliPlus/models/common/video/video_quality.dart';
import '../widgets/setting_toggle_row.dart';
import '../widgets/setting_dropdown_row.dart';
import '../widgets/setting_text_row.dart';

class PlaybackSettings extends StatefulWidget {
  final VoidCallback onMoveUp;
  final FocusNode? sidebarFocusNode;

  const PlaybackSettings({
    super.key,
    required this.onMoveUp,
    this.sidebarFocusNode,
  });

  @override
  State<PlaybackSettings> createState() => _PlaybackSettingsState();
}

class _PlaybackSettingsState extends State<PlaybackSettings> {
  List<String> _hardwareDecoders = [];

  @override
  void initState() {
    super.initState();
    _loadHardwareDecoders();
  }

  void _loadHardwareDecoders() async {
    if (mounted) setState(() => _hardwareDecoders = const []);
  }

  Future<void> _editRecommendKeyword() async {
    final controller = TextEditingController(
      text: TvSettingsFacade.recommendKeyword,
    );
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('推荐标题关键词过滤'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '用 | 分隔，例如：广告|抽奖',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || !mounted) return;
    try {
      await TvSettingsFacade.setRecommendKeyword(value);
      if (mounted) setState(() {});
    } on FormatException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('关键词格式无效，请检查正则表达式')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingToggleRow(
          label: '自动连播',
          subtitle: '视频播完自动播放下一集或推荐视频',
          value: TvSettingsFacade.autoPlay,
          autofocus: true,
          isFirst: true, // 第一项，向上返回分类标签
          onMoveUp: widget.onMoveUp,
          sidebarFocusNode: widget.sidebarFocusNode,
          onChanged: (value) async {
            await TvSettingsFacade.setAutoPlay(value);
            setState(() {});
          },
        ),
        const SizedBox(height: 16),
        SettingDropdownRow<int>(
          label: '默认画质上限',
          subtitle: '按可用资源选择不高于此档位的最高画质；4K 视频请选 4K 或更高',
          value: TvSettingsFacade.defaultVideoQa,
          items: VideoQuality.values.map((quality) => quality.code).toList(),
          itemLabel: (code) => VideoQuality.fromCode(code).shortDesc,
          sidebarFocusNode: widget.sidebarFocusNode,
          onChanged: (quality) async {
            if (quality != null) {
              await TvSettingsFacade.setDefaultVideoQa(quality);
              setState(() {});
            }
          },
        ),
        const SizedBox(height: 16),
        SettingDropdownRow<int>(
          label: '推荐视频最低时长',
          subtitle: '过滤短于设定时长的推荐视频，0 表示不过滤',
          value: TvSettingsFacade.minimumRecommendDuration,
          items: const [0, 60, 180, 300, 600, 1200, 1800],
          itemLabel: _formatDuration,
          sidebarFocusNode: widget.sidebarFocusNode,
          onChanged: (seconds) async {
            if (seconds != null) {
              await TvSettingsFacade.setMinimumRecommendDuration(seconds);
              setState(() {});
            }
          },
        ),
        const SizedBox(height: 16),
        SettingTextRow(
          label: '推荐标题关键词过滤',
          subtitle: '标题命中关键词的推荐视频会被过滤；用 | 分隔多个关键词',
          value: TvSettingsFacade.recommendKeyword,
          onSelect: _editRecommendKeyword,
          sidebarFocusNode: widget.sidebarFocusNode,
        ),
        const SizedBox(height: 16),
        SettingToggleRow(
          label: '迷你进度条',
          subtitle: '播放时在屏幕底部显示简约进度条',
          value: TvSettingsFacade.showMiniProgress,
          sidebarFocusNode: widget.sidebarFocusNode,
          onChanged: (value) async {
            await TvSettingsFacade.setShowMiniProgress(value);
            setState(() {});
          },
        ),
        const SizedBox(height: 16),
        SettingToggleRow(
          label: '默认隐藏控制栏',
          subtitle: '打开视频时不显示控制栏和进度条',
          value: TvSettingsFacade.hideControlsOnStart,
          sidebarFocusNode: widget.sidebarFocusNode,
          onChanged: (value) async {
            await TvSettingsFacade.setHideControlsOnStart(value);
            setState(() {});
          },
        ),
        const SizedBox(height: 16),
        SettingToggleRow(
          label: '快进预览模式',
          subtitle: '快进快退时显示预览缩略图，按确定跳转',
          value: TvSettingsFacade.seekPreviewMode,
          sidebarFocusNode: widget.sidebarFocusNode,
          onChanged: (value) async {
            await TvSettingsFacade.setSeekPreviewMode(value);
            setState(() {});
          },
        ),
        const SizedBox(height: 16),
        SettingDropdownRow<VideoCodec>(
          label: '视频解码器',
          subtitle: '自动=按硬件支持选最优，失败时降级到其他格式',
          value: TvSettingsFacade.preferredCodec,
          items: VideoCodec.values.where((codec) {
            // 自动选项始终显示
            if (codec == VideoCodec.auto) return true;
            // 只显示硬件支持的编码器
            return _hardwareDecoders.contains(codec.name.toLowerCase());
          }).toList(),
          itemLabel: (codec) => codec.label,
          isLast: true, // 最后一项，阻止向下导航
          sidebarFocusNode: widget.sidebarFocusNode,
          onChanged: (codec) async {
            if (codec != null) {
              await TvSettingsFacade.setPreferredCodec(codec);
              setState(() {});
            }
          },
        ),
      ],
    );
  }

  static String _formatDuration(int seconds) {
    if (seconds == 0) return '不过滤';
    if (seconds < 60) return '$seconds 秒';
    final minutes = seconds ~/ 60;
    return '$minutes 分钟以上';
  }
}
