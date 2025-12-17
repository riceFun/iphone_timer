# iPhone Timer - Android倒计时应用

一个模仿iPhone倒计时功能的Android应用,支持从快捷设置面板快速访问。

## 功能特性

- ✅ 精美的圆形倒计时界面
- ✅ iOS风格的时间选择器
- ✅ 通知栏实时显示倒计时
- ✅ Quick Settings Tile快捷磁贴支持
- ✅ 倒计时完成时声音和振动提醒
- ✅ 暂停、继续、停止功能

## 安装步骤

### 1. 安装依赖

```bash
flutter pub get
```

### 2. 添加音频文件（可选）

在 `assets/sounds/` 目录下添加一个名为 `timer_complete.mp3` 的音频文件作为倒计时完成提示音。

如果不添加，应用仍可正常工作，只是不会播放自定义声音。

### 3. 运行应用

```bash
flutter run
```

或构建APK:

```bash
flutter build apk --release
```

## 如何使用

### 基本使用

1. 打开应用
2. 点击"开始"按钮
3. 在弹出的选择器中设置分钟和秒数
4. 点击"开始"启动倒计时
5. 使用"暂停"、"继续"、"停止"按钮控制倒计时

### 添加到快捷设置

1. 下拉通知栏进入快捷设置面板
2. 点击编辑按钮（通常是铅笔图标）
3. 找到"倒计时"磁贴
4. 拖动到快捷设置面板
5. 点击磁贴即可快速打开应用

### 通知栏倒计时

当倒计时运行时:
- 通知栏会显示剩余时间
- 即使退出应用,倒计时仍会继续
- 点击通知可返回应用

## 技术栈

- Flutter SDK
- Dart
- Quick Actions (快捷操作)
- Flutter Local Notifications (本地通知)
- AudioPlayers (音频播放)
- Shared Preferences (数据持久化)

## Android配置

应用需要以下权限:
- `VIBRATE` - 振动权限
- `WAKE_LOCK` - 保持唤醒
- `POST_NOTIFICATIONS` - 发送通知(Android 13+)
- `FOREGROUND_SERVICE` - 前台服务

## 项目结构

```
lib/
├── main.dart                          # 应用入口
├── screens/
│   └── timer_screen.dart             # 倒计时主界面
└── services/
    ├── timer_service.dart            # 倒计时业务逻辑
    └── notification_service.dart     # 通知服务

android/
└── app/src/main/kotlin/
    └── com/example/iphone_timer/
        └── TimerTileService.kt       # Quick Settings Tile服务
```

## 开发笔记

### Quick Settings Tile

Quick Settings Tile (快捷设置磁贴) 是Android 7.0+ 提供的功能,允许用户从下拉通知栏快速访问应用功能。

实现要点:
1. 继承 `TileService` 类
2. 在 `AndroidManifest.xml` 中注册服务
3. 使用 `startActivityAndCollapse()` 启动应用

### 通知管理

使用 `flutter_local_notifications` 插件:
- 创建持续通知显示倒计时
- 倒计时完成时发送提醒通知
- 支持通知点击跳转

### 状态管理

使用 `ChangeNotifier` 进行简单的状态管理:
- TimerService 管理倒计时状态
- 使用 `addListener` 监听状态变化
- 实时更新UI和通知

## 未来改进

- [ ] 支持多个倒计时
- [ ] 预设常用时间
- [ ] 倒计时历史记录
- [ ] 自定义提示音
- [ ] 深色模式主题
- [ ] 桌面小部件
- [ ] 倒计时命名

## 许可证

MIT License
