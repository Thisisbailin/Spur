# 应用程序入口 (App)

此目录包含Spur应用程序的核心入口点和应用程序级配置。

## 主要组件

### SpurApp

`SpurApp`是SwiftUI应用的主入口点，负责：
- 定义应用程序场景结构
- 配置SwiftData模型容器
- 设置窗口样式和行为
- 初始化应用程序代理

### AppDelegate

`AppDelegate`实现macOS应用程序代理功能，负责：
- 管理状态栏菜单和图标
- 处理全局事件和热键
- 控制窗口显示和隐藏
- 管理应用程序生命周期

## 应用程序生命周期

1. 应用启动时：
   - `SpurApp`初始化SwiftData模型容器
   - `AppDelegate`设置状态栏菜单和图标
   - `ContentView`显示在主窗口中

2. 窗口管理：
   - `WindowAccessor`组件将NSWindow引用传递给AppDelegate
   - AppDelegate配置窗口行为（如失去焦点时隐藏等）

3. 状态栏交互：
   - 用户通过状态栏图标或全局热键激活应用
   - AppDelegate负责显示/隐藏窗口和处理菜单事件

## 技术特点

- 结合SwiftUI和AppKit实现macOS集成
- 使用NSApplicationDelegateAdaptor集成AppDelegate
- 通过WindowGroup定义窗口场景
- 使用ModelContainer配置SwiftData持久化存储 