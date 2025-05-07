//
//  TranslationModels.swift
//  Spur
//
//  Created by Joe on 2025/5/7.
//

import Foundation

// 语言模型
struct Language: Identifiable, Hashable {
    let id: String
    let name: String
    let code: String
    let nativeName: String
    
    init(code: String, name: String, nativeName: String? = nil) {
        self.id = code
        self.code = code
        self.name = name
        self.nativeName = nativeName ?? name
    }
}

// 翻译引擎模型
struct TranslationEngine: Identifiable, Hashable {
    let id: String
    let name: String
    let iconName: String
    
    init(id: String, name: String, iconName: String) {
        self.id = id
        self.name = name
        self.iconName = iconName
    }
}

// 翻译主题
struct TranslationTheme: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    
    init(id: String, name: String, description: String) {
        self.id = id
        self.name = name
        self.description = description
    }
}

// 常用语言数据
struct LanguageData {
    static let common: [Language] = [
        Language(code: "auto", name: "自动检测", nativeName: "自动检测"),
        Language(code: "zh_CN", name: "简体中文", nativeName: "简体中文"),
        Language(code: "zh_TW", name: "繁体中文", nativeName: "繁體中文"),
        Language(code: "en", name: "英语", nativeName: "English"),
        Language(code: "ja", name: "日语", nativeName: "日本語"),
        Language(code: "ko", name: "韩语", nativeName: "한국어"),
        Language(code: "fr", name: "法语", nativeName: "Français"),
        Language(code: "de", name: "德语", nativeName: "Deutsch"),
        Language(code: "es", name: "西班牙语", nativeName: "Español"),
        Language(code: "it", name: "意大利语", nativeName: "Italiano"),
        Language(code: "ru", name: "俄语", nativeName: "Русский"),
    ]
    
    static func language(for code: String) -> Language {
        return common.first { $0.code == code } ?? Language(code: code, name: code)
    }
}

// 翻译引擎数据
struct TranslationEngineData {
    static let all: [TranslationEngine] = [
        TranslationEngine(id: "Apple Translation", name: "Apple 翻译", iconName: "apple.logo"),
        TranslationEngine(id: "Gemini API", name: "Gemini API", iconName: "sparkle")
    ]
    
    static func engine(for id: String) -> TranslationEngine {
        return all.first { $0.id == id } ?? all[0]
    }
}

// 翻译主题数据
struct TranslationThemeData {
    static let all: [TranslationTheme] = [
        TranslationTheme(id: "日常", name: "日常", description: "适用于日常对话和一般文本翻译"),
        TranslationTheme(id: "学术", name: "学术", description: "适用于学术论文和专业文献翻译"),
        TranslationTheme(id: "词源", name: "词源", description: "包含词语的来源解释和相关上下文")
    ]
    
    static func theme(for id: String) -> TranslationTheme {
        return all.first { $0.id == id } ?? all[0]
    }
} 