//
//  TranslationService.swift
//  Spur
//
//  Created by Joe on 2025/5/7.
//

import Foundation
import Combine

// 翻译服务协议
protocol TranslationServiceProtocol {
    // 进行翻译并返回结果
    func translate(text: String, from: String, to: String) async throws -> String
    
    // 检查语言可用性
    func checkLanguageAvailability(source: String, target: String) async -> Bool
    
    // 获取服务名称
    var serviceName: String { get }
}

// 翻译错误类型
enum TranslationError: Error {
    case invalidInput
    case translationFailed(String)
    case languageNotSupported
    case networkError
    case unknown
    
    var localizedDescription: String {
        switch self {
        case .invalidInput:
            return "输入文本无效"
        case .translationFailed(let message):
            return "翻译失败: \(message)"
        case .languageNotSupported:
            return "不支持的语言"
        case .networkError:
            return "网络连接错误"
        case .unknown:
            return "未知错误"
        }
    }
}

// 翻译结果类
struct TranslationResult {
    let originalText: String
    let translatedText: String
    let sourceLanguage: String
    let targetLanguage: String
    let service: String
    let timestamp: Date
    
    init(originalText: String, translatedText: String, sourceLanguage: String, targetLanguage: String, service: String) {
        self.originalText = originalText
        self.translatedText = translatedText
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.service = service
        self.timestamp = Date()
    }
}

// 翻译管理器
class TranslationManager {
    static let shared = TranslationManager()
    
    private var currentService: TranslationServiceProtocol
    private var services: [String: TranslationServiceProtocol] = [:]
    private var currentTheme: String = "日常"
    
    private init() {
        // 默认使用Apple翻译服务
        let appleService = AppleTranslationService()
        services[appleService.serviceName] = appleService
        currentService = appleService
    }
    
    func registerService(_ service: TranslationServiceProtocol) {
        services[service.serviceName] = service
    }
    
    func switchService(to serviceName: String) -> Bool {
        guard let service = services[serviceName] else {
            return false
        }
        
        currentService = service
        
        // 如果切换到Gemini服务，设置当前主题
        if let geminiService = service as? GeminiTranslationService {
            geminiService.setTheme(currentTheme)
        }
        
        return true
    }
    
    func setTranslationTheme(_ theme: String) {
        currentTheme = theme
        
        // 如果当前是Gemini服务，设置主题
        if let geminiService = currentService as? GeminiTranslationService {
            geminiService.setTheme(theme)
        }
    }
    
    func getCurrentService() -> TranslationServiceProtocol {
        return currentService
    }
    
    func listAvailableServices() -> [String] {
        return Array(services.keys)
    }
    
    func translate(text: String, from: String = "auto", to: String = "zh_CN") async throws -> TranslationResult {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TranslationError.invalidInput
        }
        
        do {
            let translatedText = try await currentService.translate(text: text, from: from, to: to)
            return TranslationResult(
                originalText: text,
                translatedText: translatedText,
                sourceLanguage: from,
                targetLanguage: to,
                service: currentService.serviceName
            )
        } catch {
            if let translationError = error as? TranslationError {
                throw translationError
            } else {
                throw TranslationError.translationFailed(error.localizedDescription)
            }
        }
    }
} 