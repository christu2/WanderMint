//
//  TravelConsultingAppApp.swift
//  TravelConsultingApp
//
//  Created by Nick Christus on 3/9/25.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth

class AuthViewModel: ObservableObject {
    @Published var isUserLoggedIn: Bool = false

    init() {
        FirebaseApp.configure()
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.isUserLoggedIn = user != nil
        }
    }
}

@main
struct TravelConsultingApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isUserLoggedIn {
                    MainTabView()
                } else {
                    LoginView(isUserLoggedIn: $authViewModel.isUserLoggedIn)
                }
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            TripSubmissionView()
                .tabItem {
                    Label("Submit Trip", systemImage: "airplane")
                }

            AllTripsStatusView()
                .tabItem {
                    Label("My Trips", systemImage: "list.bullet")
                }
        }
    }
}
