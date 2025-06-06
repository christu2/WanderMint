//
//  TripStatusView.swift
//  TravelConsultingApp
//
//  Created by Nick Christus on 3/15/25.
//

import SwiftUI
import Firebase

struct TripStatusView: View {
    @ObservedObject var viewModel = TripStatusViewModel()
    let tripId: String

    var body: some View {
        VStack {
            if let tripStatus = viewModel.tripStatus {
                Text("Status: \(tripStatus.status)")
                if let recommendation = tripStatus.recommendation {
                    Text("Destination: \(recommendation.destination)")
                    Text("Accommodation: \(recommendation.accommodation)")
                    Text("Transportation: \(recommendation.transportation)")
                    Text("Activities:")
                    ForEach(recommendation.activities, id: \.self) { activity in
                        Text("- \(activity)")
                    }
                }
            } else {
                Text("Loading...")
            }
        }
        .onAppear {
            viewModel.fetchTripStatus(for: tripId)
        }
    }
}

class TripStatusViewModel: ObservableObject {
    @Published var tripStatus: TripStatus?

    func fetchTripStatus(for tripId: String) {
        let db = Firestore.firestore()
        db.collection("trips").document(tripId).addSnapshotListener { (snapshot, error) in
            if let error = error {
                print("Error fetching trip status: \(error)")
                return
            }
            guard let data = snapshot?.data() else { return }
            self.tripStatus = TripStatus(
                id: snapshot!.documentID,
                status: data["status"] as? String ?? "unknown",
                recommendation: data["recommendation"] as? Recommendation
            )
        }
    }
}

struct TripStatus: Identifiable {
    var id: String
    var status: String
    var recommendation: Recommendation?
}

struct Recommendation: Identifiable {
    var id: String
    var destination: String
    var activities: [String]
    var accommodation: String
    var transportation: String
}
