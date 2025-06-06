//
//  ContentView.swift
//  TravelConsultingApp
//
//  Created by Nick Christus on 3/9/25.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @State private var isUserLoggedIn = Auth.auth().currentUser != nil

    var body: some View {
        Group {
            if isUserLoggedIn {
                TripSubmissionView()
            } else {
                LoginView(isUserLoggedIn: $isUserLoggedIn)
            }
        }
        .onAppear {
            _ = Auth.auth().addStateDidChangeListener { _, user in
                isUserLoggedIn = user != nil
            }
        }
    }
}

#Preview {
    ContentView()
}
