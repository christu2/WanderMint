import SwiftUI
import Combine

/// Keyboard handling utilities and view modifiers
class KeyboardHandler: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0
    @Published var isKeyboardVisible = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupKeyboardObservers()
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { notification in
                (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height
            }
            .sink { [weak self] height in
                withAnimation(.easeInOut(duration: 0.3)) {
                    self?.keyboardHeight = height
                    self?.isKeyboardVisible = true
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    self?.keyboardHeight = 0
                    self?.isKeyboardVisible = false
                }
            }
            .store(in: &cancellables)
    }
    
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Keyboard Avoiding View Modifier

struct KeyboardAvoidingModifier: ViewModifier {
    @StateObject private var keyboardHandler = KeyboardHandler()
    
    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardHandler.keyboardHeight)
            .animation(.easeInOut(duration: 0.3), value: keyboardHandler.keyboardHeight)
    }
}

// MARK: - Keyboard Toolbar Modifier

struct KeyboardToolbarModifier: ViewModifier {
    let showDoneButton: Bool
    let onDone: (() -> Void)?
    
    init(showDoneButton: Bool = true, onDone: (() -> Void)? = nil) {
        self.showDoneButton = showDoneButton
        self.onDone = onDone
    }
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    
                    if showDoneButton {
                        Button("Done") {
                            onDone?()
                            KeyboardHandler().dismissKeyboard()
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.accentColor)
                    }
                }
            }
    }
}

// MARK: - Smart TextField with Keyboard Handling

struct SmartTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    
    let keyboardType: UIKeyboardType
    let autocapitalization: TextInputAutocapitalization
    let autocorrection: Bool
    let showDoneButton: Bool
    let onCommit: (() -> Void)?
    let onEditingChanged: ((Bool) -> Void)?
    
    @FocusState private var isFocused: Bool
    
    init(
        title: String,
        placeholder: String = "",
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default,
        autocapitalization: TextInputAutocapitalization = .sentences,
        autocorrection: Bool = true,
        showDoneButton: Bool = true,
        onCommit: (() -> Void)? = nil,
        onEditingChanged: ((Bool) -> Void)? = nil
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.keyboardType = keyboardType
        self.autocapitalization = autocapitalization
        self.autocorrection = autocorrection
        self.showDoneButton = showDoneButton
        self.onCommit = onCommit
        self.onEditingChanged = onEditingChanged
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !title.isEmpty {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(autocapitalization)
                .keyboardType(keyboardType)
                .autocorrectionDisabled(!autocorrection)
                .focused($isFocused)
                .padding(12)
                .background(Color.white)
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                .onChange(of: isFocused) { focused in
                    onEditingChanged?(focused)
                }
                .onSubmit {
                    onCommit?()
                }
                .keyboardToolbar(showDoneButton: showDoneButton) {
                    isFocused = false
                    onCommit?()
                }
        }
    }
}

// MARK: - Smart TextEditor with Keyboard Handling

struct SmartTextEditor: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    
    let minHeight: CGFloat
    let maxHeight: CGFloat
    let autocapitalization: TextInputAutocapitalization
    let autocorrection: Bool
    let showDoneButton: Bool
    let onEditingChanged: ((Bool) -> Void)?
    
    @FocusState private var isFocused: Bool
    
    init(
        title: String,
        placeholder: String = "",
        text: Binding<String>,
        minHeight: CGFloat = 100,
        maxHeight: CGFloat = 200,
        autocapitalization: TextInputAutocapitalization = .sentences,
        autocorrection: Bool = true,
        showDoneButton: Bool = true,
        onEditingChanged: ((Bool) -> Void)? = nil
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.autocapitalization = autocapitalization
        self.autocorrection = autocorrection
        self.showDoneButton = showDoneButton
        self.onEditingChanged = onEditingChanged
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !title.isEmpty {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .textInputAutocapitalization(autocapitalization)
                    .autocorrectionDisabled(!autocorrection)
                    .focused($isFocused)
                    .frame(minHeight: minHeight, maxHeight: maxHeight)
                    .padding(8)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    .onChange(of: isFocused) { focused in
                        onEditingChanged?(focused)
                    }
                    .keyboardToolbar(showDoneButton: showDoneButton) {
                        isFocused = false
                    }
                
                if text.isEmpty && !placeholder.isEmpty {
                    Text(placeholder)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }
        }
    }
}

// MARK: - Keyboard Responsive ScrollView

struct KeyboardResponsiveScrollView<Content: View>: View {
    let content: Content
    @StateObject private var keyboardHandler = KeyboardHandler()
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            content
                .padding(.bottom, keyboardHandler.keyboardHeight)
        }
        .animation(.easeInOut(duration: 0.3), value: keyboardHandler.keyboardHeight)
        .onTapGesture {
            if keyboardHandler.isKeyboardVisible {
                keyboardHandler.dismissKeyboard()
            }
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply keyboard avoidance to a view
    func keyboardAvoiding() -> some View {
        self.modifier(KeyboardAvoidingModifier())
    }
    
    /// Add keyboard toolbar with Done button
    func keyboardToolbar(showDoneButton: Bool = true, onDone: (() -> Void)? = nil) -> some View {
        self.modifier(KeyboardToolbarModifier(showDoneButton: showDoneButton, onDone: onDone))
    }
    
    /// Dismiss keyboard when tapping outside
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        }
    }
    
    /// Make the view keyboard responsive
    func keyboardResponsive() -> some View {
        KeyboardResponsiveScrollView {
            self
        }
    }
}

// MARK: - Focus Management

class FocusCoordinator: ObservableObject {
    @Published var currentFocus: FocusField?
    
    func focus(_ field: FocusField) {
        currentFocus = field
    }
    
    func clearFocus() {
        currentFocus = nil
    }
    
    func nextField(_ current: FocusField) {
        if let nextField = current.next {
            focus(nextField)
        } else {
            clearFocus()
        }
    }
}

enum FocusField: Hashable {
    case departureLocation
    case destination(Int)
    case budget
    case groupSize
    case specialRequests
    
    var next: FocusField? {
        switch self {
        case .departureLocation:
            return .destination(0)
        case .destination(_):
            return .budget
        case .budget:
            return .specialRequests
        case .groupSize:
            return .specialRequests
        case .specialRequests:
            return nil
        }
    }
    
    static var allCases: [FocusField] {
        return [
            .departureLocation,
            .destination(0),
            .budget,
            .groupSize,
            .specialRequests
        ]
    }
}

// MARK: - Keyboard Safe Area

struct KeyboardSafeArea: ViewModifier {
    @StateObject private var keyboardHandler = KeyboardHandler()
    
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: keyboardHandler.keyboardHeight)
                    .animation(.easeInOut(duration: 0.3), value: keyboardHandler.keyboardHeight)
            }
    }
}

extension View {
    func keyboardSafeArea() -> some View {
        self.modifier(KeyboardSafeArea())
    }
}