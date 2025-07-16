import SwiftUI

struct StableBudgetTextField: View {
    @Binding var text: String
    @State private var isEditing = false
    @State private var displayText = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack {
            TextField("Enter budget", text: $displayText)
                .keyboardType(.numberPad)
                .focused($isFocused)
                .textFieldStyle(PlainTextFieldStyle())
                .onTapGesture {
                    if !isFocused {
                        isFocused = true
                    }
                }
                .onChange(of: isFocused) { focused in
                    isEditing = focused
                    if focused {
                        // When editing starts, show unformatted text
                        displayText = text.replacingOccurrences(of: ",", with: "")
                    } else {
                        // When editing ends, format the text and update binding
                        formatAndUpdateText()
                    }
                }
                .onChange(of: displayText) { newValue in
                    if isFocused {
                        // Only allow numbers while editing
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered != newValue {
                            displayText = filtered
                        }
                        // Update the binding with unformatted text
                        text = filtered
                    }
                }
                .onAppear {
                    // Initialize display text with formatted version
                    displayText = formatNumber(text)
                }
            
            if isEditing && !displayText.isEmpty {
                Button(action: {
                    text = ""
                    displayText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(Color.white)
        .cornerRadius(AppTheme.CornerRadius.md)
        .applyShadow(Shadow(color: AppTheme.Shadows.light, radius: 2, x: 0, y: 1))
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isFocused = false
                }
            }
        }
    }
    
    private func formatNumber(_ input: String) -> String {
        let cleanInput = input.replacingOccurrences(of: ",", with: "")
        guard !cleanInput.isEmpty, let number = Int(cleanInput) else {
            return input
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? input
    }
    
    private func formatAndUpdateText() {
        let cleanText = displayText.replacingOccurrences(of: ",", with: "")
        text = cleanText
        displayText = formatNumber(cleanText)
    }
}

#Preview {
    StableBudgetTextField(text: .constant(""))
}