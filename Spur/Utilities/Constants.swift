import Foundation
import SwiftUI

/// 应用程序常量
enum AppConstants {
    /// 应用程序名称
    static let appName = "Spur"
    
    /// 应用程序版本
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    
    /// 应用程序构建版本
    static let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    /// 应用程序完整版本
    static var fullVersion: String {
        return "\(appVersion) (\(buildVersion))"
    }
    
    /// 应用程序版权信息
    static let copyright = "© 2025 Joe"
    
    /// 应用程序窗口ID
    static let mainWindowID = "spur-panel"
}

/// UI相关常量
enum UIConstants {
    /// 文本尺寸
    enum TextSize {
        static let small: CGFloat = 12
        static let medium: CGFloat = 14
        static let large: CGFloat = 16
        static let headline: CGFloat = 18
    }
    
    /// 间距
    enum Spacing {
        static let small: CGFloat = 4
        static let medium: CGFloat = 8
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 24
    }
    
    /// 圆角
    enum CornerRadius {
        static let small: CGFloat = 4
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
        static let extraLarge: CGFloat = 18
    }
    
    /// 动画
    enum Animation {
        static let quick = SwiftUI.Animation.easeOut(duration: 0.2)
        static let normal = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let springy = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.8)
    }
} 