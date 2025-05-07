# 翻译服务 (Translation Services)

本目录包含Spur应用程序的翻译服务实现，基于协议设计模式，支持多种翻译引擎。

## 架构设计

1. **协议定义**：
   - `TranslationServiceProtocol`：定义了翻译服务必须实现的方法

2. **核心组件**：
   - `TranslationManager`：管理和协调不同翻译服务的单例
   - `TranslationError`：统一的错误类型定义
   - `TranslationResult`：标准化的翻译结果模型

3. **服务实现**：
   - `AppleTranslationService`：使用Apple原生翻译API
   - `GeminiTranslationService`：使用Google Gemini API

## 使用流程

1. 应用启动时，`TranslationManager`会注册可用的翻译服务
2. 用户选择翻译引擎，通过`TranslationManager.switchService(to:)`切换服务
3. 执行翻译通过`TranslationManager.translate(text:from:to:)`方法
4. 翻译结果以`TranslationResult`的形式返回

## 错误处理

所有翻译服务统一使用`TranslationError`枚举类型报告错误：

- `invalidInput`：输入文本无效
- `translationFailed`：翻译过程失败，带有详细信息
- `languageNotSupported`：不支持的语言
- `networkError`：网络连接错误
- `unknown`：未知错误

## 支持的语言

当前支持的语言在`LanguageData`中定义，包括：
- 自动检测
- 简体中文
- 繁体中文
- 英语
- 日语
- 韩语
等多种语言 