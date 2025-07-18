//
//  AuthenticationViewModel.swift
//  WanderMint
//
//  Created by Nick Christus on 6/6/25.
//


import Foundation
#if canImport(Firebase)
import Firebase
#endif
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var userProfile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var needsOnboarding = false
    
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    private let userService = UserService.shared
    
    init() {
        setupAuthStateListener()
    }
    
    deinit {
        if let handle = authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    private func setupAuthStateListener() {
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            DispatchQueue.main.async {
                self?.currentUser = user
                self?.isAuthenticated = user != nil
                
                // Load user profile when authenticated
                if let user = user {
                    Task {
                        await self?.loadUserProfile()
                        try await self?.userService.updateLastLogin()
                    }
                } else {
                    self?.userProfile = nil
                }
            }
        }
    }
    
    // MARK: - Sign In
    func signIn(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                _ = try await Auth.auth().signIn(withEmail: email, password: password)
            } catch let error as NSError {
                // Provide user-friendly error messages
                if error.domain == "FIRAuthErrorDomain" {
                    switch error.code {
                    case 17008: // FIRAuthErrorCodeInvalidEmail
                        self.errorMessage = "Please enter a valid email address"
                    case 17009: // FIRAuthErrorCodeWrongPassword
                        self.errorMessage = "Incorrect password. Please try again"
                    case 17011: // FIRAuthErrorCodeUserNotFound
                        self.errorMessage = "No account found with this email address"
                    case 17020: // FIRAuthErrorCodeNetworkError
                        self.errorMessage = "Network error. Please check your connection and try again"
                    default:
                        self.errorMessage = error.localizedDescription
                    }
                } else {
                    self.errorMessage = "Connection error. Please check your internet connection and try again"
                }
            }
            self.isLoading = false
        }
    }
    
    // MARK: - Sign Up
    func signUp(email: String, password: String, name: String = "") {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let result = try await Auth.auth().createUser(withEmail: email, password: password)
                
                // Create user profile in Firestore
                try await userService.createUserProfile(for: result.user, name: name)
                
                // Load the created profile
                await loadUserProfile()
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isLoading = false
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Reset Password
    func resetPassword(email: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await Auth.auth().sendPasswordReset(withEmail: email)
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isLoading = false
        }
    }
    
    // MARK: - Helper Methods
    private func loadUserProfile() async {
        do {
            self.userProfile = try await userService.getUserProfile()
            self.needsOnboarding = !(self.userProfile?.onboardingCompleted ?? false)
        } catch {
        }
    }
    
    func updateUserProfile(name: String) async {
        do {
            try await userService.updateUserProfile(name: name)
            await loadUserProfile()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    func completeOnboarding() async {
        do {
            try await userService.completeOnboarding()
            await loadUserProfile()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Validation Helpers
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    func isValidPassword(_ password: String) -> Bool {
        guard password.count >= 8 else { return false }
        
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasDigit = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecialChar = password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
        
        return hasUppercase && hasLowercase && hasDigit && hasSpecialChar
    }
}