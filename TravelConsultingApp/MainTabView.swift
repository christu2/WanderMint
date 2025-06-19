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
    @State private var showingPointsView = false
    
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
                
                // Points Management Button
                PrimaryButton(
                    title: "Manage Points & Miles",
                    icon: "creditcard",
                    isLoading: false,
                    isEnabled: true
                ) {
                    showingPointsView = true
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button("Sign Out") {
                    authViewModel.signOut()
                }
                .foregroundColor(.red)
                .frame(minHeight: 44) // Better touch target
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
            .padding()
            .navigationTitle("Profile")
            .sheet(isPresented: $showingPointsView) {
                PointsManagementView()
            }
        }
    }
}
