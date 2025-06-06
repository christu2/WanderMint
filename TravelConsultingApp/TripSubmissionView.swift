import SwiftUI
import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct TripSubmissionView: View {
    @State private var destination: String = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var paymentMethod: String = "Cash"
    @State private var flexibleDates: Bool = false
    @State private var earliestStartDate = Date()
    @State private var latestEndDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
    @State private var minTripLength: Int = 1
    @State private var maxTripLength: Int = 14
    @State private var tripId: String? = nil

    let paymentOptions = ["Cash", "Points"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Trip Details")) {
                    TextField("Destination", text: $destination)
                    Toggle("Flexible Dates", isOn: $flexibleDates)

                    if flexibleDates {
                        DatePicker("Earliest Start Date", selection: $earliestStartDate, in: Date()..., displayedComponents: .date)
                        DatePicker("Latest End Date", selection: $latestEndDate, in: earliestStartDate..., displayedComponents: .date)
                        Stepper("Min Trip Length: \(minTripLength) days", value: $minTripLength, in: 1...maxTripLength)
                        Stepper("Max Trip Length: \(maxTripLength) days", value: $maxTripLength, in: minTripLength...30)
                    } else {
                        DatePicker("Start Date", selection: $startDate, in: Date()..., displayedComponents: .date)
                        DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                    }

                    Picker("Payment Method", selection: $paymentMethod) {
                        ForEach(paymentOptions, id: \.self) { option in
                            Text(option)
                        }
                    }
                }

                Section {
                    Button(action: submitTrip) {
                        Text("Submit Trip")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }

                if let tripId = tripId {
                    NavigationLink(destination: TripStatusView(tripId: tripId), isActive: .constant(true)) {
                        EmptyView()
                    }
                }
            }
            .navigationTitle("Plan Your Trip")
        }
    }

    func submitTrip() {
        guard let user = Auth.auth().currentUser else {
            print("User not logged in")
            return
        }

        let db = Firestore.firestore()
        let userSubmissionsRef = db.collection("userSubmissions").document(user.uid)
        let today = Calendar.current.startOfDay(for: Date())

        userSubmissionsRef.getDocument { document, error in
            if let error = error {
                print("Error fetching submission record: \(error)")
                return
            }

            if let document = document, document.exists {
                let data = document.data()
                let lastSubmissionDate = (data?["lastSubmissionDate"] as? Timestamp)?.dateValue() ?? Date.distantPast
                let submissionCount = data?["submissionCount"] as? Int ?? 0

                if Calendar.current.isDate(lastSubmissionDate, inSameDayAs: today) && submissionCount >= 10 {
                    print("Submission limit reached for today")
                    return
                }

                // Proceed with submission
                processTripSubmission(user: user, userSubmissionsRef: userSubmissionsRef, submissionCount: submissionCount, lastSubmissionDate: lastSubmissionDate)
            } else {
                // No submission record found, proceed with submission
                processTripSubmission(user: user, userSubmissionsRef: userSubmissionsRef, submissionCount: 0, lastSubmissionDate: Date.distantPast)
            }
        }
    }

    func processTripSubmission(user: User, userSubmissionsRef: DocumentReference, submissionCount: Int, lastSubmissionDate: Date) {
        user.getIDToken { idToken, error in
            if let error = error {
                print("Error getting ID token: \(error)")
                return
            }

            guard let idToken = idToken else {
                print("ID token is nil")
                return
            }

            let url = URL(string: "https://us-central1-travel-consulting-app-1.cloudfunctions.net/submitTrip")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone.current

            var tripDetails: [String: Any] = [
                "destination": destination,
                "paymentMethod": paymentMethod,
                "flexibleDates": flexibleDates
            ]

            if flexibleDates {
                tripDetails["earliestStartDate"] = dateFormatter.string(from: earliestStartDate)
                tripDetails["latestEndDate"] = dateFormatter.string(from: latestEndDate)
                tripDetails["minTripLength"] = minTripLength
                tripDetails["maxTripLength"] = maxTripLength
            } else {
                tripDetails["startDate"] = dateFormatter.string(from: startDate)
                tripDetails["endDate"] = dateFormatter.string(from: endDate)
            }

            request.httpBody = try? JSONSerialization.data(withJSONObject: tripDetails)

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error submitting trip: \(error)")
                    return
                }

                // Update submission record
                let newSubmissionCount = Calendar.current.isDate(lastSubmissionDate, inSameDayAs: Date()) ? submissionCount + 1 : 1
                userSubmissionsRef.setData([
                    "lastSubmissionDate": Timestamp(date: Date()),
                    "submissionCount": newSubmissionCount
                ]) { error in
                    if let error = error {
                        print("Error updating submission record: \(error)")
                    } else {
                        print("Trip submitted successfully")
                        // Assuming the response contains the tripId
                        if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let tripId = json["tripId"] as? String {
                            DispatchQueue.main.async {
                                self.tripId = tripId
                            }
                        }
                    }
                }
            }

            task.resume()
        }
    }
}

struct TripSubmissionView_Previews: PreviewProvider {
    static var previews: some View {
        TripSubmissionView()
    }
}
