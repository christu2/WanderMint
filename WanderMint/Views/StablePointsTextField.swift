import SwiftUI

struct StablePointsTextField: View {
    @Binding var text: String
    @State private var isEditing = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack {
            TextField("Points", text: $text)
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
                }
            
            if isEditing && !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(Color.white)
        .cornerRadius(AppTheme.CornerRadius.sm)
        .applyShadow(Shadow(color: AppTheme.Shadows.light, radius: 1, x: 0, y: 1))
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isFocused = false
                }
            }
        }
    }
}

#Preview {
    StablePointsTextField(text: .constant(""))
}