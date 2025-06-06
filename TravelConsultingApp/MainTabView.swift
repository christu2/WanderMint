//
//  MainTabView.swift
//  TravelConsultingApp
//
//  Created by Nick Christus on 6/6/25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        TabView {
            TripSubmissionView()
                .tabItem {
                    Image(systemName: "plus.circle")
                    Text("New Trip")
                }
            
            TripsListView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("My Trips")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profile")
                }
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Profile")
                    .font(.largeTitle)
                    .bold()
                
                if let user = authViewModel.currentUser {
                    Text("Email: \(user.email ?? "No email")")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Sign Out") {
                    authViewModel.signOut()
                }
                .foregroundColor(.red)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
            .padding()
            .navigationTitle("Profile")
        }
    }
}
