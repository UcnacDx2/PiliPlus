# fork 层说明

本仓库是 [bggRGjQaUbCoE/PiliPlus](https://github.com/bggRGjQaUbCoE/PiliPlus) 的个人定制分支。
所有定制功能都放在 `lib/fork/` 下，上游文件里只保留少量带 `// FORK:` 标记的接入点，
这样每天 `git rebase canonical/main` 时冲突面最小。

## 功能来源

| 功能 | 代码位置 | 上游接入点 |
| --- | --- | --- |
| 分账号续播（取流账号 ≠ 记录账号） | `lib/fork/playback/account_playback.dart` | `VideoDetailController._getVideoUrl`、`PageUtils.viewPgc`、`VideoHttp.videoUrl` 的可选 `account` 参数 |
| 长视频播放地址自动续期 | `lib/fork/player/stream_renewal.dart`（判断）、`lib/fork/playback/video_renewal.dart`（重新取流并原地重开） | `PlPlayerController` 的 `beforeOpen` / `afterOpen` / `started` / 错误监听 / `dispose`；`VideoDetailController.playerInit` 绑定 renewer |
| 首帧封面 + 视频截图兜底 | `lib/fork/covers/`、`lib/fork/http/fork_video_api.dart` | 三个卡片组件的 `NetworkImgLayer` 替换为 `FirstFrameOrCover`；模型增加 `firstFrame` 字段 |
| 去水印（GLSL shader） | `lib/fork/watermark/` | `PlPlayerController` 的 `setShader` 之后重挂滤镜；播放页控制栏的水印位置选择 |
| fork 设置项 | `lib/fork/settings/fork_settings.dart` | 设置页列表里 `...forkPlaySettings` / `...forkVideoSettings` |

偏好项直接读写 `GStorage.setting`，键名常量在 `lib/fork/fork_prefs.dart`
（`watermarkMode`、`watermarkPosition`、`useFirstFrameAsCover`），
不改 `SettingBoxKey` / `storage_pref.dart`，同样是为了少冲突。

## 续期是怎么工作的

B 站 playurl 返回的地址带 `deadline` 参数（通常约 2 小时）。长视频超过这个时间，
mpv 播完缓冲后再请求就失败：有时报 `Failed to open https://`，有时只是停住不动。
官方逻辑只会用同一条失效地址 `refreshPlayer()` 重试，所以会一直卡住。

fork 层的 `ForkStreamRenewal` 做三件事：

1. 打开媒体时解析 `deadline`，在到期前 3 分钟主动续期；
2. 监听 mpv 错误，命中失效地址特征时接管处理（返回 `true`，压掉官方的无效重试）；
3. 看门狗：播放中位置 20 秒不前进则判定卡死，触发续期。

续期由 `VideoDetailController.forkRenewStream()` 执行：用当前画质/音质重新取流，
更新 `data.dash` 中对应条目，记下当前位置后 `playerInit` 原地重开。
失败按 15s×次数退避，最多 3 次；主动续期不弹 toast，卡死/报错续期成功后提示「播放地址已刷新」。

## 分账号续播

`Accounts.video` 取流、`Accounts.heartbeat`/`history` 记录进度。两个账号不一致时，
playurl 返回的 `last_play_time` 属于取流账号，续播位置会错。
`ForkAccountPlayback.videoUrl` 在这种情况下额外用记录账号请求一次 playurl，
只取 `last_play_time` / `last_play_cid` 覆盖结果；同账号时没有额外请求。
PGC 受限剧集没有播放进度时，再用记录账号的搜索历史接口兜底（`pgcProgress`）。

## 每次同步上游

```bash
git fetch canonical main
git rebase canonical/main
flutter pub get
flutter analyze --no-fatal-infos lib/fork lib/plugin/pl_player/controller.dart \
  lib/pages/video/controller.dart lib/pages/video/widgets/header_control.dart \
  lib/http/video.dart lib/utils/page_utils.dart lib/common/widgets/video_card \
  lib/pages/dynamics/widgets/video_panel.dart lib/pages/setting/models
flutter test test/fork
```

`.github/workflows/sync-fork-mobile.yml` 每天自动做同样的事，并构建一次 Android 包。
rebase 后如果某个 `// FORK:` 注释丢了，`test/fork/fork_integration_markers_test.dart`
会失败并指出是哪个文件、哪个接入点。

## 重新发布

```bash
gh workflow run Build --ref fork/mobile \
  -f build_android=true -f build_ios=false -f build_mac=false \
  -f build_win_x64=false -f build_linux_x64=false -f tag=<tag>
```
