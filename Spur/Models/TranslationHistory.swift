import Foundation
import SwiftData

@Model
class TranslationRecord {
    // 基本信息
    var originalText: String
    var translatedText: String
    var sourceLanguage: String
    var targetLanguage: String
    var translationService: String
    
    // 元数据
    var timestamp: Date
    var isFavorite: Bool
    var tags: [String]
    
    // 可选元数据，如主题等
    var theme: String?
    
    init(
        originalText: String,
        translatedText: String,
        sourceLanguage: String,
        targetLanguage: String,
        translationService: String,
        timestamp: Date = Date(),
        isFavorite: Bool = false,
        tags: [String] = [],
        theme: String? = nil
    ) {
        self.originalText = originalText
        self.translatedText = translatedText
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.translationService = translationService
        self.timestamp = timestamp
        self.isFavorite = isFavorite
        self.tags = tags
        self.theme = theme
    }
    
    // 从TranslationResult创建记录的便捷方法
    static func from(result: TranslationResult, theme: String? = nil) -> TranslationRecord {
        return TranslationRecord(
            originalText: result.originalText,
            translatedText: result.translatedText,
            sourceLanguage: result.sourceLanguage,
            targetLanguage: result.targetLanguage,
            translationService: result.service,
            timestamp: result.timestamp,
            theme: theme
        )
    }
} 