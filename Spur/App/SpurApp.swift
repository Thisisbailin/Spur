//
//  SpurApp.swift
//  Spur
//
//  Created by Joe on 2025/5/7.
//

import SwiftUI
import SwiftData

// 应用颜色方案枚举
enum AppColorScheme: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var title: String {
        switch self {
        case .light: return "浅色"
        case .dark: return "深色"
        case .system: return "跟随系统"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

// 用户设置对象，用于存储和管理用户偏好
class UserSettings: ObservableObject {
    @Published var colorScheme: AppColorScheme {
        didSet {
            UserDefaults.standard.set(colorScheme.rawValue, forKey: "appColorScheme")
        }
    }
    
    init() {
        let savedScheme = UserDefaults.standard.string(forKey: "appColorScheme") ?? AppColorScheme.system.rawValue
        self.colorScheme = AppColorScheme(rawValue: savedScheme) ?? .system
    }
}

@main
struct SpurApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var userSettings = UserSettings()
    
    // 配置SwiftData模型容器
    let modelContainer: ModelContainer
    
    init() {
        do {
            // 创建和配置SwiftData模型容器
            let schema = Schema([
                TranslationRecord.self,
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("无法创建模型容器: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup("SpurTranslatorPanel", id: "spur-panel") { // 确保这个 Title 唯一
            ContentView()
                .background(WindowAccessor(callback: { window in
                    if let nsWindow = window {
                        // AppDelegate 的 passWindowFromSwiftUI 会处理初始隐藏
                        appDelegate.passWindowFromSwiftUI(nsWindow)
                    }
                }))
                .frame(minWidth: 320, idealWidth: 380, maxWidth: 500,
                       minHeight: 100, idealHeight: 150, maxHeight: 500) // 给一个合理的初始高度
                .modelContainer(modelContainer) // 使用模型容器
                .preferredColorScheme(userSettings.colorScheme.colorScheme) // 应用颜色方案
                .environmentObject(userSettings) // 将设置注入环境
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        // macOS 13+ 可以尝试移除窗口的默认边框/标题栏效果
        // .windowStyle(.titleBar) // 尝试不同的系统样式
        // .windowToolbarStyle(.automatic, showsTitle: false)
    }
}

struct WindowAccessor: NSViewRepresentable {
    var callback: (NSWindow?) -> Void
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        // 使用 DispatchQueue.main.async 确保 window 属性已设置
        DispatchQueue.main.async {
            self.callback(view.window)
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}
