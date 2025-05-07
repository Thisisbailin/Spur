//
//  OutputAreaView.swift
//  Spur
//
//  Created by Joe on 2025/5/7.
//

import SwiftUI

struct OutputAreaView: View {
    // MARK: - Properties

    // ViewModel引用
    @ObservedObject var viewModel: TranslationViewModel
    
    // Binding to control visibility of the result area
    @Binding var isResultVisible: Bool
    // Binding to indicate if translation is in progress
    @Binding var isLoading: Bool
    // Binding to store any error message during translation
    @Binding var errorMessage: String?
    // Binding to store the translated text
    @Binding var translatedText: String
    
    // 本地状态
    @State private var activeOverlay: OverlayType? = nil
    @State private var searchText: String = ""
    @State private var selectedHistoryTab: HistoryTab = .recent
    @State private var selectedSettingTab: SettingTab = .shortcut
    
    // 覆盖视图类型
    enum OverlayType {
        case history
        case settings
    }
    
    // 历史标签页枚举
    enum HistoryTab {
        case recent
        case favorites
    }
    
    // 设置标签页枚举
    enum SettingTab {
        case shortcut
        case appearance
        case gemini
    }
    
    // 计算过滤后的历史记录
    private var filteredRecords: [TranslationRecord] {
        let baseRecords: [TranslationRecord]
        
        // 根据选择的标签页获取基础记录集
        switch selectedHistoryTab {
        case .recent:
            baseRecords = viewModel.recentHistory
        case .favorites:
            baseRecords = viewModel.favoriteHistory
        }
        
        // 如果没有搜索文本，返回所有记录
        if searchText.isEmpty {
            return baseRecords
        }
        
        // 否则过滤记录
        return baseRecords.filter { record in
            record.originalText.localizedCaseInsensitiveContains(searchText) ||
            record.translatedText.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - Body

    var body: some View {
        // Display the result area only if isResultVisible is true
        if isResultVisible {
            ZStack {
                // 默认显示翻译结果，但当有覆盖层时隐藏
                if activeOverlay == nil {
                    translationResultView()
                        .transition(.opacity)
                }
                
                // 覆盖层 - 历史记录或设置
                if let overlay = activeOverlay {
                    overlayView(for: overlay)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .frame(minHeight: 30, idealHeight: 120, maxHeight: 300)
            .animation(.easeInOut(duration: 0.2), value: activeOverlay)
            .onAppear {
                // 监听菜单通知
                setupNotificationObservers()
            }
            .onDisappear {
                // 移除通知观察者
                removeNotificationObservers()
            }
        }
    }
    
    // 设置通知观察者
    private func setupNotificationObservers() {
        // 监听显示历史记录通知
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("showHistoryInOutput"),
            object: nil,
            queue: .main
        ) { _ in
            withAnimation {
                self.activeOverlay = .history
            }
        }
        
        // 监听显示设置通知
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("showSettingsInOutput"),
            object: nil,
            queue: .main
        ) { _ in
            withAnimation {
                self.activeOverlay = .settings
            }
        }
    }
    
    // 移除通知观察者
    private func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name("showHistoryInOutput"),
            object: nil
        )
        
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name("showSettingsInOutput"),
            object: nil
        )
    }
    
    // MARK: - 翻译结果视图
    
    private func translationResultView() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                // Show loading indicator if translation is in progress
                if isLoading {
                    VStack(spacing: 10) {
                        ProgressView()
                            .scaleEffect(0.7)
                            .padding(.vertical, 2)
                        Text("正在翻译...")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                } else if let errorMessage = errorMessage {
                    // Show error message if translation failed
                    VStack(alignment: .leading, spacing: 6) {
                        Text("翻译失败")
                            .font(.subheadline)
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }
                    .padding(EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12))
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    // Show translated text if successful
                    Text(translatedText)
                        .font(.system(size: 13))
                        .foregroundColor(.primary.opacity(0.85))
                        .padding(EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
            }
        }
    }
    
    // MARK: - 覆盖视图（历史记录或设置）
    
    private func overlayView(for type: OverlayType) -> some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text(type == .history ? "翻译历史" : "设置")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        activeOverlay = nil
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 18))
                }
                .buttonStyle(.plain)
                .buttonHoverEffect()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.primary.opacity(0.05))
            
            // 内容区域
            Group {
                if type == .history {
                    historyView()
                } else {
                    settingsView()
                }
            }
        }
        .background(Color.primary.opacity(0.03))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
    }
    
    // MARK: - 历史记录视图
    
    private func historyView() -> some View {
        VStack(spacing: 0) {
            // 搜索栏
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
                
                TextField("搜索翻译历史", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                    .buttonHoverEffect()
                }
            }
            .padding(6)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(6)
            .padding(.horizontal, 10)
            .padding(.top, 6)
            
            // 标签页选择器
            HStack(spacing: 0) {
                historyTabButton(title: "最近记录", tab: .recent)
                historyTabButton(title: "收藏", tab: .favorites)
            }
            .padding(.top, 6)
            
            // 历史记录列表
            if filteredRecords.isEmpty {
                historyEmptyStateView()
            } else {
                historyListView()
            }
        }
    }
    
    // 历史记录标签页按钮
    private func historyTabButton(title: String, tab: HistoryTab) -> some View {
        Button(action: {
            selectedHistoryTab = tab
        }) {
            Text(title)
                .font(.system(size: 12))
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .foregroundColor(selectedHistoryTab == tab ? .primary : .secondary)
        .background(
            VStack {
                Spacer()
                if selectedHistoryTab == tab {
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(height: 2)
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 2)
                }
            }
        )
        .hoverEffect(color: selectedHistoryTab == tab ? .accentColor : .primary)
    }
    
    // 历史记录空状态视图
    private func historyEmptyStateView() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 28))
                .foregroundColor(.secondary)
            
            Text(searchText.isEmpty 
                ? (selectedHistoryTab == .recent ? "暂无翻译记录" : "暂无收藏记录") 
                : "未找到匹配的翻译记录")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            if !searchText.isEmpty {
                Button("清除搜索") {
                    searchText = ""
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.small)
                .buttonHoverEffect()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical)
    }
    
    // 历史记录列表视图
    private func historyListView() -> some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(filteredRecords) { record in
                    historyItemView(record: record)
                        .onTapGesture {
                            viewModel.loadFromHistory(record: record)
                            withAnimation {
                                activeOverlay = nil // 切换回结果视图
                            }
                        }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
    }
    
    // 历史记录项视图
    private func historyItemView(record: TranslationRecord) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // 原始文本
            Text(record.originalText)
                .font(.system(size: 12))
                .foregroundColor(.primary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
                .padding(.vertical, 2)
            
            // 翻译文本
            Text(record.translatedText)
                .font(.system(size: 12))
                .foregroundColor(.primary.opacity(0.8))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 元数据
            HStack {
                Text(formatDate(record.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // 语言信息
                Text("\(formatLanguage(record.sourceLanguage)) → \(formatLanguage(record.targetLanguage))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                // 收藏按钮
                Button(action: {
                    viewModel.toggleFavorite(for: record)
                }) {
                    Image(systemName: record.isFavorite ? "star.fill" : "star")
                        .font(.system(size: 12))
                        .foregroundColor(record.isFavorite ? .yellow : .secondary)
                }
                .buttonStyle(.plain)
                .buttonHoverEffect()
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.primary.opacity(0.05))
        )
        .contentShape(Rectangle())
        .hoverEffect()
    }
    
    // 日期格式化
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // 语言代码格式化
    private func formatLanguage(_ code: String) -> String {
        if code == "auto" {
            return "自动"
        }
        
        // 尝试从语言数据中获取名称
        let language = LanguageData.language(for: code)
        return language.name
    }
    
    // MARK: - 设置视图
    
    private func settingsView() -> some View {
        VStack(spacing: 0) {
            // 设置标签页选择器
            HStack(spacing: 0) {
                settingTabButton(title: "快捷键", tab: .shortcut)
                settingTabButton(title: "外观", tab: .appearance)
                settingTabButton(title: "Gemini", tab: .gemini)
            }
            .padding(.top, 6)
            
            // 设置内容
            ScrollView {
                switch selectedSettingTab {
                case .shortcut:
                    shortcutSettingsView()
                case .appearance:
                    appearanceSettingsView()
                case .gemini:
                    geminiSettingsView()
                }
            }
            .padding()
        }
    }
    
    // 设置标签页按钮
    private func settingTabButton(title: String, tab: SettingTab) -> some View {
        Button(action: {
            selectedSettingTab = tab
        }) {
            Text(title)
                .font(.system(size: 12))
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .foregroundColor(selectedSettingTab == tab ? .primary : .secondary)
        .background(
            VStack {
                Spacer()
                if selectedSettingTab == tab {
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(height: 2)
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 2)
                }
            }
        )
        .hoverEffect(color: selectedSettingTab == tab ? .accentColor : .primary)
    }
    
    // 快捷键设置视图
    private func shortcutSettingsView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            shortcutSettingItem(name: "显示/隐藏翻译", key: "⌘+⇧+T")
            shortcutSettingItem(name: "翻译选中文本", key: "⌘+⇧+X")
            shortcutSettingItem(name: "清空输入", key: "⌘+⌫")
            shortcutSettingItem(name: "切换翻译引擎", key: "⌘+E")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // 快捷键设置项
    private func shortcutSettingItem(name: String, key: String) -> some View {
        HStack {
            Text(name)
                .font(.system(size: 12))
            
            Spacer()
            
            Text(key)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.primary.opacity(0.1))
                .cornerRadius(4)
        }
    }
    
    // 外观设置视图
    private func appearanceSettingsView() -> some View {
        // 获取UserSettings环境对象
        @EnvironmentObject var userSettings: UserSettings
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("应用主题")
                .font(.system(size: 12, weight: .medium))
            
            HStack(spacing: 12) {
                themeButton(
                    name: AppColorScheme.light.title,
                    systemName: "sun.max",
                    isSelected: userSettings.colorScheme == .light,
                    action: { userSettings.colorScheme = .light }
                )
                
                themeButton(
                    name: AppColorScheme.dark.title,
                    systemName: "moon",
                    isSelected: userSettings.colorScheme == .dark,
                    action: { userSettings.colorScheme = .dark }
                )
                
                themeButton(
                    name: AppColorScheme.system.title,
                    systemName: "circle.lefthalf.filled",
                    isSelected: userSettings.colorScheme == .system,
                    action: { userSettings.colorScheme = .system }
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .environmentObject(userSettings) // 确保环境对象可用
    }
    
    // 主题按钮
    private func themeButton(name: String, systemName: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemName)
                    .font(.system(size: 20))
                
                Text(name)
                    .font(.system(size: 12))
            }
            .padding(8)
            .frame(width: 70, height: 70)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.primary.opacity(0.2), lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.primary.opacity(0.05))
                    )
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .hoverEffect()
    }
    
    // Gemini设置视图
    private func geminiSettingsView() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // 默认翻译偏好
            VStack(alignment: .leading, spacing: 8) {
                Text("默认翻译偏好")
                    .font(.system(size: 12, weight: .medium))
                
                Picker("", selection: $viewModel.geminiTranslationTheme) {
                    ForEach(viewModel.themes) { theme in
                        Text(theme.name).tag(theme.id)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
            
            // 自定义偏好（占位符）
            VStack(alignment: .leading, spacing: 8) {
                Text("自定义翻译偏好")
                    .font(.system(size: 12, weight: .medium))
                
                HStack {
                    Button(action: {}) {
                        Label("创建新偏好", systemImage: "plus")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .buttonHoverEffect()
                    
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - 公共方法
    
    /// 显示历史记录覆盖视图
    func showHistory() {
        withAnimation {
            activeOverlay = .history
        }
    }
    
    /// 显示设置覆盖视图
    func showSettings() {
        withAnimation {
            activeOverlay = .settings
        }
    }
}

