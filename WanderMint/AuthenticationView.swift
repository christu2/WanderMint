//
//  AuthenticationView.swift
//  WanderMint
//
//  Created by Nick Christus on 6/6/25.
//


import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var name = ""
    @State private var isSignUpMode = false
    @State private var showingResetPassword = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Logo/Header
                VStack(spacing: 10) {
                    Image(systemName: "airplane.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(AppTheme.Colors.primary)
                    
                    Text("WanderMint")
                        .font(AppTheme.Typography.hero)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text("Your personal travel planner")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Form
                VStack(spacing: 16) {
                    if isSignUpMode {
                        TextField("Name", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                    }
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if isSignUpMode {
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Primary Action Button
                    Button(action: primaryAction) {
                        HStack {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            }
                            Text(authViewModel.isLoading ? "Please wait..." : (isSignUpMode ? "Sign Up" : "Sign In"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(!isFormValid || authViewModel.isLoading)
                    
                    // Toggle Mode Button
                    Button(action: {
                        isSignUpMode.toggle()
                        clearForm()
                    }) {
                        Text(isSignUpMode ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .foregroundColor(.blue)
                    }
                    .disabled(authViewModel.isLoading)
                    
                    // Forgot Password (only in sign in mode)
                    if !isSignUpMode {
                        Button("Forgot Password?") {
                            showingResetPassword = true
                        }
                        .foregroundColor(.blue)
                        .font(.footnote)
                        .disabled(authViewModel.isLoading)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Error Message
                if let errorMessage = authViewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $showingResetPassword) {
                ResetPasswordView()
                    .environmentObject(authViewModel)
            }
        }
    }
    
    private var isFormValid: Bool {
        let emailValid = authViewModel.isValidEmail(email)
        let passwordValid = authViewModel.isValidPassword(password)
        let nameValid = !isSignUpMode || !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        if isSignUpMode {
            return emailValid && passwordValid && password == confirmPassword && nameValid
        } else {
            return emailValid && passwordValid
        }
    }
    
    private func primaryAction() {
        authViewModel.clearError()
        
        if isSignUpMode {
            authViewModel.signUp(email: email, password: password, name: name.trimmingCharacters(in: .whitespacesAndNewlines))
        } else {
            authViewModel.signIn(email: email, password: password)
        }
    }
    
    private func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        name = ""
        authViewModel.clearError()
    }
}

struct ResetPasswordView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var email = ""
    @State private var showingSuccessAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Reset Password")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)
                
                Text("Enter your email address and we'll send you a link to reset your password.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .padding(.horizontal)
                
                Button(action: resetPassword) {
                    HStack {
                        if authViewModel.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        }
                        Text(authViewModel.isLoading ? "Sending..." : "Send Reset Link")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(authViewModel.isValidEmail(email) ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(!authViewModel.isValidEmail(email) || authViewModel.isLoading)
                .padding(.horizontal)
                
                if let errorMessage = authViewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert("Reset Link Sent", isPresented: $showingSuccessAlert) {
                Button("OK") {
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Check your email for instructions to reset your password.")
            }
        }
    }
    
    private func resetPassword() {
        authViewModel.resetPassword(email: email)
        
        // Show success alert after a brief delay (simulating the async operation)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if authViewModel.errorMessage == nil {
                showingSuccessAlert = true
            }
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthenticationViewModel())
}