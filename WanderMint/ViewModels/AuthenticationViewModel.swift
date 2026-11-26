//
//  AuthenticationViewModel.swift
//  WanderMint
//
//  Created by Nick Christus on 6/6/25.
//


import Foundation
import AuthenticationServices
import CryptoKit
import Security
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
    private var currentAppleSignInNonce: String?
    
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
                if user != nil {
                    Task {
                        await self?.loadUserProfile()
                        try? await self?.userService.updateLastLogin()
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
                    case 17004, 17009, 17011: // Invalid credential, wrong password, or user not found (uniform message prevents account enumeration)
                        self.errorMessage = "Invalid email or password. Please try again"
                    case 17010: // FIRAuthErrorCodeTooManyRequests
                        self.errorMessage = "Too many attempts. Please wait a moment and try again"
                    case 17020: // FIRAuthErrorCodeNetworkError
                        self.errorMessage = "Network error. Please check your connection and try again"
                    default:
                        self.errorMessage = "Unable to sign in. Please check your credentials and try again"
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
        Task {
            await NotificationService.shared.removeFCMTokenOnSignOut()
            do {
                try Auth.auth().signOut()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - Sign in with Apple
    
    /// Configures an Apple ID authorization request with requested scopes and a SHA-256 hashed cryptographic nonce.
    func prepareAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        clearError()
        let nonce = Self.randomNonceString()
        currentAppleSignInNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)
    }
    
    /// Handles the Sign in with Apple authorization callback and authenticates with Firebase Auth.
    func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .failure(let error):
            if let authError = error as? ASAuthorizationError, authError.code == .canceled {
                // User dismissed the Apple Sign-In sheet intentionally — do not display an error banner
                return
            }
            self.errorMessage = "Apple Sign In failed. Please try again."
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let nonce = currentAppleSignInNonce,
                  let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                self.errorMessage = "Unable to verify Apple ID credentials. Please try again."
                return
            }
            
            currentAppleSignInNonce = nil
            isLoading = true
            errorMessage = nil
            
            let fullName = [
                appleIDCredential.fullName?.givenName,
                appleIDCredential.fullName?.familyName
            ]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            
            Task {
                defer { self.isLoading = false }
                do {
                    #if canImport(FirebaseAuth)
                    let credential = OAuthProvider.appleCredential(
                        withIDToken: idTokenString,
                        rawNonce: nonce,
                        fullName: appleIDCredential.fullName
                    )
                    let authResult = try await Auth.auth().signIn(with: credential)
                    
                    // Create Firestore user profile on first Sign in with Apple (Apple only sends name once)
                    let existingProfile = try? await userService.getUserProfile()
                    if existingProfile == nil {
                        try await userService.createUserProfile(for: authResult.user, name: fullName)
                    } else if !fullName.isEmpty, (existingProfile?.name.isEmpty ?? true) {
                        try? await userService.updateUserProfile(name: fullName)
                    }
                    await loadUserProfile()
                    #endif
                } catch {
                    self.errorMessage = "Unable to sign in with Apple. Please try again."
                }
            }
        }
    }
    
    /// Generates a cryptographically secure random alphanumeric nonce string for OIDC/Apple Sign-In.
    nonisolated static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            if status != errSecSuccess {
                fatalError("Unable to generate secure nonce. SecRandomCopyBytes failed with OSStatus \(status)")
            }
            for random in randoms {
                if remainingLength == 0 { break }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }
    
    /// Returns the lowercase SHA-256 hex digest of the input string.
    nonisolated static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Reset Password
    func resetPassword(email: String) {
        Task {
            _ = await resetPasswordAsync(email: email)
        }
    }
    
    @discardableResult
    func resetPasswordAsync(email: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }
    }
    
    // MARK: - Delete Account (App Store Guideline 5.1.1(v))
    @discardableResult
    func deleteAccount() async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await userService.deleteAccount()
            self.userProfile = nil
            self.currentUser = nil
            self.isAuthenticated = false
            self.needsOnboarding = false
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            return false
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