//
//  ContentView.swift
//  Spur
//
//  Created by Joe on 2025/5/7.
//

import SwiftUI
import Combine // For listening to Enter key
import Translation

struct ContentView: View {
    @State private var inputText: String = ""
    @State private var translatedText: String = ""
    @State private var isResultVisible: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    @State private var selectedTranslationEngine: String = "Apple Translation"
    @State private var selectedTheme: String = "日常"
    @State private var sourceLanguage: String = "auto"
    @State private var targetLanguage: String = "zh_CN"
    @State private var textEditorHeight: CGFloat = 40
    private let minTextEditorHeight: CGFloat = 40
    private let maxTextEditorHeight: CGFloat = 150

    // FocusState for TextEditor
    @FocusState private var isTextEditorFocused: Bool

    // Subject to publish Enter key presses
    private let enterKeyPressSubject = PassthroughSubject<Void, Never>()
    
    // 翻译管理器实例
    private let translationManager = TranslationManager.shared
    
    // 翻译引擎
    private var engines: [TranslationEngine] {
        TranslationEngineData.all
    }
    
    // 翻译主题
    private var themes: [TranslationTheme] {
        TranslationThemeData.all
    }
    
    // 常用语言
    private var languages: [Language] {
        LanguageData.common
    }
    
    // Apple Translation选择的目标语言
    @State private var appleTargetLanguage: String = "zh_CN"
    // Gemini翻译偏好主题
    @State private var geminiTranslationTheme: String = "日常"
    
    // 跟踪上次翻译的文本
    @State private var lastTranslatedText: String = ""
    
    // 当前是否使用Apple翻译
    private var isUsingAppleTranslation: Bool {
        selectedTranslationEngine == "Apple Translation"
    }
    
    // 初始化方法
    init() {
        // 注册Gemini API翻译服务
        let geminiService = GeminiTranslationService()
        translationManager.registerService(geminiService)
    }

    private func performTranslationAction() {
        Task {
            await performTranslation()
        }
    }
    
    private func performTranslation() async {
        let trimmedInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedInput.isEmpty {
            withAnimation { isResultVisible = false }
            return
        }
        
        // 防止重复翻译相同的文本
        if trimmedInput == lastTranslatedText && isResultVisible {
            return
        }
        
        lastTranslatedText = trimmedInput
        
        // 设置加载状态
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
            withAnimation {
                self.isResultVisible = true
            }
        }
        
        do {
            // 根据UI选择的翻译引擎切换服务
            translationManager.switchService(to: selectedTranslationEngine)
            
            // 如果使用Gemini，设置翻译主题
            if !isUsingAppleTranslation {
                translationManager.setTranslationTheme(geminiTranslationTheme)
            }
            
            // 根据选择的翻译引擎，使用不同的目标语言或使用主题修改提示词
            var fromLanguage = sourceLanguage
            var toLanguage = isUsingAppleTranslation ? appleTargetLanguage : targetLanguage
            
            // 如果使用Gemini且有选择主题，将主题信息添加到文本中
            var textToTranslate = trimmedInput
            if !isUsingAppleTranslation && geminiTranslationTheme != "日常" {
                let themeInstruction: String
                switch geminiTranslationTheme {
                case "学术":
                    themeInstruction = "以学术和专业的语言风格"
                case "词源":
                    themeInstruction = "解释词语来源并提供相关上下文，"
                default:
                    themeInstruction = ""
                }
                textToTranslate = "将以下文本\(themeInstruction)翻译成中文：\n\n\(trimmedInput)"
                // 对Gemini使用固定的英文到中文翻译，使用主题控制风格
                fromLanguage = "en"
                toLanguage = "zh_CN"
            }
            
            // 执行翻译
            let result = try await translationManager.translate(
                text: textToTranslate,
                from: fromLanguage,
                to: toLanguage
            )
            
            // 更新UI
            DispatchQueue.main.async {
                self.translatedText = result.translatedText
                self.isLoading = false
            }
        } catch {
            // 处理错误
            DispatchQueue.main.async {
                self.isLoading = false
                if let translationError = error as? TranslationError {
                    self.errorMessage = translationError.localizedDescription
                    self.translatedText = "翻译错误: \(translationError.localizedDescription)"
                } else {
                    self.errorMessage = error.localizedDescription
                    self.translatedText = "翻译错误: \(error.localizedDescription)"
                }
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 1. Result Area
            if isResultVisible {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        if isLoading {
                            VStack(spacing: 12) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .padding(.vertical, 4)
                                Text("正在翻译...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        } else if let errorMessage = errorMessage {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("翻译失败")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text(translatedText)
                                .font(.system(size: 14))
                                .foregroundColor(.primary.opacity(0.85))
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                    }
                }
                .frame(minHeight: 40, idealHeight: 120, maxHeight: 250)
            }

            // 2. Input Area
            VStack(spacing: 0) {
                // 语言选择栏 - 根据翻译引擎显示不同选项
                HStack(spacing: 8) {
                    if isUsingAppleTranslation {
                        // Apple Translation模式：源语言+目标语言选择器
                        // 源语言选择
                        Menu {
                            ForEach(languages) { language in
                                Button(language.name) {
                                    sourceLanguage = language.code
                                }
                            }
                        } label: {
                            HStack {
                                Text(LanguageData.language(for: sourceLanguage).name)
                                    .font(.caption)
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(Color.primary.opacity(0.06))
                            .cornerRadius(6)
                        }
                        
                        // 交换语言按钮
                        Button(action: {
                            // 如果源语言是自动检测，则不交换
                            if sourceLanguage != "auto" {
                                let temp = sourceLanguage
                                sourceLanguage = appleTargetLanguage
                                appleTargetLanguage = temp
                            }
                        }) {
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.caption)
                                .padding(6)
                                .foregroundColor(.accentColor)
                        }
                        .disabled(sourceLanguage == "auto")
                        
                        // 目标语言选择 - 只显示Apple支持的语言
                        Menu {
                            ForEach(languages.filter { $0.code != "auto" }) { language in
                                Button(language.name) {
                                    appleTargetLanguage = language.code
                                }
                            }
                        } label: {
                            HStack {
                                Text(LanguageData.language(for: appleTargetLanguage).name)
                                    .font(.caption)
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(Color.primary.opacity(0.06))
                            .cornerRadius(6)
                        }
                    } else {
                        // Gemini API模式：源语言+翻译主题选择器
                        // 源语言选择
                        Menu {
                            ForEach(languages) { language in
                                Button(language.name) {
                                    sourceLanguage = language.code
                                }
                            }
                        } label: {
                            HStack {
                                Text(LanguageData.language(for: sourceLanguage).name)
                                    .font(.caption)
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(Color.primary.opacity(0.06))
                            .cornerRadius(6)
                        }
                        
                        Spacer()
                        
                        // 翻译主题选择
                        Menu {
                            ForEach(TranslationThemeData.all) { theme in
                                Button(theme.name) {
                                    geminiTranslationTheme = theme.id
                                    // 设置翻译管理器的主题
                                    translationManager.setTranslationTheme(theme.id)
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "wand.and.stars")
                                    .font(.caption)
                                Text(TranslationThemeData.theme(for: geminiTranslationTheme).name)
                                    .font(.caption)
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(Color.primary.opacity(0.06))
                            .cornerRadius(6)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 8)
                .padding(.bottom, 4)
                
                // 2a. Text Input Area
                ZStack(alignment: .topTrailing) { // Use ZStack for potential clear button
                    TextEditor(text: $inputText)
                        .focused($isTextEditorFocused)
                        .font(.system(size: 15))
                        .frame(height: textEditorHeight)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 6) // Add some vertical padding inside TextEditor
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .onChange(of: inputText) { newValue in
                            // 自动检测Enter键
                            if newValue.hasSuffix("\n") && newValue.count > previousInputText.count {
                                let trimmedInput = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !trimmedInput.isEmpty && previousInputText.trimmingCharacters(in: .whitespacesAndNewlines) != trimmedInput {
                                    // 移除末尾换行符
                                    inputText = trimmedInput
                                    // 执行翻译
                                    performTranslationAction()
                                }
                            }
                            previousInputText = newValue // Keep track of previous text

                            let lines = newValue.split(whereSeparator: \.isNewline).count
                            let baseLineHeight: CGFloat = 20 // Approximate height per line
                            let padding: CGFloat = 20 // Base padding and spacing
                            var estimatedHeight = CGFloat(lines) * baseLineHeight + padding
                            // Special case for single line, ensure it's not too cramped
                            if lines == 1 && !newValue.isEmpty {
                                estimatedHeight = max(minTextEditorHeight, baseLineHeight + padding)
                            } else if newValue.isEmpty {
                                estimatedHeight = minTextEditorHeight
                            }
                            self.textEditorHeight = min(max(estimatedHeight, minTextEditorHeight), maxTextEditorHeight)
                        }
                        .onReceive(NotificationCenter.default.publisher(for: NSTextView.didChangeNotification)) { obj in
                            guard let textView = obj.object as? NSTextView, textView.string == inputText else { return }
                        }
                        .onCommand(#selector(NSResponder.insertNewline(_:))) {
                            print("Enter pressed (default newline)")
                        }
                }
                .padding(.top, 4)
                .padding(.horizontal, 8)

                // 2b. Controls Area
                HStack(spacing: 0) { // Reduce spacing to 0 and use padding on items
                    Group { // Group for easier padding application
                        // 翻译引擎选择
                        Menu {
                            ForEach(engines) { engine in
                                Button(engine.name) { 
                                    selectedTranslationEngine = engine.id
                                    print("Switched to \(engine.name)")
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: selectedTranslationEngine == "Apple Translation" ? "apple.logo" : "sparkle")
                                    .font(.system(size: 15))
                                Text(TranslationEngineData.engine(for: selectedTranslationEngine).name)
                                    .font(.system(size: 12))
                                    .lineLimit(1)
                            }
                            .frame(width: 120, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .menuStyle(.borderlessButton)
                        .padding(.horizontal, 4)

                        // 历史和设置按钮
                        Button { print("History Tapped") } label: {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 17))
                                .frame(width: 30, height: 30)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 4)
                    
                        Button { print("Settings Tapped") } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 17))
                                .frame(width: 30, height: 30)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 4)
                    }
                    .foregroundColor(.secondary) // Dim the control icons a bit

                    Spacer()

                    Button(action: performTranslationAction) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 22))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray.opacity(0.5) : Color.accentColor)
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.horizontal, 6)
                }
                .padding(EdgeInsets(top: 6, leading: 10, bottom: 8, trailing: 10)) 
            }
            .background(Color.primary.opacity(0.04)) 
        }
        .background(.regularMaterial)
        .cornerRadius(18) // Slightly larger corner radius
        // Add a very subtle shadow to the panel itself
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        // Animations
        .animation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.3), value: isResultVisible)
        .animation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.3), value: isLoading)
        .animation(.smooth(duration: 0.2), value: textEditorHeight) // Smoother height animation
        .onAppear {
            textEditorHeight = minTextEditorHeight
            // Try to focus TextEditor when panel appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // Delay to ensure view is ready
                self.isTextEditorFocused = true
            }
        }
        // Store previous inputText to help with Enter key logic (if needed)
        .onStateChange(of: inputText) { newValue, oldValue in
             self.previousInputText = oldValue
        }
        .onChange(of: selectedTranslationEngine) { _ in
            // 根据引擎变化，重置相关设置
            if isUsingAppleTranslation {
                // 默认Apple翻译器目标语言为中文
                targetLanguage = "zh_CN" 
            } else {
                // 默认Gemini主题为"日常"
                geminiTranslationTheme = "日常"
            }
        }
    }
    // Helper to store previous inputText value
    @State private var previousInputText: String = ""
}

// Helper for .onStateChange (optional, you can just use .onChange)
extension View {
    func onStateChange<Value: Equatable>(of value: Value, action: @escaping (_ newValue: Value, _ oldValue: Value) -> Void) -> some View {
        modifier(HostView(value: value, action: action))
    }
}

struct HostView<Value: Equatable>: ViewModifier {
    @State private var oldValue: Value
    private let value: Value
    private let action: (_ newValue: Value, _ oldValue: Value) -> Void

    init(value: Value, action: @escaping (_ newValue: Value, _ oldValue: Value) -> Void) {
        self.value = value
        self._oldValue = State(initialValue: value)
        self.action = action
    }

    func body(content: Content) -> some View {
        content
            .onChange(of: value) { newValue in
                action(newValue, oldValue)
                oldValue = newValue
            }
    }
}


#Preview {
    ContentView()
        .frame(width: 380)
        .padding(50)
        .background(Color.purple.opacity(0.2))
}
