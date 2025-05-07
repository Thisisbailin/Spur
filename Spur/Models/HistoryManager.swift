import Foundation
import SwiftData
import Combine
import SwiftUI

/// 翻译历史记录管理器
class HistoryManager: ObservableObject {
    // 单例实例
    static let shared = HistoryManager()
    
    // 数据模型上下文
    private var modelContext: ModelContext?
    
    // 最近的翻译记录（用于UI展示）
    @Published var recentRecords: [TranslationRecord] = []
    
    // 最大保存的记录数量
    private let maxRecentRecords = 100
    
    // 私有初始化方法
    private init() {}
    
    /// 设置数据模型上下文
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadRecentRecords()
    }
    
    /// 添加新的翻译记录
    func addRecord(from result: TranslationResult, theme: String? = nil) {
        guard let modelContext = modelContext else {
            print("警告: ModelContext未设置，无法保存记录")
            return
        }
        
        // 创建新记录
        let record = TranslationRecord.from(result: result, theme: theme)
        
        // 保存到数据库
        modelContext.insert(record)
        
        // 尝试保存上下文
        do {
            try modelContext.save()
            // 更新最近记录
            loadRecentRecords()
        } catch {
            print("保存翻译记录失败: \(error.localizedDescription)")
        }
    }
    
    /// 加载最近的翻译记录
    func loadRecentRecords() {
        guard let modelContext = modelContext else { return }
        
        var descriptor = FetchDescriptor<TranslationRecord>(
            predicate: nil,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        // 设置最大获取记录数
        descriptor.fetchLimit = maxRecentRecords
        
        do {
            recentRecords = try modelContext.fetch(descriptor)
        } catch {
            print("加载翻译记录失败: \(error.localizedDescription)")
            recentRecords = []
        }
    }
    
    /// 设置记录为收藏
    func toggleFavorite(for record: TranslationRecord) {
        guard let modelContext = modelContext else { return }
        
        // 切换收藏状态
        record.isFavorite.toggle()
        
        // 保存更改
        do {
            try modelContext.save()
        } catch {
            print("更新收藏状态失败: \(error.localizedDescription)")
        }
    }
    
    /// 为记录添加标签
    func addTag(_ tag: String, to record: TranslationRecord) {
        guard let modelContext = modelContext else { return }
        
        // 如果标签不存在，则添加
        if !record.tags.contains(tag) {
            record.tags.append(tag)
            
            // 保存更改
            do {
                try modelContext.save()
            } catch {
                print("添加标签失败: \(error.localizedDescription)")
            }
        }
    }
    
    /// 删除记录
    func deleteRecord(_ record: TranslationRecord) {
        guard let modelContext = modelContext else { return }
        
        // 从数据库中删除
        modelContext.delete(record)
        
        // 保存更改
        do {
            try modelContext.save()
            // 更新最近记录
            loadRecentRecords()
        } catch {
            print("删除记录失败: \(error.localizedDescription)")
        }
    }
    
    /// 搜索翻译记录
    func searchRecords(query: String) -> [TranslationRecord] {
        guard let modelContext = modelContext, !query.isEmpty else { 
            return recentRecords 
        }
        
        let predicate = #Predicate<TranslationRecord> { record in
            record.originalText.contains(query) || 
            record.translatedText.contains(query)
        }
        
        let descriptor = FetchDescriptor<TranslationRecord>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("搜索记录失败: \(error.localizedDescription)")
            return []
        }
    }
    
    /// 获取收藏的记录
    func getFavorites() -> [TranslationRecord] {
        guard let modelContext = modelContext else { return [] }
        
        let predicate = #Predicate<TranslationRecord> { record in
            record.isFavorite == true
        }
        
        let descriptor = FetchDescriptor<TranslationRecord>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("获取收藏记录失败: \(error.localizedDescription)")
            return []
        }
    }
    
    /// 清除所有历史记录
    func clearAllHistory() {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<TranslationRecord>()
        
        do {
            let allRecords = try modelContext.fetch(descriptor)
            for record in allRecords {
                modelContext.delete(record)
            }
            try modelContext.save()
            recentRecords = []
        } catch {
            print("清除历史记录失败: \(error.localizedDescription)")
        }
    }
} 