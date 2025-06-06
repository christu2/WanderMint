//
//  AllTripsStatusView.swift
//  TravelConsultingApp
//
//  Created by Nick Christus on 3/15/25.
//


import SwiftUI
import Firebase
import FirebaseAuth

struct AllTripsStatusView: View {
    @ObservedObject var viewModel = AllTripsStatusViewModel()

    var body: some View {
        NavigationView {
            List(viewModel.trips) { trip in
                NavigationLink(destination: TripStatusView(tripId: trip.id)) {
                    VStack(alignment: .leading) {
                        Text("Destination: \(trip.destination)")
                        Text("Status: \(trip.status)")
                    }
                }
            }
            .navigationTitle("My Trips")
            .onAppear {
                viewModel.fetchAllTrips()
            }
        }
    }
}

class AllTripsStatusViewModel: ObservableObject {
    @Published var trips: [Trip] = []

    func fetchAllTrips() {
        guard let user = Auth.auth().currentUser else {
            print("User not logged in")
            return
        }

        let db = Firestore.firestore()
        db.collection("trips").whereField("userId", isEqualTo: user.uid).addSnapshotListener { (snapshot, error) in
            if let error = error {
                print("Error fetching trips: \(error)")
                return
            }
            self.trips = snapshot?.documents.compactMap { document in
                let data = document.data()
                return Trip(
                    id: document.documentID,
                    destination: data["destination"] as? String ?? "Unknown",
                    status: data["status"] as? String ?? "Unknown"
                )
            } ?? []
        }
    }
}

struct Trip: Identifiable {
    var id: String
    var destination: String
    var status: String
}

struct AllTripsStatusView_Previews: PreviewProvider {
    static var previews: some View {
        AllTripsStatusView()
    }
}
