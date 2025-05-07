# 视图模型 (ViewModels)

此目录包含Spur应用程序的视图模型，它们作为视图和模型之间的桥梁，处理UI业务逻辑。

## 主要组件

### TranslationViewModel

`TranslationViewModel`是应用程序的核心视图模型，负责：

1. **状态管理**：
   - 管理输入/输出文本
   - 追踪翻译状态（加载中、错误等）
   - 控制UI元素的可见性和尺寸

2. **用户交互处理**：
   - 处理文本输入变化
   - 执行翻译请求
   - 切换翻译引擎和设置

3. **翻译逻辑**：
   - 根据用户选择配置翻译参数
   - 调用翻译服务执行翻译
   - 处理翻译结果和错误

4. **历史记录管理**：
   - 保存翻译历史
   - 提供历史查询功能
   - 管理历史记录收藏状态

## 架构特点

- **观察者模式**：使用`@Published`属性使状态变化可观察
- **依赖注入**：通过引用服务和管理器避免紧耦合
- **异步处理**：使用`async/await`处理翻译操作

## 使用方式

视图模型通常在视图初始化时创建：

```swift
struct SomeView: View {
    @StateObject private var viewModel = TranslationViewModel()
    
    var body: some View {
        // 使用viewModel的状态和方法
    }
}
```

或通过依赖注入方式传递：

```swift
struct ChildView: View {
    @ObservedObject var viewModel: TranslationViewModel
    
    var body: some View {
        // 使用viewModel的状态和方法
    }
}
``` 