//
//  UserService.swift
//  WanderMint
//
//  Created by Claude Code on 7/6/25.
//

import Foundation
#if canImport(Firebase)
import Firebase
#endif
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

@MainActor
class UserService: ObservableObject {
    static let shared = UserService()
    #if canImport(FirebaseFirestore)
    private let db = Firestore.firestore()
    #endif
    
    private init() {}
    
    func createUserProfile(for user: User, name: String = "") async throws {
        #if canImport(FirebaseFirestore) && canImport(FirebaseAuth)
        let userData: [String: Any] = [
            "userId": user.uid,
            "name": name.isEmpty ? (user.displayName ?? "") : name,
            "email": user.email ?? "",
            "createdAt": FieldValue.serverTimestamp(),
            "lastLoginAt": FieldValue.serverTimestamp(),
            "onboardingCompleted": false
        ]
        
        try await db.collection("users").document(user.uid).setData(userData)
        #else
        throw TravelAppError.authenticationFailed
        #endif
    }
    
    func getUserProfile() async throws -> UserProfile? {
        #if canImport(FirebaseFirestore) && canImport(FirebaseAuth)
        guard let user = Auth.auth().currentUser else {
            throw TravelAppError.authenticationFailed
        }
        
        do {
            let document = try await db.collection("users").document(user.uid).getDocument()
            
            guard let data = document.data() else {
                return nil
            }
            
            return try parseUserProfile(from: data, userId: user.uid)
        } catch {
            throw TravelAppError.dataError(error.localizedDescription)
        }
        #else
        return nil
        #endif
    }
    
    func updateUserProfile(name: String) async throws {
        #if canImport(FirebaseFirestore) && canImport(FirebaseAuth)
        guard let user = Auth.auth().currentUser else {
            throw TravelAppError.authenticationFailed
        }
        
        let updateData: [String: Any] = [
            "name": name,
            "lastLoginAt": FieldValue.serverTimestamp()
        ]
        
        do {
            try await db.collection("users").document(user.uid).updateData(updateData)
        } catch {
            throw TravelAppError.dataError(error.localizedDescription)
        }
        #else
        throw TravelAppError.authenticationFailed
        #endif
    }
    
    func updateLastLogin() async throws {
        #if canImport(FirebaseFirestore) && canImport(FirebaseAuth)
        guard let user = Auth.auth().currentUser else {
            throw TravelAppError.authenticationFailed
        }
        
        let updateData: [String: Any] = [
            "lastLoginAt": FieldValue.serverTimestamp()
        ]
        
        do {
            try await db.collection("users").document(user.uid).setData(updateData, merge: true)
        } catch {
            // Don't throw error for last login update failures
        }
        #else
        throw TravelAppError.authenticationFailed
        #endif
    }
    
    func completeOnboarding() async throws {
        #if canImport(FirebaseFirestore) && canImport(FirebaseAuth)
        guard let user = Auth.auth().currentUser else {
            throw TravelAppError.authenticationFailed
        }
        
        let updateData: [String: Any] = [
            "onboardingCompleted": true,
            "onboardingCompletedAt": FieldValue.serverTimestamp()
        ]
        
        do {
            try await db.collection("users").document(user.uid).updateData(updateData)
        } catch {
            throw TravelAppError.dataError(error.localizedDescription)
        }
        #else
        throw TravelAppError.authenticationFailed
        #endif
    }
    
    private func parseUserProfile(from data: [String: Any], userId: String) throws -> UserProfile {
        let name = data["name"] as? String ?? ""
        let email = data["email"] as? String ?? ""
        let createdAt = data["createdAt"] as? AppTimestamp ?? createTimestamp()
        let lastLoginAt = data["lastLoginAt"] as? AppTimestamp ?? createTimestamp()
        let profilePictureUrl = data["profilePictureUrl"] as? String
        let onboardingCompleted = data["onboardingCompleted"] as? Bool ?? false
        let onboardingCompletedAt = data["onboardingCompletedAt"] as? AppTimestamp
        
        return UserProfile(
            userId: userId,
            name: name,
            email: email,
            createdAt: createdAt,
            lastLoginAt: lastLoginAt,
            profilePictureUrl: profilePictureUrl,
            onboardingCompleted: onboardingCompleted,
            onboardingCompletedAt: onboardingCompletedAt
        )
    }
}