# Spur项目结构

## 目录结构

```
Spur/
├── App/                   # 应用程序入口和配置
│   ├── AppDelegate.swift  # 应用程序代理
│   └── SpurApp.swift      # SwiftUI应用入口
│
├── Models/                # 数据模型
│   ├── HistoryManager.swift     # 历史记录管理器
│   ├── TranslationHistory.swift # 翻译历史记录模型(SwiftData)
│   ├── TranslationModels.swift  # 基础翻译模型和数据
│   └── README.md                # 模型实现说明
│
├── ViewModels/            # 视图模型
│   └── TranslationViewModel.swift # 翻译视图模型
│
├── Views/                 # 视图组件
│   ├── ContentView.swift      # 主内容视图
│   ├── HistoryView.swift      # 历史记录视图
│   ├── InputAreaView.swift    # 输入区域视图
│   └── OutputAreaView.swift   # 输出区域视图
│
├── Service/               # 服务层
│   ├── AppleTranslationService.swift # Apple翻译服务
│   ├── GeminiTranslationService.swift # Gemini翻译服务
│   └── TranslationService.swift      # 翻译服务基础接口
│
├── Utilities/             # 工具类
│
└── Assets.xcassets/       # 资源文件
```

## 架构说明

本项目采用MVVM架构模式：

1. **Model层**
   - `Models/`: 负责数据表示和业务逻辑
   - `Service/`: 提供翻译服务和API交互

2. **ViewModel层**
   - `ViewModels/`: 作为Model和View之间的桥梁，处理UI业务逻辑

3. **View层**
   - `Views/`: 负责UI展示和用户交互

4. **App层**
   - `App/`: 负责应用程序生命周期和全局配置

## 数据流

1. 用户在`Views/`中的视图组件中交互
2. 交互事件传递给`ViewModels/`中的视图模型
3. 视图模型调用`Service/`中的服务执行翻译
4. 翻译结果通过`Models/`中的数据模型存储
5. 视图模型更新状态，通知视图刷新

## 依赖关系

- View → ViewModel → Model/Service
- 避免View直接依赖Model

## 文件命名约定

- 视图文件: `XXXView.swift`
- 视图模型: `XXXViewModel.swift`
- 服务文件: `XXXService.swift`
- 模型文件: `XXX.swift` 或 `XXXModel.swift` 