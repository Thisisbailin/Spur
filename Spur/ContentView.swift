//
//  ContentView.swift
//  Spur
//
//  Created by Joe on 2025/5/7.
//

import SwiftUI
import Combine // For listening to Enter key

struct ContentView: View {
    @State private var inputText: String = ""
    @State private var translatedText: String = ""
    @State private var isResultVisible: Bool = false
    @State private var isLoading: Bool = false

    @State private var selectedTranslationEngine: String = "Translation"
    @State private var selectedTheme: String = "日常"
    @State private var textEditorHeight: CGFloat = 40
    private let minTextEditorHeight: CGFloat = 40
    private let maxTextEditorHeight: CGFloat = 150

    // FocusState for TextEditor
    @FocusState private var isTextEditorFocused: Bool

    // Subject to publish Enter key presses
    private let enterKeyPressSubject = PassthroughSubject<Void, Never>()


    private func performTranslationAction() {
        let trimmedInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedInput.isEmpty {
            withAnimation { isResultVisible = false }
            return
        }
        isLoading = true
        // Simulate translation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            translatedText = "翻译结果: \(trimmedInput)\n多行内容测试，确保显示正常。"
            isLoading = false
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isResultVisible = true
            }
            // 清空输入框并重置高度 (如果需要)
            // inputText = ""
            // textEditorHeight = minTextEditorHeight
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 1. Result Area
            if isResultVisible {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        if isLoading {
                            ProgressView().padding()
                        } else {
                            Text(translatedText)
                                .font(.system(size: 14))
                                .foregroundColor(.primary.opacity(0.85))
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                    }
                }
                .frame(minHeight: 40, idealHeight: 120, maxHeight: 250)
            }

            // 2. Input Area
            VStack(spacing: 0) {
                // 2a. Text Input Area
                ZStack(alignment: .topTrailing) { // Use ZStack for potential clear button
                    TextEditor(text: $inputText)
                        .focused($isTextEditorFocused)
                        .font(.system(size: 15))
                        .frame(height: textEditorHeight)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 6) // Add some vertical padding inside TextEditor
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .onChange(of: inputText) { newValue in
                            // Remove trailing newline if it was added by Enter press that we handled
                            if newValue.hasSuffix("\n") && newValue.count > previousInputText.count {
                                // This logic is tricky; we want to send on Enter, not just add newline
                                // The PassthroughSubject approach is more robust for Enter detection.
                            }
                            previousInputText = newValue // Keep track of previous text

                            let lines = newValue.split(whereSeparator: \.isNewline).count
                            let baseLineHeight: CGFloat = 20 // Approximate height per line
                            let padding: CGFloat = 20 // Base padding and spacing
                            var estimatedHeight = CGFloat(lines) * baseLineHeight + padding
                            // Special case for single line, ensure it's not too cramped
                            if lines == 1 && !newValue.isEmpty {
                                estimatedHeight = max(minTextEditorHeight, baseLineHeight + padding)
                            } else if newValue.isEmpty {
                                estimatedHeight = minTextEditorHeight
                            }
                            self.textEditorHeight = min(max(estimatedHeight, minTextEditorHeight), maxTextEditorHeight)
                        }
                        // Custom modifier to handle Enter key press
                        .onReceive(NotificationCenter.default.publisher(for: NSTextView.didChangeNotification)) { obj in
                            guard let textView = obj.object as? NSTextView, textView.string == inputText else { return }
                            // This notification fires for many changes. For Enter specifically,
                            // we'd need to inspect the actual key event, which is harder in pure SwiftUI.
                            // The PassthroughSubject method with a custom NSViewRepresentable is better.
                            // For now, we'll rely on onCommand for Shift+Enter for newline.
                        }
                        .onCommand(#selector(NSResponder.insertNewline(_:))) {
                            // Default Enter behavior: usually adds a newline. We want to send.
                            // If we want Enter to send, and Shift+Enter for newline, this needs more work.
                            // For simplicity now, Enter will still add newline, send button is primary.
                            // To make Enter send:
                            // 1. Prevent default newline.
                            // 2. Call performTranslationAction().
                            // This often requires an NSViewRepresentable wrapper for TextEditor.
                            // Or a "hack" by checking if the last char is a newline after a change.
                            print("Enter pressed (default newline)")
                        }


                    // Removed the 'x' clear button as per request
                }
                .padding(.top, 8)
                .padding(.horizontal, 8)

                // 2b. Controls Area
                HStack(spacing: 0) { // Reduce spacing to 0 and use padding on items
                    Group { // Group for easier padding application
                        Menu {
                            Button("Apple Translation") { selectedTranslationEngine = "Translation" }
                            Button("Gemini API") { selectedTranslationEngine = "Gemini" }
                        } label: {
                            Image(systemName: "globe")
                                .font(.system(size: 17)) // Slightly smaller icon
                                .frame(width: 30, height: 30) // Ensure tap area
                                .contentShape(Rectangle())
                        }
                        .menuStyle(.borderlessButton)
                        .padding(.horizontal, 4)


                        Menu {
                            Button("日常") { selectedTheme = "日常" }
                            Button("学术") { selectedTheme = "学术" }
                            Button("词源") { selectedTheme = "词源" }
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 17))
                                .frame(width: 30, height: 30)
                                .contentShape(Rectangle())
                        }
                        .menuStyle(.borderlessButton)
                        .padding(.horizontal, 4)

                        Button { print("History Tapped") } label: {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 17))
                                .frame(width: 30, height: 30)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 4)
                    
                        Button { print("Settings Tapped") } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 17))
                                .frame(width: 30, height: 30)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 4)
                    }
                    .foregroundColor(.secondary) // Dim the control icons a bit

                    Spacer()

                    Button(action: performTranslationAction) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 22))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray.opacity(0.5) : Color.accentColor)
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.horizontal, 6)
                }
                .padding(EdgeInsets(top: 6, leading: 10, bottom: 8, trailing: 10)) // Adjusted padding
            }
            .background(Color.primary.opacity(0.04)) // Subtle background for input area
        }
        .background(.regularMaterial) // Main panel material
        .cornerRadius(18) // Slightly larger corner radius
        // Add a very subtle shadow to the panel itself
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        // Animations
        .animation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.3), value: isResultVisible)
        .animation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.3), value: isLoading)
        .animation(.smooth(duration: 0.2), value: textEditorHeight) // Smoother height animation
        .onAppear {
            textEditorHeight = minTextEditorHeight
            // Try to focus TextEditor when panel appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // Delay to ensure view is ready
                self.isTextEditorFocused = true
            }
        }
        // Store previous inputText to help with Enter key logic (if needed)
        .onStateChange(of: inputText) { newValue, oldValue in
             self.previousInputText = oldValue
        }
    }
    // Helper to store previous inputText value
    @State private var previousInputText: String = ""
}

// Helper for .onStateChange (optional, you can just use .onChange)
extension View {
    func onStateChange<Value: Equatable>(of value: Value, action: @escaping (_ newValue: Value, _ oldValue: Value) -> Void) -> some View {
        modifier(HostView(value: value, action: action))
    }
}

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


#Preview {
    ContentView()
        .frame(width: 380)
        .padding(50)
        .background(Color.purple.opacity(0.2))
}
