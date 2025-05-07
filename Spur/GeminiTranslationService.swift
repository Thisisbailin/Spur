//
//  GeminiTranslationService.swift
//  Spur
//
//  Created by Joe on 2025/5/7.
//

import Foundation

// Gemini API翻译服务实现
class GeminiTranslationService: TranslationServiceProtocol {
    var serviceName: String { "Gemini API" }
    
    // Gemini API密钥（实际开发中应从安全的地方获取，如Keychain）
    private var apiKey: String = "YOUR_GEMINI_API_KEY"
    private let apiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"
    
    // 翻译主题
    private var currentTheme: String = "日常"
    
    func translate(text: String, from: String, to: String) async throws -> String {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TranslationError.invalidInput
        }
        
        // 构建请求URL
        let urlString = "\(apiEndpoint)?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw TranslationError.unknown
        }
        
        // 检查是否包含主题指令，如果已经包含则直接使用原文本
        let containsThemeInstructions = text.contains("以学术和专业的语言风格") || 
                                        text.contains("解释词语来源并提供相关上下文") ||
                                        text.contains("将以下文本")
        
        // 根据输入文本判断是否需要添加主题指令
        let promptText: String
        if containsThemeInstructions {
            // 已经包含主题指令，直接使用原文本
            promptText = text
        } else {
            // 没有主题指令，根据源语言和目标语言构建提示词
            let sourceLanguage = from == "auto" ? "自动检测" : from
            let targetLanguage = to
            
            // 构建提示文本，加入当前主题指令
            let themeInstruction = getThemeInstruction(theme: currentTheme)
            
            promptText = """
            将以下文本从\(sourceLanguage)\(themeInstruction)翻译成\(targetLanguage)。只返回翻译后的文本，不要添加额外解释或上下文。
            
            原文: \(text)
            
            翻译:
            """
        }
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": promptText]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.2,
                "topP": 0.8,
                "topK": 40
            ]
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw TranslationError.unknown
        }
        
        // 创建请求
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            // 发送请求
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 验证响应
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TranslationError.networkError
            }
            
            // 检查HTTP状态码
            if httpResponse.statusCode != 200 {
                // 尝试解析错误信息
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = errorJson["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    throw TranslationError.translationFailed(message)
                }
                throw TranslationError.translationFailed("HTTP状态码: \(httpResponse.statusCode)")
            }
            
            // 解析响应
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = json["candidates"] as? [[String: Any]],
                  let content = candidates.first?["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let text = parts.first?["text"] as? String else {
                throw TranslationError.translationFailed("解析响应失败")
            }
            
            // 处理翻译结果，提取关键部分
            let translatedText = extractTranslatedText(from: text)
            return translatedText
        } catch {
            if let translationError = error as? TranslationError {
                throw translationError
            } else if let urlError = error as? URLError {
                throw TranslationError.networkError
            } else {
                throw TranslationError.translationFailed(error.localizedDescription)
            }
        }
    }
    
    // 从Gemini响应中提取翻译文本
    private func extractTranslatedText(from text: String) -> String {
        // 简单处理：如果返回了明确的"翻译:"前缀，则移除它
        if text.contains("翻译:") {
            if let range = text.range(of: "翻译:") {
                return String(text[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // 根据主题获取指令
    private func getThemeInstruction(theme: String) -> String {
        switch theme {
        case "学术":
            return "以学术和专业的语言风格"
        case "词源":
            return "并解释词语来源和相关上下文"
        default:
            return ""
        }
    }
    
    func checkLanguageAvailability(source: String, target: String) async -> Bool {
        // Gemini API支持大多数常见语言，但可能有限制
        // 这里简化处理，假设所有语言对都可用
        return true
    }
    
    // 设置API密钥
    func setApiKey(_ key: String) {
        self.apiKey = key
    }
    
    // 设置翻译主题
    func setTheme(_ theme: String) {
        self.currentTheme = theme
    }
} 