import SwiftUI

// 视图扩展
extension View {
    /// 当状态值发生变化时执行动作，同时提供旧值和新值
    /// - Parameters:
    ///   - value: 需要监听变化的值
    ///   - action: 当值变化时执行的闭包，提供新值和旧值
    /// - Returns: 修改后的视图
    func onStateChange<Value: Equatable>(of value: Value, action: @escaping (_ newValue: Value, _ oldValue: Value) -> Void) -> some View {
        modifier(HostView(value: value, action: action))
    }
}

/// 用于实现onStateChange的视图修饰器
struct HostView<Value: Equatable>: ViewModifier {
    @State private var oldValue: Value
    private let value: Value
    private let action: (_ newValue: Value, _ oldValue: Value) -> Void

    init(value: Value, action: @escaping (_ newValue: Value, _ oldValue: Value) -> Void) {
        self.value = value
        self._oldValue = State(initialValue: value)
        self.action = action
    }

    func body(content: Content) -> some View {
        content
            .onChange(of: value) { newValue in
                action(newValue, oldValue)
                oldValue = newValue
            }
    }
}

/// 添加悬停效果的视图扩展
extension View {
    /// 为视图添加悬停效果
    /// - Parameters:
    ///   - isHovered: 悬停状态
    /// - Returns: 修改后的视图
    func hoverEffect(color: Color = .accentColor) -> some View {
        modifier(HoverEffectModifier(color: color))
    }
    
    /// 为按钮添加悬停效果
    func buttonHoverEffect() -> some View {
        modifier(ButtonHoverEffectModifier())
    }
    
    /// 为菜单标签添加悬停效果
    func menuLabelHoverEffect() -> some View {
        modifier(MenuLabelHoverEffectModifier())
    }
}

/// 悬停效果修饰器
struct HoverEffectModifier: ViewModifier {
    @State private var isHovered = false
    let color: Color
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(color.opacity(isHovered ? 0.1 : 0))
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            .onHover { hovering in
                self.isHovered = hovering
            }
    }
}

/// 按钮悬停效果修饰器
struct ButtonHoverEffectModifier: ViewModifier {
    @State private var isHovered = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isHovered ? 0.8 : 1.0)
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            .onHover { hovering in
                self.isHovered = hovering
            }
    }
}

/// 菜单标签悬停效果修饰器
struct MenuLabelHoverEffectModifier: ViewModifier {
    @State private var isHovered = false
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.primary.opacity(isHovered ? 0.1 : 0.06))
            )
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .onHover { hovering in
                self.isHovered = hovering
            }
    }
} 