//
//  InputAreaView.swift
//  Spur
//
//  Created by Joe on 2025/5/7.
//

import SwiftUI
import Combine
import AppKit // 用于文件选择器和图像处理

struct InputAreaView: View {
    // MARK: - Properties

    // Bindings for state managed by ContentView
    @Binding var inputText: String
    @Binding var selectedTranslationEngine: String
    @Binding var sourceLanguage: String
    @Binding var appleTargetLanguage: String
    @Binding var geminiTranslationTheme: String
    @Binding var textEditorHeight: CGFloat
    @Binding var previousInputText: String // For Enter key detection logic

    // 添加对ViewModel的引用，用于调用方法
    var viewModel: TranslationViewModel

    // FocusState for TextEditor, passed from ContentView
    @FocusState.Binding var isTextEditorFocused: Bool
    
    // OCR相关状态
    @State private var isImagePickerPresented: Bool = false
    @State private var selectedImage: NSImage? = nil
    
    // Computed property to determine if Apple Translation is used
    var isUsingAppleTranslation: Bool {
        selectedTranslationEngine == "Apple Translation"
    }

    // Data for menus
    let languages: [Language] = LanguageData.common
    let engines: [TranslationEngine] = TranslationEngineData.all
    let themes: [TranslationTheme] = TranslationThemeData.all
    
    // Translation manager instance (can be passed or accessed if it's a singleton)
    // For simplicity here, assuming it's accessible or passed if methods are called directly.
    // If TranslationManager methods are needed inside this view, it should be passed.
    // let translationManager: TranslationManager = TranslationManager.shared
    // However, since performTranslationAction is a closure, it doesn't need direct access here.

    // Action to perform translation
    var performTranslationAction: () -> Void
    
    // Constants for TextEditor height
    private let minTextEditorHeight: CGFloat = 35 // Reduced min height
    private let maxTextEditorHeight: CGFloat = 100 // Reduced max height

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Language and Theme selection bar
            HStack(spacing: 6) { // Reduced spacing
                if isUsingAppleTranslation {
                    // Source Language Menu (Apple)
                    languageMenu(selection: $sourceLanguage, availableLanguages: languages, title: LanguageData.language(for: sourceLanguage).name)
                    
                    // Swap Languages Button (Apple)
                    swapLanguagesButton()
                    
                    // Target Language Menu (Apple)
                    languageMenu(selection: $appleTargetLanguage, availableLanguages: languages.filter { $0.code != "auto" }, title: LanguageData.language(for: appleTargetLanguage).name)
                } else {
                    // Source Language Menu (Gemini)
                    languageMenu(selection: $sourceLanguage, availableLanguages: languages, title: LanguageData.language(for: sourceLanguage).name)
                    
                    Spacer()
                    
                    // Theme Menu (Gemini)
                    themeMenu()
                }
            }
            .padding(.horizontal, 8) // Reduced horizontal padding
            .padding(.top, 6)    // Reduced top padding
            .padding(.bottom, 3) // Reduced bottom padding

            // Text Input Area
            textInputEditor()
                .padding(.top, 3) // Reduced top padding
                .padding(.horizontal, 6) // Reduced horizontal padding

            // Controls Area (Engine and Translate Button)
            controlsBar()
                .padding(EdgeInsets(top: 5, leading: 8, bottom: 6, trailing: 8)) // Reduced padding
        }
        .background(Color.primary.opacity(0.04))
        .sheet(isPresented: $isImagePickerPresented) {
            // 处理图像选择
            ImagePickerView { selectedImage in
                if let image = selectedImage {
                    // 执行OCR翻译
                    self.selectedImage = image
                    viewModel.performOCRTranslation(with: image)
                }
                isImagePickerPresented = false
            }
        }
    }

    // MARK: - Subviews

    // Generic Language Menu
    @ViewBuilder
    private func languageMenu(selection: Binding<String>, availableLanguages: [Language], title: String) -> some View {
        Menu {
            ForEach(availableLanguages) { language in
                Button(language.name) {
                    selection.wrappedValue = language.code
                }
            }
        } label: {
            HStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .scaleEffect(0.8)
            }
            .padding(.vertical, 5) // Reduced padding
            .padding(.horizontal, 7) // Reduced padding
            .background(Color.primary.opacity(0.06))
            .cornerRadius(5) // Slightly smaller corner radius
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain) // Use plain button style for menus
        .menuLabelHoverEffect() // 添加悬停效果
    }

    // Swap Languages Button
    @ViewBuilder
    private func swapLanguagesButton() -> some View {
        Button(action: {
            if sourceLanguage != "auto" { // Only swap if source is not auto-detect
                let temp = sourceLanguage
                sourceLanguage = appleTargetLanguage
                appleTargetLanguage = temp
            }
        }) {
            Image(systemName: "arrow.left.arrow.right")
                .font(.caption)
                .frame(height: 24) // Reduced height
                .padding(.horizontal, 5) // Reduced padding
                .foregroundColor(.accentColor)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(sourceLanguage == "auto")
        .buttonHoverEffect() // 添加悬停效果
    }

    // Gemini Theme Menu
    @ViewBuilder
    private func themeMenu() -> some View {
        Menu {
            ForEach(themes) { theme in
                Button(theme.name) {
                    geminiTranslationTheme = theme.id
                    // If TranslationManager is accessible:
                    // translationManager.setTranslationTheme(theme.id)
                }
            }
        } label: {
            HStack(spacing: 2) {
                Image(systemName: "wand.and.stars")
                    .font(.caption)
                Text(TranslationThemeData.theme(for: geminiTranslationTheme).name)
                    .font(.caption)
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .scaleEffect(0.8)
            }
            .padding(.vertical, 5) // Reduced padding
            .padding(.horizontal, 7) // Reduced padding
            .background(Color.primary.opacity(0.06))
            .cornerRadius(5)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .menuLabelHoverEffect() // 添加悬停效果
    }
    
    // Text Input Editor
    @ViewBuilder
    private func textInputEditor() -> some View {
        ZStack(alignment: .bottomTrailing) {
            TextEditor(text: $inputText)
                .focused($isTextEditorFocused) // Use the binding
                .font(.system(size: 14)) // Slightly smaller font
                .frame(height: textEditorHeight)
                .padding(.horizontal, 3) // Reduced padding
                .padding(.vertical, 4)   // Reduced padding
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .onChange(of: inputText) { oldValue, newValue in // Using new onChange syntax
                    // Enter key detection logic
                    if newValue.hasSuffix("\n") && newValue.count > previousInputText.count {
                        let trimmedInput = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmedInput.isEmpty && previousInputText.trimmingCharacters(in: .whitespacesAndNewlines) != trimmedInput {
                            inputText = trimmedInput // Remove newline
                            performTranslationAction()
                        }
                    }
                    previousInputText = newValue // Update previous text

                    // Dynamic height adjustment
                    let lines = newValue.split(whereSeparator: \.isNewline).count
                    let baseLineHeight: CGFloat = 18 // Adjusted base line height
                    let padding: CGFloat = 18      // Adjusted padding
                    var estimatedHeight = CGFloat(lines) * baseLineHeight + padding
                    if lines == 1 && !newValue.isEmpty {
                        estimatedHeight = max(minTextEditorHeight, baseLineHeight + padding)
                    } else if newValue.isEmpty {
                        estimatedHeight = minTextEditorHeight
                    }
                    self.textEditorHeight = min(max(estimatedHeight, minTextEditorHeight), maxTextEditorHeight)
                }
                .onCommand(#selector(NSResponder.insertNewline(_:))) {
                    // This can be used if you want specific action on Enter without Shift
                    // For now, the onChange handles translation on newline.
                }
            
            // OCR图像选择按钮
            if !isUsingAppleTranslation {
                Button(action: {
                    isImagePickerPresented = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.accentColor)
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                }
                .buttonStyle(.plain)
                .buttonHoverEffect()
                .help("添加图片进行OCR识别翻译")
                .padding(8)
            }
        }
    }

    // Controls Bar
    @ViewBuilder
    private func controlsBar() -> some View {
        HStack(spacing: 0) {
            // Translation Engine Menu
            Menu {
                ForEach(engines) { engine in
                    Button(engine.name) {
                        selectedTranslationEngine = engine.id
                    }
                }
            } label: {
                HStack(spacing: 3) { // Reduced spacing
                    Image(systemName: selectedTranslationEngine == "Apple Translation" ? "apple.logo" : "sparkle")
                        .font(.system(size: 14)) // Slightly smaller icon
                    Text(TranslationEngineData.engine(for: selectedTranslationEngine).name)
                        .font(.system(size: 11)) // Smaller font
                        .lineLimit(1)
                }
                .frame(width: 110, alignment: .leading) // Reduced width
                .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .padding(.horizontal, 3) // Reduced padding
            .help("选择翻译引擎")
            
            Spacer()
            
            // 如果有选中的图像，显示指示器
            if viewModel.hasSelectedImage {
                Text("图像OCR中...")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.trailing, 5)
            }

            // Translate Button
            Button(action: performTranslationAction) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 20)) // Slightly smaller icon
            }
            .buttonStyle(.plain)
            .foregroundColor(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray.opacity(0.5) : Color.accentColor)
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .padding(.horizontal, 5) // Reduced padding
            .buttonHoverEffect() // 添加悬停效果
            .help("翻译")
        }
    }
}

// MARK: - 图像选择器视图
struct ImagePickerView: View {
    var onSelect: (NSImage?) -> Void
    
    @State private var isHovering = false
    @State private var isDragging = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("选择图像进行OCR识别")
                .font(.headline)
            
            ZStack {
                Rectangle()
                    .fill(isDragging ? Color.accentColor.opacity(0.2) : Color.primary.opacity(0.05))
                    .frame(width: 300, height: 200)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isDragging ? Color.accentColor : Color.primary.opacity(0.2), lineWidth: 2)
                    )
                
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.image")
                        .font(.system(size: 40))
                        .foregroundColor(isDragging ? .accentColor : .primary.opacity(0.7))
                    
                    Text("拖放图像到此处")
                        .font(.body)
                    
                    Text("或")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("选择图像文件") {
                        openFileDialog()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            .onDrop(of: ["public.file-url"], isTargeted: $isDragging) { providers in
                guard let provider = providers.first else {
                    return false
                }
                
                provider.loadDataRepresentation(forTypeIdentifier: "public.file-url") { data, error in
                    if let data = data, 
                       let path = NSString(data: data, encoding: 4),
                       let url = URL(string: path as String), 
                       url.isFileURL {
                        let image = NSImage(contentsOf: url)
                        DispatchQueue.main.async {
                            onSelect(image)
                        }
                    }
                }
                
                return true
            }
            
            HStack {
                Button("取消") {
                    onSelect(nil)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                
                Spacer().frame(width: 20)
                
                Button("确认") {
                    // 直接关闭视图，图像已通过文件选择器处理
                    onSelect(nil)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .disabled(true) // 不需要确认按钮的功能，由文件选择器直接处理
            }
            .padding(.top, 10)
        }
        .padding(20)
        .frame(width: 350, height: 350)
    }
    
    // 打开文件选择器
    private func openFileDialog() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedContentTypes = [.image]
        
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                let image = NSImage(contentsOf: url)
                DispatchQueue.main.async {
                    onSelect(image)
                }
            }
        }
    }
}
