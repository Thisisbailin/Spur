//
//  AppleTranslationService.swift
//  Spur
//
//  Created by Joe on 2025/5/7.
//

import Foundation
import Translation
import SwiftUI

// Apple Translation服务实现
class AppleTranslationService: TranslationServiceProtocol {
    var serviceName: String { "Apple Translation" }
    
    private var translationTask: Task<String, Error>?
    
    func translate(text: String, from: String, to: String) async throws -> String {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TranslationError.invalidInput
        }
        
        do {
            // 创建配置
            let sourceLanguage = from == "auto" ? nil : Locale.Language(identifier: from)
            let targetLanguage = Locale.Language(identifier: to)
            
            let configuration = TranslationSession.Configuration(source: sourceLanguage, target: targetLanguage)
            
            // 使用SwiftUI的translationTask进行翻译
            return try await withCheckedThrowingContinuation { continuation in
                translationTask = Task {
                    do {
                        var resultText = ""
                        
                        try await withTranslationSession(configuration: configuration) { session in
                            // 尝试检查语言可用性
                            do {
                                try await session.prepareTranslation()
                                resultText = try await session.translate(text)
                                continuation.resume(returning: resultText)
                            } catch {
                                continuation.resume(throwing: TranslationError.translationFailed(error.localizedDescription))
                            }
                        }
                        
                        return resultText
                    } catch {
                        continuation.resume(throwing: TranslationError.translationFailed(error.localizedDescription))
                        throw error
                    }
                }
            }
        } catch {
            print("Apple Translation Error: \(error.localizedDescription)")
            
            // 根据错误类型转换为我们的错误类型
            switch error {
            case is URLError:
                throw TranslationError.networkError
            case is CancellationError:
                throw TranslationError.translationFailed("操作被取消")
            default:
                throw TranslationError.translationFailed(error.localizedDescription)
            }
        }
    }
    
    // 创建一个辅助函数来使用translationTask
    private func withTranslationSession<R>(configuration: TranslationSession.Configuration, 
                                          action: @escaping (TranslationSession) async throws -> R) async throws -> R {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    var session: TranslationSession?
                    
                    // 使用SwiftUI的translationTask视图修饰符创建一个临时视图来获取session
                    let view = EmptyView()
                        .translationTask(configuration) { translationSession in
                            session = translationSession
                            if let session = session {
                                do {
                                    let result = try await action(session)
                                    continuation.resume(returning: result)
                                } catch {
                                    continuation.resume(throwing: error)
                                }
                            } else {
                                continuation.resume(throwing: TranslationError.unknown)
                            }
                        }
                    
                    // 在某些情况下，可能需要确保视图被渲染
                    _ = view
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func checkLanguageAvailability(source: String, target: String) async -> Bool {
        do {
            let sourceLanguage = source == "auto" ? nil : Locale.Language(identifier: source)
            let targetLanguage = Locale.Language(identifier: target)
            
            let configuration = TranslationSession.Configuration(source: sourceLanguage, target: targetLanguage)
            
            var isAvailable = false
            
            _ = try? await withTranslationSession(configuration: configuration) { session in
                // 尝试进行一个简单的翻译测试来检查可用性
                do {
                    // 先准备翻译，这会提示用户下载语言模型（如果需要）
                    try await session.prepareTranslation()
                    isAvailable = true
                } catch {
                    isAvailable = false
                }
                return isAvailable
            }
            
            return isAvailable
        } catch {
            print("Language availability check error: \(error.localizedDescription)")
            return false
        }
    }
    
    deinit {
        // 取消正在进行的任务
        translationTask?.cancel()
    }
} 