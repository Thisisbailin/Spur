//
//  AppleTranslationService.swift
//  Spur
//
//  Created by Joe on 2025/5/7.
//

import Foundation
import Translation
import SwiftUI
import Combine

// Apple Translation服务实现
class AppleTranslationService: TranslationServiceProtocol {
    var serviceName: String { "Apple Translation" }
    
    // 使用简化的实现，更可靠地处理Translation API
    func translate(text: String, from: String, to: String) async throws -> String {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TranslationError.invalidInput
        }
        
        do {
            // 创建配置
            let sourceLanguage = from == "auto" ? nil : Locale.Language(identifier: from)
            let targetLanguage = Locale.Language(identifier: to)
            
            let configuration = TranslationSession.Configuration(source: sourceLanguage, target: targetLanguage)
            
            // 使用一个标记来确保continuation只被调用一次
            return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
                var hasCompleted = false
                
                // 创建任务进行翻译
                let task = Task {
                    do {
                        let session = try TranslationSession(configuration: configuration)
                        
                        try await session.prepareTranslation()
                        let response = try await session.translate(text)
                        
                        // 确保只有在尚未完成时才恢复continuation
                        if !hasCompleted {
                            hasCompleted = true
                            continuation.resume(returning: response.targetText)
                        }
                    } catch {
                        // 确保只有在尚未完成时才恢复continuation
                        if !hasCompleted {
                            hasCompleted = true
                            continuation.resume(throwing: TranslationError.translationFailed("Apple Translation失败: \(error.localizedDescription)"))
                        }
                    }
                }
                
                // 设置超时处理
                Task {
                    do {
                        try await Task.sleep(nanoseconds: 15_000_000_000) // 15秒超时
                        if !hasCompleted && !task.isCancelled {
                            task.cancel()
                            hasCompleted = true
                            continuation.resume(throwing: TranslationError.translationFailed("翻译请求超时"))
                        }
                    } catch {
                        // 忽略超时任务被取消的情况
                    }
                }
            }
        } catch {
            print("Apple Translation Error: \(error.localizedDescription)")
            
            // 根据错误类型转换为我们的错误类型
            if let translationError = error as? TranslationError {
                throw translationError
            } else {
                switch error {
                case is URLError:
                    throw TranslationError.networkError
                case is CancellationError:
                    throw TranslationError.translationFailed("操作被取消")
                default:
                    throw TranslationError.translationFailed("Apple Translation错误: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func checkLanguageAvailability(source: String, target: String) async -> Bool {
        do {
            let sourceLanguage = source == "auto" ? nil : Locale.Language(identifier: source)
            let targetLanguage = Locale.Language(identifier: target)
            
            let configuration = TranslationSession.Configuration(source: sourceLanguage, target: targetLanguage)
            
            // 使用同样的方式检查可用性
            var isAvailable = false
            
            // 使用translationTask创建会话并检查可用性
            _ = try? await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
                Task {
                    let view = Text("")
                        .translationTask(configuration) { session in
                            Task {
                                do {
                                    try await session.prepareTranslation()
                                    isAvailable = true
                                    continuation.resume(returning: true)
                                } catch {
                                    isAvailable = false
                                    continuation.resume(returning: false)
                                }
                            }
                        }
                    
                    // 确保视图被"渲染"（在macOS下）
                    _ = NSHostingView(rootView: view.frame(width: 0, height: 0).opacity(0))
                }
                
                // 超时处理
                Task {
                    do {
                        try await Task.sleep(nanoseconds: 5_000_000_000) // 5秒超时
                        if !isAvailable {
                            continuation.resume(returning: false)
                        }
                    } catch {
                        // 忽略超时任务被取消的情况
                    }
                }
            }
            
            return isAvailable
        } catch {
            print("Language availability check error: \(error.localizedDescription)")
            return false
        }
    }
} 