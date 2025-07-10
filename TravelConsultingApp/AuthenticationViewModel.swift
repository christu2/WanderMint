//
//  AuthenticationViewModel.swift
//  TravelConsultingApp
//
//  Created by Nick Christus on 6/6/25.
//


import Foundation
import Firebase
import FirebaseAuth

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        setupAuthStateListener()
    }
    
    deinit {
        if let handle = authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    private func setupAuthStateListener() {
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.currentUser = user
                self?.isAuthenticated = user != nil
            }
        }
    }
    
    // MARK: - Sign In
    func signIn(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let result = try await Auth.auth().signIn(withEmail: email, password: password)
                print("User signed in: \(result.user.uid)")
            } catch {
                self.errorMessage = error.localizedDescription
                print("Sign in error: \(error)")
            }
            self.isLoading = false
        }
    }
    
    // MARK: - Sign Up
    func signUp(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let result = try await Auth.auth().createUser(withEmail: email, password: password)
                print("User created: \(result.user.uid)")
                
                // Optionally create user profile in Firestore
                try await createUserProfile(for: result.user)
            } catch {
                self.errorMessage = error.localizedDescription
                print("Sign up error: \(error)")
            }
            self.isLoading = false
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
            print("User signed out")
        } catch {
            errorMessage = error.localizedDescription
            print("Sign out error: \(error)")
        }
    }
    
    // MARK: - Reset Password
    func resetPassword(email: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await Auth.auth().sendPasswordReset(withEmail: email)
                print("Password reset email sent")
            } catch {
                self.errorMessage = error.localizedDescription
                print("Password reset error: \(error)")
            }
            self.isLoading = false
        }
    }
    
    // MARK: - Helper Methods
    private func createUserProfile(for user: User) async throws {
        let db = Firestore.firestore()
        let userData: [String: Any] = [
            "email": user.email ?? "",
            "createdAt": Timestamp(),
            "lastLoginAt": Timestamp()
        ]
        
        try await db.collection("users").document(user.uid).setData(userData)
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Validation Helpers
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    func isValidPassword(_ password: String) -> Bool {
        return password.count >= 6
    }
}