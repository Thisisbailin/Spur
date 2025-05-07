//
//  ContentView.swift
//  Spur
//
//  Created by Joe on 2025/5/7.
//

import SwiftUI
import Combine // For listening to Enter key
import Translation
import SwiftData

struct ContentView: View {
    // 使用ViewModel替代直接状态管理
    @StateObject private var viewModel = TranslationViewModel()
    
    // 添加SwiftData的ModelContext
    @Environment(\.modelContext) private var modelContext
    
    // FocusState for TextEditor
    @FocusState private var isTextEditorFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // 1. 输出结果区域 - 使用OutputAreaView
            OutputAreaView(
                viewModel: viewModel,
                isResultVisible: $viewModel.isResultVisible,
                isLoading: $viewModel.isLoading,
                errorMessage: $viewModel.errorMessage,
                translatedText: $viewModel.translatedText
            )
            .id("outputAreaView") // 提供一个稳定的ID用于引用
            
            // 2. 输入区域 - 使用InputAreaView
            InputAreaView(
                inputText: $viewModel.inputText,
                selectedTranslationEngine: $viewModel.selectedTranslationEngine,
                sourceLanguage: $viewModel.sourceLanguage,
                appleTargetLanguage: $viewModel.appleTargetLanguage,
                geminiTranslationTheme: $viewModel.geminiTranslationTheme,
                textEditorHeight: $viewModel.textEditorHeight,
                previousInputText: $viewModel.previousInputText,
                viewModel: viewModel,
                isTextEditorFocused: $isTextEditorFocused,
                performTranslationAction: viewModel.performTranslationAction
            )
        }
        .background(.regularMaterial)
        .cornerRadius(18)
        // 添加微妙的阴影效果
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        // 添加动画效果
        .animation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.3), value: viewModel.isResultVisible)
        .animation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.3), value: viewModel.isLoading)
        .animation(.smooth(duration: 0.2), value: viewModel.textEditorHeight)
        .onAppear {
            // 初始化文本编辑器高度
            viewModel.textEditorHeight = viewModel.minTextEditorHeight
            
            // 尝试在面板出现时聚焦TextEditor
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isTextEditorFocused = true
            }
            
            // 设置ModelContext到HistoryManager
            HistoryManager.shared.setModelContext(modelContext)
            
            // 监听菜单栏动作
            setupNotificationObservers()
        }
        .onDisappear {
            // 清理通知观察者
            NotificationCenter.default.removeObserver(self)
        }
        // 监听输入文本变化
        .onChange(of: viewModel.inputText) { oldValue, newValue in
            viewModel.handleInputTextChange(oldValue: oldValue, newValue: newValue)
        }
    }
    
    private func setupNotificationObservers() {
        // 监听历史记录显示通知
        NotificationCenter.default.addObserver(
            forName: .showHistory,
            object: nil,
            queue: .main
        ) { _ in
            // 确保结果区域可见
            viewModel.isResultVisible = true
            // 发送通知要求显示历史记录视图
            NotificationCenter.default.post(name: NSNotification.Name("showHistoryInOutput"), object: nil)
        }
        
        // 监听设置显示通知
        NotificationCenter.default.addObserver(
            forName: .showSettings,
            object: nil,
            queue: .main
        ) { _ in
            // 确保结果区域可见
            viewModel.isResultVisible = true
            // 发送通知要求显示设置视图
            NotificationCenter.default.post(name: NSNotification.Name("showSettingsInOutput"), object: nil)
        }
        
        // 监听翻译引擎选择通知
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("selectTranslationEngine"),
            object: nil,
            queue: .main
        ) { notification in
            if let engineName = notification.object as? String {
                // 更新选中的翻译引擎
                viewModel.selectedTranslationEngine = engineName
            }
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 380)
        .padding(50)
        .background(Color.purple.opacity(0.2))
        .modelContainer(for: TranslationRecord.self, inMemory: true)
}
