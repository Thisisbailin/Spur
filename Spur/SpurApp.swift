//
//  SpurApp.swift
//  Spur
//
//  Created by Joe on 2025/5/7.
//

import SwiftUI

@main
struct SpurApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

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
