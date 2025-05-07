//
//  AppDelegate.swift
//  Spur
//
//  Created by Joe on 2025/5/7.
//

import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    var spurPanelWindowController: NSWindowController? // 用于管理我们的 Spur 面板
    var statusItem: NSStatusItem?
    var appMenu: NSMenu? // 用于菜单栏图标的菜单

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 设置为配件应用，不显示在 Dock 中，除非被激活
        // NSApp.setActivationPolicy(.accessory) // 可以根据需要启用

        // 创建状态栏项目
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength) // 可变长度更好
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "text.bubble.fill", accessibilityDescription: "Spur Translator")
            // button.action = #selector(statusItemClicked(_:)) // 现在点击会弹出菜单
            // button.target = self
            // 为按钮关联菜单
            setupAppMenu()
            statusItem?.menu = appMenu // 将菜单赋给 statusItem
        }
    }
    
    func setupAppMenu() {
        appMenu = NSMenu(title: "Spur Menu")
        
        appMenu?.addItem(
            withTitle: "显示面板",
            action: #selector(showSpurPanelFromMenu),
            keyEquivalent: ""
        ).target = self
        
        appMenu?.addItem(NSMenuItem.separator())
        
        // 占位菜单项
        let frameworkItem = NSMenuItem(title: "翻译框架 (占位)", action: nil, keyEquivalent: "")
        let themeItem = NSMenuItem(title: "偏好主题 (占位)", action: nil, keyEquivalent: "")
        let historyItem = NSMenuItem(title: "历史记录 (占位)", action: nil, keyEquivalent: "")
        let settingsItem = NSMenuItem(title: "设置 (占位)", action: nil, keyEquivalent: "")
        
        [frameworkItem, themeItem, historyItem, settingsItem].forEach { $0.isEnabled = false } // 暂时禁用
        appMenu?.addItem(frameworkItem)
        appMenu?.addItem(themeItem)
        appMenu?.addItem(historyItem)
        appMenu?.addItem(settingsItem)
        
        appMenu?.addItem(NSMenuItem.separator())
        
        appMenu?.addItem(
            withTitle: "退出 Spur",
            action: #selector(NSApplication.terminate(_:)), // 使用标准的 terminate
            keyEquivalent: "q" //  可以给一个快捷键 Command+Q (系统会自动处理)
        ).target = NSApp // target 是 NSApp
    }

    @objc func showSpurPanelFromMenu() {
        ensureSpurPanelWindowExistsAndIsReady() // 确保窗口存在并已准备好
        
        guard let panelWindow = self.window else {
            print("Error: Panel window is nil even after trying to ensure its existence.")
            return
        }
        
        if panelWindow.isVisible {
            // 如果已经可见，可能只是把它带到最前
            NSApp.activate(ignoringOtherApps: true)
            panelWindow.makeKeyAndOrderFront(nil)
        } else {
            showAndFocusPanelWindow()
        }
    }
    
    // 这个方法现在是核心，用于确保我们的 ContentView 的 NSWindow 实例被创建和获取
    private func ensureSpurPanelWindowExistsAndIsReady() {
        if self.window == nil {
            print("Spur panel window is nil. Attempting to find or create.")
            // 激活应用，这应该会触发 SpurApp 中的 WindowGroup 创建窗口
            NSApp.activate(ignoringOtherApps: true)
            
            // 短暂延迟，给 SwiftUI 时间来创建和通过 WindowAccessor 传递窗口
            // 这是一个尝试性的时序同步，理想情况下应该有更确定的机制
            // 但在 AppKit/SwiftUI 混合中，有时需要这样的延迟
            let group = DispatchGroup()
            group.enter()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // 增加一点延迟
                group.leave()
            }
            group.wait() // 等待一小段时间

            if self.window == nil {
                 print("Still nil after delay. This indicates WindowAccessor might not have run or passed the window.")
                 // 作为最后的手段，尝试查找具有特定ID的窗口
                 // (这要求 WindowGroup 有一个唯一的 title 或 identifier)
                 for w in NSApp.windows {
                     // 如果 WindowGroup 设置了 title "SpurTranslatorPanel"
                     if w.title == "SpurTranslatorPanel" {
                         print("Found window by title: \(w.title)")
                         self.window = w // 得到了引用
                         // 需要手动调用 passWindowFromSwiftUI 的部分逻辑来完成配置
                         self.passWindowFromSwiftUI(w, initialHide: false) // 传递并配置
                         break
                     }
                 }
                 if self.window == nil {
                     print("FATAL: Could not obtain window reference for Spur panel.")
                     return
                 }
            }
        }
        // 确保窗口已配置
        ensureWindowConfigured(window: self.window!)
    }

    private func ensureWindowConfigured(window: NSWindow) {
        if window.isOpaque || window.backgroundColor != .clear {
            print("Configuring window...")
            window.isOpaque = false
            window.backgroundColor = .clear // 非常重要
            window.hasShadow = false // 移除系统默认阴影，我们可以在ContentView上加自定义阴影
            
            window.standardWindowButton(.closeButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
            window.isMovableByWindowBackground = true
            // window.level = .floating // 可选

            NotificationCenter.default.addObserver(forName: NSWindow.didResignKeyNotification, object: window, queue: .main) { [weak self] _ in
                self?.hidePanelWindow()
            }
            print("Window configured.")
        }
    }
    
    private func showAndFocusPanelWindow() {
        guard let panelWindow = self.window else { return }
        
        NSApp.activate(ignoringOtherApps: true)
        panelWindow.makeKeyAndOrderFront(nil)
        
        // 定位到屏幕底部中央
        if let screen = panelWindow.screen ?? NSScreen.main {
            let screenRect = screen.visibleFrame // 可用区域，不包括Dock和菜单栏
            let windowSize = panelWindow.frame.size
            
            let xPos = screenRect.origin.x + (screenRect.width - windowSize.width) / 2
            // Y 坐标从屏幕底部向上计算，留一点边距
            let yPos = screenRect.origin.y + 20 // 例如，距离底部20像素
            
            panelWindow.setFrameOrigin(NSPoint(x: xPos, y: yPos))
        } else {
            panelWindow.center() // 备选方案
        }
        
        // 后续添加聚焦 TextField 的逻辑
        print("Panel window shown and focused at bottom center.")
    }

    private func hidePanelWindow() {
        window?.orderOut(nil)
        print("Panel window hidden.")
    }

    // 修改 passWindowFromSwiftUI 接受一个额外参数，指示是否需要初始隐藏
    func passWindowFromSwiftUI(_ nsWindow: NSWindow, initialHide: Bool = true) {
        if self.window == nil {
            self.window = nsWindow
            print("Window reference passed from SwiftUI and stored in AppDelegate.")
            if initialHide {
                nsWindow.orderOut(nil) // 确保初始隐藏
            }
            // 即使不是初始隐藏（例如通过title找到），也需要配置
            ensureWindowConfigured(window: nsWindow)
        } else if self.window != nsWindow {
            // 如果 WindowAccessor 由于某种原因被多次调用并传递了不同的窗口实例
            print("Warning: A new window instance was passed from SwiftUI. Updating reference.")
            self.window = nsWindow
            if initialHide {
                nsWindow.orderOut(nil)
            }
            ensureWindowConfigured(window: nsWindow)
        }
    }
}
