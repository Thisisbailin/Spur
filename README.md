# Spur - macOS 翻译工具

Spur 是一个优雅的 macOS 翻译工具，提供简洁的用户界面和流畅的翻译体验。

## 功能特性

- 🎯 简洁美观的悬浮翻译面板
- 🌐 支持多种翻译引擎（Apple Translation、Gemini API）
- 🎨 多种翻译主题（日常、学术、词源）
- 📝 实时翻译输入
- 📱 状态栏快速访问
- 🎯 智能窗口管理
- 📋 翻译历史记录
- ⚙️ 自定义设置

## 技术架构

### 核心组件

1. **SpurApp**
   - 应用程序入口点
   - 管理主窗口和窗口访问器
   - 集成 AppDelegate

2. **ContentView**
   - 主要用户界面实现
   - 包含翻译输入和结果显示
   - 实现动态高度调整
   - 提供多种控制按钮和菜单

3. **AppDelegate**
   - 管理应用程序生命周期
   - 处理状态栏集成
   - 控制窗口显示和隐藏
   - 实现全局快捷键支持

### 技术特点

- 使用 SwiftUI 构建现代化用户界面
- 结合 AppKit 实现系统级集成
- 采用 MVVM 架构模式
- 支持实时动画和过渡效果
- 实现优雅的窗口管理

## 系统要求

- macOS 11.0 或更高版本
- Xcode 13.0 或更高版本（开发环境）

## 开发设置

1. 克隆项目
2. 使用 Xcode 打开项目
3. 构建并运行

## 使用说明

1. 通过状态栏图标启动应用
2. 在输入框中输入需要翻译的文本
3. 选择翻译引擎和主题
4. 查看翻译结果
5. 使用快捷键或状态栏菜单控制应用

## 故障排除

### 常见错误

#### SwiftUI 与 AppKit 集成渲染问题

如果您遇到以下错误：
```
Unable to render flattened version of PlatformViewRepresentableAdaptor<AppKitTextEditorAdaptor>
Unable to render flattened version of PlatformViewRepresentableAdaptor<PlatformView>
```

**解决方案：**
1. 这些警告通常出现在 SwiftUI 预览和真实运行环境之间，不影响实际应用功能
2. 可以通过以下方式解决：
   - 在自定义 NSViewRepresentable 包装器中实现 `updateNSView` 方法时避免频繁更新
   - 使用 `DispatchQueue.main.async` 延迟更新 AppKit 视图的操作
   - 在 ContentView 中使用 `.drawingGroup()` 修饰符优化渲染性能

#### Metal 渲染相关问题

如果遇到 Metal 库相关错误：
```
Unable to open mach-O at path: .../RenderBox.framework/.../default.metallib Error:2
```

**解决方案：**
1. 确保项目正确配置 Metal 库依赖
2. 可以在 Xcode 中清理构建文件夹 (Product > Clean Build Folder)
3. 重启 Xcode 和模拟器

#### 窗口引用传递问题

对于窗口引用相关的日志信息，这通常是正常的应用程序行为，不需要特别处理。

## 贡献指南

欢迎提交 Pull Request 或创建 Issue 来帮助改进项目。

## 许可证

[待定] 

# Spur翻译工具 - 架构说明

## MVVM架构实现

本项目采用MVVM (Model-View-ViewModel) 架构设计模式，以提高代码的可维护性、可测试性和可扩展性。

### 组件结构

1. **Model层**
   - `TranslationManager`: 管理不同翻译服务的核心类
   - `TranslationService`：翻译服务的协议抽象
   - `AppleTranslationService`/`GeminiTranslationService`：具体翻译服务实现

2. **ViewModel层**
   - `TranslationViewModel`：管理翻译状态和业务逻辑，充当View和Model之间的桥梁

3. **View层**
   - `ContentView`：主容器视图，仅负责视图组合和基本布局
   - `InputAreaView`：负责输入区域UI和交互
   - `OutputAreaView`：负责显示翻译结果和状态

### 数据流

1. 用户在`InputAreaView`中输入文本并与UI交互
2. 这些交互通过绑定更新`TranslationViewModel`中的状态
3. `TranslationViewModel`处理业务逻辑并调用`TranslationManager`执行翻译
4. 翻译结果通过`TranslationViewModel`更新，反映在`OutputAreaView`中

## 架构优势

### 1. 关注点分离
- 视图组件只负责UI渲染和用户交互
- 业务逻辑集中在ViewModel中
- 翻译功能封装在专用服务中

### 2. 可维护性
- 代码模块化，各部分职责明确
- 降低了组件间的耦合度
- 更容易理解和修改单个组件

### 3. 可测试性
- ViewModel可以独立测试，无需依赖UI
- 可以为Model层编写单元测试

### 4. 可扩展性
- 轻松添加新的翻译服务而不影响UI
- 可以轻松扩展UI功能而不改变底层逻辑
- 为添加历史记录、设置等功能提供了清晰的路径

## 未来扩展考虑

- 添加历史记录功能：在ViewModel中添加历史管理
- 实现用户设置：创建专用的SettingsViewModel
- 支持更多翻译引擎：只需实现新的TranslationService
- 离线模式：在Model层添加缓存机制 
