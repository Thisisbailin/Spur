import SwiftUI
import Combine
import Translation

class TranslationViewModel: ObservableObject {
    // 输入和输出状态
    @Published var inputText: String = ""
    @Published var translatedText: String = ""
    @Published var isResultVisible: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var textEditorHeight: CGFloat = 40
    @Published var previousInputText: String = ""
    
    // 翻译设置
    @Published var selectedTranslationEngine: String = "Apple Translation"
    @Published var sourceLanguage: String = "auto"
    @Published var targetLanguage: String = "zh_CN"
    @Published var appleTargetLanguage: String = "zh_CN"
    @Published var geminiTranslationTheme: String = "日常"
    
    // 跟踪上次翻译的文本
    private var lastTranslatedText: String = ""
    
    // 翻译管理器实例
    private let translationManager = TranslationManager.shared
    
    // 历史记录管理器实例
    private let historyManager = HistoryManager.shared
    
    // 配置常量
    let minTextEditorHeight: CGFloat = 40
    let maxTextEditorHeight: CGFloat = 150
    
    // 数据源
    var engines: [TranslationEngine] {
        TranslationEngineData.all
    }
    
    var themes: [TranslationTheme] {
        TranslationThemeData.all
    }
    
    var languages: [Language] {
        LanguageData.common
    }
    
    // 当前是否使用Apple翻译
    var isUsingAppleTranslation: Bool {
        selectedTranslationEngine == "Apple Translation"
    }
    
    // 初始化方法
    init() {
        // 注册Gemini API翻译服务
        let geminiService = GeminiTranslationService()
        translationManager.registerService(geminiService)
        
        // 监听翻译引擎变化
        setupEngineChangeHandler()
    }
    
    private func setupEngineChangeHandler() {
        // 监控引擎变化并更新相关设置
        $selectedTranslationEngine
            .sink { [weak self] newEngine in
                guard let self = self else { return }
                
                if self.isUsingAppleTranslation {
                    // 默认Apple翻译器目标语言为中文
                    self.targetLanguage = "zh_CN"
                } else {
                    // 默认Gemini主题为"日常"
                    self.geminiTranslationTheme = "日常"
                }
            }
            .store(in: &cancellables)
    }
    
    // 用于存储Combine订阅
    private var cancellables = Set<AnyCancellable>()
    
    // 交换源语言和目标语言
    func swapLanguages() {
        // 只有当源语言不是自动检测时才进行交换
        if sourceLanguage != "auto" {
            let temp = sourceLanguage
            sourceLanguage = appleTargetLanguage
            appleTargetLanguage = temp
        }
    }
    
    // 执行翻译动作的入口方法
    func performTranslationAction() {
        Task {
            await performTranslation()
        }
    }
    
    // 执行翻译的核心逻辑
    func performTranslation() async {
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
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
            withAnimation {
                self.isResultVisible = true
            }
        }
        
        do {
            // 根据UI选择的翻译引擎切换服务
            let _ = translationManager.switchService(to: selectedTranslationEngine)
            
            // 如果使用Gemini，设置翻译主题
            if !isUsingAppleTranslation {
                translationManager.setTranslationTheme(geminiTranslationTheme)
            }
            
            // 根据选择的翻译引擎，使用不同的目标语言或使用主题修改提示词
            var fromLanguage = sourceLanguage
            var toLanguage = isUsingAppleTranslation ? appleTargetLanguage : targetLanguage
            
            // 如果使用Gemini且有选择主题，将主题信息添加到文本中
            var textToTranslate = trimmedInput
            var currentTheme: String? = nil
            
            if !isUsingAppleTranslation && geminiTranslationTheme != "日常" {
                currentTheme = geminiTranslationTheme
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
            await MainActor.run {
                self.translatedText = result.translatedText
                self.isLoading = false
                
                // 将翻译结果保存到历史记录
                self.saveToHistory(result: result, theme: currentTheme)
            }
        } catch {
            // 处理错误
            await MainActor.run {
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
    
    // 保存翻译结果到历史记录
    private func saveToHistory(result: TranslationResult, theme: String?) {
        // 将翻译结果保存到历史记录
        historyManager.addRecord(from: result, theme: theme)
    }
    
    // 从历史记录中加载翻译
    func loadFromHistory(record: TranslationRecord) {
        // 更新输入文本
        inputText = record.originalText
        
        // 更新翻译结果
        translatedText = record.translatedText
        
        // 更新源语言和目标语言
        sourceLanguage = record.sourceLanguage
        
        if isUsingAppleTranslation {
            appleTargetLanguage = record.targetLanguage
        }
        
        // 更新主题（如果有）
        if let theme = record.theme {
            geminiTranslationTheme = theme
        }
        
        // 显示结果
        isResultVisible = true
        isLoading = false
        errorMessage = nil
    }
    
    // 搜索历史记录
    func searchHistory(query: String) -> [TranslationRecord] {
        return historyManager.searchRecords(query: query)
    }
    
    // 获取最近的历史记录
    var recentHistory: [TranslationRecord] {
        return historyManager.recentRecords
    }
    
    // 获取收藏的记录
    var favoriteHistory: [TranslationRecord] {
        return historyManager.getFavorites()
    }
    
    // 切换收藏状态
    func toggleFavorite(for record: TranslationRecord) {
        historyManager.toggleFavorite(for: record)
    }
    
    // 处理输入文本变化
    func handleInputTextChange(oldValue: String, newValue: String) {
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
        previousInputText = newValue // 保存上一次的输入文本
        
        // 动态调整文本编辑器高度
        updateTextEditorHeight(for: newValue)
    }
    
    // 根据文本内容更新文本编辑器高度
    private func updateTextEditorHeight(for text: String) {
        let lines = text.split(whereSeparator: \.isNewline).count
        let baseLineHeight: CGFloat = 20 // 每行大约高度
        let padding: CGFloat = 20 // 基础内边距和间距
        var estimatedHeight = CGFloat(lines) * baseLineHeight + padding
        
        // 单行特殊情况处理
        if lines == 1 && !text.isEmpty {
            estimatedHeight = max(minTextEditorHeight, baseLineHeight + padding)
        } else if text.isEmpty {
            estimatedHeight = minTextEditorHeight
        }
        
        // 限制高度范围
        self.textEditorHeight = min(max(estimatedHeight, minTextEditorHeight), maxTextEditorHeight)
    }
} 