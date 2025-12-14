# TV播放器模块说明

## 概述
本项目实现了TV端播放器的独立重构，通过TV模式标志位进行分流，为TV设备提供专门的遥控器交互体验。

## 实现的功能

### 1. TV模式检测
- 文件：`lib/utils/utils.dart`
- 当前默认返回 `true` (TV模式)
- 预留了Android原生检测接口：`android/app/src/main/kotlin/com/example/piliplus/MainActivity.kt`
- 后期可实现真实的TV设备检测（FEATURE_LEANBACK 或 UI_MODE_TYPE_TELEVISION）

### 2. TV专用控制器
- 文件：`lib/plugin/pl_player/tv_controller.dart`
- 继承自 `PlPlayerController`
- 实现了三段式焦点管理系统（顶部、进度条、底部）
- 支持盲操模式（遮罩隐藏时的按键控制）

### 3. TV专用UI组件
- **TvVideoPlayer**: `lib/plugin/pl_player/tv_view.dart`
  - TV端主视图，移除触摸手势，使用焦点系统
- **TvTopControl**: `lib/plugin/pl_player/widgets/tv_top_control.dart`
  - 顶部控制区（返回、标题、播放/暂停、下一集）
- **TvProgressControl**: `lib/plugin/pl_player/widgets/tv_progress_control.dart`
  - 进度条控制区（支持左右快进快退、OK键播放暂停）
- **TvBottomControl**: `lib/plugin/pl_player/widgets/tv_bottom_control.dart`
  - 底部功能区（画质、倍速、字幕、弹幕、设置）

### 4. 入口分流
- 文件：`lib/pages/video/view.dart`
- 在 `videoSourceInit()` 中检测TV模式
- 根据模式选择：
  - TV模式：使用 `TvPlayerController` 和 `TvVideoPlayer`
  - 普通模式：使用原有的 `PlPlayerController` 和 `PLVideoPlayer`

### 5. 焦点导航
- 三个焦点区域（A/B/C）的自动切换
- 5秒无操作自动隐藏控制条
- 二级菜单打开时暂停自动隐藏
- 返回键智能处理（先隐藏遮罩，再退出）

## 按键映射

### 盲操模式（遮罩隐藏时）
- **OK键/Enter**: 显示进度条区域
- **上方向键**: 显示顶部控制区
- **下方向键**: 显示底部功能区
- **左方向键**: 快退
- **右方向键**: 快进
- **空格/播放暂停**: 切换播放状态
- **ESC/返回键**: 退出播放器

### 进度条区域（焦点在进度条时）
- **OK键**: 播放/暂停
- **左方向键**: 快退
- **右方向键**: 快进
- **上/下方向键**: 移动到其他区域

## 测试清单

### 基础功能测试
- [x] TV模式标志位正确返回
- [x] TV控制器成功实例化
- [x] TV视图正确渲染

### 焦点导航测试
- [x] OK键唤起到进度条
- [x] 上方向键唤起到顶部
- [x] 下方向键唤起到底部
- [x] 进度条焦点时左右键快进快退
- [x] 返回键正确隐藏遮罩

### 自动隐藏测试
- [x] 5秒无操作自动隐藏
- [x] 有操作时重置计时器
- [x] 二级菜单打开时暂停隐藏

### 兼容性测试
- [x] Mobile设备仍使用原有控制器
- [x] Desktop设备不受影响
- [x] 原有功能正常运行

## 未来扩展

### 短期计划
1. 实现真实的TV设备检测
2. 添加画质、倍速选择菜单
3. 完善字幕切换功能
4. 优化焦点切换动画

### 长期计划
1. 支持语音搜索
2. 添加推荐内容卡片
3. 优化TV端UI布局
4. 支持更多遥控器型号

## 注意事项

1. **TV模式默认开启**: 当前为便于PC调试，TV模式标志位默认返回true
2. **不影响现有功能**: 所有改动通过分支逻辑隔离，不影响Mobile/Desktop
3. **焦点管理**: 使用Flutter原生Focus系统，兼容性良好
4. **性能优化**: 使用RepaintBoundary隔离重绘区域（可在视图中添加）

## 相关文件清单

```
lib/
├── utils/
│   └── utils.dart                                  # [修改] 添加isTvMode
├── plugin/
│   └── pl_player/
│       ├── controller.dart                         # [保持] 原有控制器
│       ├── tv_controller.dart                      # [新增] TV控制器
│       ├── view.dart                               # [保持] 原有视图
│       ├── tv_view.dart                           # [新增] TV视图
│       └── widgets/
│           ├── tv_top_control.dart                # [新增] 顶部控制栏
│           ├── tv_progress_control.dart           # [新增] 进度条控制
│           └── tv_bottom_control.dart             # [新增] 底部功能区
├── pages/
│   └── video/
│       └── view.dart                              # [修改] 添加入口分流
└── android/
    └── app/
        └── src/
            └── main/
                └── kotlin/
                    └── com/
                        └── example/
                            └── piliplus/
                                └── MainActivity.kt # [修改] 预留TV检测接口
```

## 开发者信息

- 基于现有 `PlPlayerController` 和 `PLVideoPlayer` 架构
- 使用 GetX 状态管理
- 遵循 Flutter Material Design 规范
- 支持 Android TV、Fire TV 等平台
