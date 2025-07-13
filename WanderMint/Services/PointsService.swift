//
//  PointsService.swift
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
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

@MainActor
class PointsService: ObservableObject {
    #if canImport(FirebaseFirestore)
    private let db = Firestore.firestore()
    #endif
    
    func getUserPointsProfile() async throws -> UserPointsProfile? {
        #if canImport(FirebaseFirestore) && canImport(FirebaseAuth)
        guard let user = Auth.auth().currentUser else {
            throw TravelAppError.authenticationFailed
        }
        
        do {
            let document = try await db.collection("userPoints").document(user.uid).getDocument()
            
            guard let data = document.data() else {
                return nil
            }
            
            return try parsePointsProfile(from: data, userId: user.uid)
        } catch {
            throw TravelAppError.dataError(error.localizedDescription)
        }
        #else
        return nil
        #endif
    }
    
    func updatePoints(provider: String, type: PointsType, amount: Int) async throws {
        #if canImport(FirebaseFirestore) && canImport(FirebaseAuth)
        guard let user = Auth.auth().currentUser else {
            throw TravelAppError.authenticationFailed
        }
        
        let docRef = db.collection("userPoints").document(user.uid)
        
        do {
            // Check if document exists
            let document = try await docRef.getDocument()
            
            if document.exists {
                // Update existing document
                let fieldPath = "\(type.rawValue)Points.\(provider)"
                try await docRef.updateData([
                    fieldPath: amount,
                    "lastUpdated": FieldValue.serverTimestamp()
                ])
            } else {
                // Create new document
                var pointsData: [String: Any] = [
                    "userId": user.uid,
                    "creditCardPoints": [:],
                    "hotelPoints": [:],
                    "airlinePoints": [:],
                    "lastUpdated": FieldValue.serverTimestamp()
                ]
                
                let fieldPath = "\(type.rawValue)Points"
                pointsData[fieldPath] = [provider: amount]
                
                try await docRef.setData(pointsData)
            }
        } catch {
            throw TravelAppError.dataError(error.localizedDescription)
        }
        #else
        throw TravelAppError.authenticationFailed
        #endif
    }
    
    func removePoints(provider: String, type: PointsType) async throws {
        #if canImport(FirebaseFirestore) && canImport(FirebaseAuth)
        guard let user = Auth.auth().currentUser else {
            throw TravelAppError.authenticationFailed
        }
        
        let docRef = db.collection("userPoints").document(user.uid)
        let fieldPath = "\(type.rawValue)Points.\(provider)"
        
        do {
            try await docRef.updateData([
                fieldPath: FieldValue.delete(),
                "lastUpdated": FieldValue.serverTimestamp()
            ])
        } catch {
            throw TravelAppError.dataError(error.localizedDescription)
        }
        #else
        throw TravelAppError.authenticationFailed
        #endif
    }
    
    private func parsePointsProfile(from data: [String: Any], userId: String) throws -> UserPointsProfile {
        #if canImport(FirebaseFirestore) && canImport(FirebaseAuth)
        let creditCardPoints = data["creditCardPoints"] as? [String: Int] ?? [:]
        let hotelPoints = data["hotelPoints"] as? [String: Int] ?? [:]
        let airlinePoints = data["airlinePoints"] as? [String: Int] ?? [:]
        let lastUpdated = data["lastUpdated"] as? AppTimestamp ?? createTimestamp()
        
        return UserPointsProfile(
            userId: userId,
            creditCardPoints: creditCardPoints,
            hotelPoints: hotelPoints,
            airlinePoints: airlinePoints,
            lastUpdated: lastUpdated
        )
        #else
        throw TravelAppError.authenticationFailed
        #endif
    }
}