//
//  GeminiTranslationService.swift
//  Spur
//
//  Created by Joe on 2025/5/7.
//

import Foundation
import SwiftUI

// MARK: - OCR提示词管理

// GeminiOCR提示词
struct GeminiOCRPrompts {
    // --- 系统指令：定义核心任务和输出格式 ---
    static let ocrSystemInstruction = """
You are a highly specialized image OCR and text translation agent. Your task is to:
1. Accurately extract all text from the provided image
2. Preserve the original formatting including paragraphs and line breaks
3. Translate the extracted text into Chinese
4. Return only the translated text without any explanations or metadata

Focus on accuracy and fluency of the translation. If the image contains text in multiple languages, translate all of it to Chinese.
"""

    // --- 用户指令：简单指令引用系统指令和图像 ---
    static let ocrUserInstruction = "识别这张图片中的所有文本并翻译成中文。请直接返回翻译结果，不要添加任何解释或元数据。"
}

// MARK: - Gemini API翻译服务实现

class GeminiTranslationService: TranslationServiceProtocol {
    var serviceName: String { "Gemini API" }
    
    // API调用相关
    private let workerEndpoint = "https://lexis.thisisbailin.workers.dev/define" // 文本翻译
    private let ocrEndpoint = "https://lexis.thisisbailin.workers.dev/ocr" // OCR专用端点
    private let session = URLSession.shared
    
    // 翻译主题
    private var currentTheme: String = "日常"
    
    // 选中的OCR图像
    private var selectedImage: NSImage? = nil
    
    func translate(text: String, from: String, to: String) async throws -> String {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TranslationError.invalidInput
        }
        
        // 检查是否有选中的图像需要OCR识别
        if let image = selectedImage {
            // 使用OCR服务处理图像
            return try await translateWithOCR(image: image, from: from, to: to)
        } else {
            // 正常文本翻译
            return try await translateText(text: text, from: from, to: to)
        }
    }
    
    // 处理文本翻译
    private func translateText(text: String, from: String, to: String) async throws -> String {
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
            let sourceLanguage = from == "auto" ? "自动检测" : LanguageData.language(for: from).name
            let targetLanguage = LanguageData.language(for: to).name
            
            // 构建提示文本，加入当前主题指令
            let themeInstruction = getThemeInstruction(theme: currentTheme)
            
            promptText = """
            将以下文本从\(sourceLanguage)\(themeInstruction)翻译成\(targetLanguage)。只返回翻译后的文本，不要添加额外解释或上下文。
            
            原文: \(text)
            
            翻译:
            """
        }
        
        // 构建请求体 - 使用Worker格式
        let userContentPart: [String: Any] = [
            "parts": [
                ["text": promptText]
            ]
        ]
        
        let systemInstructionText = "你是一位专业的翻译助手，负责准确、流畅地将文本从一种语言翻译到另一种语言。只返回翻译后的文本，不要添加任何额外的解释、评论或格式。"
        
        let requestBody: [String: Any] = [
            "systemInstruction": systemInstructionText,
            "userContent": [userContentPart],
            "generationConfig": [
                "temperature": 0.2,
                "topP": 0.8,
                "topK": 40
            ]
        ]
        
        // 发送请求并处理响应
        return try await sendRequestToWorker(requestBody: requestBody)
    }
    
    // 处理图像OCR翻译
    private func translateWithOCR(image: NSImage, from: String, to: String) async throws -> String {
        print("GeminiTranslationService: 开始OCR图像识别...")
        
        // 准备图像数据
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let imageRep = NSBitmapImageRep(cgImage: cgImage),
              let jpegData = imageRep.representation(using: .jpeg, properties: [.compressionFactor: 0.7]) else {
            throw TranslationError.invalidInput
        }
        
        let base64Image = jpegData.base64EncodedString()
        
        // 获取指令
        let systemInstruction = GeminiOCRPrompts.ocrSystemInstruction
        let userInstruction = GeminiOCRPrompts.ocrUserInstruction
        
        // 构建请求体
        let userContentPart: [String: Any] = [
            "parts": [
                ["inlineData": ["mimeType": "image/jpeg", "data": base64Image]],
                ["text": userInstruction]
            ]
        ]
        
        let payloadForWorker: [String: Any] = [
            "systemInstruction": systemInstruction,
            "userContent": [userContentPart],
            "generationConfig": [
                "temperature": 0.2,
                "topP": 0.8,
                "topK": 40
            ]
        ]
        
        // 序列化请求体
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payloadForWorker) else {
            throw TranslationError.unknown
        }
        
        // 创建请求
        guard let url = URL(string: ocrEndpoint) else {
            throw TranslationError.networkError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60 // OCR可能需要更长时间
        
        print("GeminiTranslationService: 发送OCR请求到Worker...")
        
        // 清除已处理的图像
        defer { self.selectedImage = nil }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TranslationError.networkError
            }
            
            if httpResponse.statusCode != 200 {
                // 尝试解析错误信息
                let errorBody = String(data: data, encoding: .utf8) ?? "未知错误"
                print("❌ OCR错误: HTTP \(httpResponse.statusCode). Body: \(errorBody)")
                throw TranslationError.translationFailed("OCR处理错误: \(httpResponse.statusCode)")
            }
            
            // 解析OCR响应
            guard let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = result["candidates"] as? [[String: Any]],
                  let content = candidates.first?["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let text = parts.first?["text"] as? String else {
                let rawString = String(data: data, encoding: .utf8) ?? "(无法解码)"
                print("❌ 解析OCR响应失败. Raw: \(rawString)")
                throw TranslationError.translationFailed("解析OCR响应失败")
            }
            
            print("✅ OCR识别成功!")
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            if let translationError = error as? TranslationError {
                throw translationError
            } else {
                print("❌ OCR处理失败: \(error.localizedDescription)")
                throw TranslationError.translationFailed("OCR处理失败: \(error.localizedDescription)")
            }
        }
    }
    
    // 发送请求到Worker（文本翻译）
    private func sendRequestToWorker(requestBody: [String: Any]) async throws -> String {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw TranslationError.unknown
        }
        
        guard let url = URL(string: workerEndpoint) else {
            throw TranslationError.networkError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TranslationError.networkError
            }
            
            if httpResponse.statusCode != 200 {
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = errorJson["error"] as? String {
                    throw TranslationError.translationFailed(error)
                }
                throw TranslationError.translationFailed("HTTP错误: \(httpResponse.statusCode)")
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
            return extractTranslatedText(from: text)
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
    
    // 设置翻译主题
    func setTheme(_ theme: String) {
        self.currentTheme = theme
    }
    
    // 设置要OCR识别的图像
    func setImage(_ image: NSImage?) {
        self.selectedImage = image
    }
    
    // 检查是否有图像等待处理
    func hasImageForOCR() -> Bool {
        return selectedImage != nil
    }
    
    // 清除待处理的图像
    func clearImageForOCR() {
        selectedImage = nil
    }
} 
