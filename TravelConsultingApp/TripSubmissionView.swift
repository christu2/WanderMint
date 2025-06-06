import SwiftUI

struct TripSubmissionView: View {
    @StateObject private var viewModel = TripSubmissionViewModel()
    @State private var destination = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(7 * 24 * 60 * 60) // 7 days from now
    @State private var paymentMethod = "Credit Card"
    @State private var flexibleDates = false
    
    let paymentMethods = ["Credit Card", "Debit Card", "PayPal", "Bank Transfer"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Trip Details")) {
                    TextField("Destination", text: $destination)
                        .textInputAutocapitalization(.words)
                    
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    
                    Toggle("Flexible Dates", isOn: $flexibleDates)
                }
                
                Section(header: Text("Payment")) {
                    Picker("Payment Method", selection: $paymentMethod) {
                        ForEach(paymentMethods, id: \.self) { method in
                            Text(method).tag(method)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section {
                    Button(action: submitTrip) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(viewModel.isLoading ? "Submitting..." : "Submit Trip Request")
                        }
                    }
                    .disabled(!isFormValid || viewModel.isLoading)
                }
            }
            .navigationTitle("New Trip")
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .alert("Success", isPresented: .constant(viewModel.submissionSuccess)) {
                Button("OK") {
                    viewModel.clearSuccess()
                    clearForm()
                }
            } message: {
                Text("Your trip request has been submitted successfully!")
            }
        }
    }
    
    private var isFormValid: Bool {
        !destination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        endDate > startDate
    }
    
    private func submitTrip() {
        let submission = TripSubmission(
            destination: destination.trimmingCharacters(in: .whitespacesAndNewlines),
            startDate: startDate,
            endDate: endDate,
            paymentMethod: paymentMethod,
            flexibleDates: flexibleDates
        )
        
        viewModel.submitTrip(submission)
    }
    
    private func clearForm() {
        destination = ""
        startDate = Date()
        endDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        paymentMethod = "Credit Card"
        flexibleDates = false
    }
}

// MARK: - ViewModel
@MainActor
class TripSubmissionViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var submissionSuccess = false
    
    private let tripService = TripService()
    
    func submitTrip(_ submission: TripSubmission) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await tripService.submitTrip(submission)
                submissionSuccess = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    func clearSuccess() {
        submissionSuccess = false
    }
}

#Preview {
    TripSubmissionView()
}
