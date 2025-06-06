//
//  TripService.swift
//  TravelConsultingApp
//
//  Created by Nick Christus on 6/6/25.
//


import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions

@MainActor
class TripService: ObservableObject {
    private let db = Firestore.firestore()
    private let functions = Functions.functions()
    
    // MARK: - Submit Trip
    func submitTrip(_ submission: TripSubmission) async throws {
        guard let user = Auth.auth().currentUser else {
            throw TravelAppError.authenticationFailed
        }
        
        let data: [String: Any] = [
            "destination": submission.destination,
            "startDate": Timestamp(date: submission.startDate),
            "endDate": Timestamp(date: submission.endDate),
            "paymentMethod": submission.paymentMethod,
            "flexibleDates": submission.flexibleDates
        ]
        
        do {
            let result = try await functions.httpsCallable("submitTrip").call(data)
            print("Trip submitted successfully: \(result)")
        } catch {
            print("Error submitting trip: \(error)")
            throw TravelAppError.submissionFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Fetch User Trips
    func fetchUserTrips() async throws -> [Trip] {
        guard let user = Auth.auth().currentUser else {
            throw TravelAppError.authenticationFailed
        }
        
        do {
            let snapshot = try await db.collection("trips")
                .whereField("userId", isEqualTo: user.uid)
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            let trips = try snapshot.documents.compactMap { document -> Trip? in
                var data = document.data()
                data["id"] = document.documentID
                
                return try self.parseTrip(from: data)
            }
            
            return trips
        } catch {
            print("Error fetching trips: \(error)")
            throw TravelAppError.dataError(error.localizedDescription)
        }
    }
    
    // MARK: - Fetch Single Trip
    func fetchTrip(tripId: String) async throws -> Trip? {
        guard Auth.auth().currentUser != nil else {
            throw TravelAppError.authenticationFailed
        }
        
        do {
            let document = try await db.collection("trips").document(tripId).getDocument()
            
            guard let data = document.data() else {
                return nil
            }
            
            var tripData = data
            tripData["id"] = document.documentID
            
            return try parseTrip(from: tripData)
        } catch {
            print("Error fetching trip: \(error)")
            throw TravelAppError.dataError(error.localizedDescription)
        }
    }
    
    // MARK: - Listen to Trip Updates
    func listenToTrip(tripId: String, completion: @escaping (Result<Trip?, Error>) -> Void) -> ListenerRegistration {
        return db.collection("trips").document(tripId).addSnapshotListener { document, error in
            if let error = error {
                completion(.failure(TravelAppError.dataError(error.localizedDescription)))
                return
            }
            
            guard let document = document, let data = document.data() else {
                completion(.success(nil))
                return
            }
            
            var tripData = data
            tripData["id"] = document.documentID
            
            do {
                let trip = try self.parseTrip(from: tripData)
                completion(.success(trip))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Helper Methods
    private func parseTrip(from data: [String: Any]) throws -> Trip {
        guard let id = data["id"] as? String,
              let userId = data["userId"] as? String,
              let destination = data["destination"] as? String,
              let startDate = data["startDate"] as? Timestamp,
              let endDate = data["endDate"] as? Timestamp,
              let paymentMethod = data["paymentMethod"] as? String,
              let flexibleDates = data["flexibleDates"] as? Bool,
              let statusString = data["status"] as? String,
              let status = TripStatusType(rawValue: statusString),
              let createdAt = data["createdAt"] as? Timestamp else {
            throw TravelAppError.dataError("Invalid trip data structure")
        }
        
        let updatedAt = data["updatedAt"] as? Timestamp
        
        // Parse recommendation if it exists
        let recommendation: Recommendation?
        if let recData = data["recommendation"] as? [String: Any] {
            recommendation = try parseRecommendation(from: recData)
        } else {
            recommendation = nil
        }
        
        return Trip(
            id: id,
            userId: userId,
            destination: destination,
            startDate: startDate,
            endDate: endDate,
            paymentMethod: paymentMethod,
            flexibleDates: flexibleDates,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
            recommendation: recommendation
        )
    }
    
    private func parseRecommendation(from data: [String: Any]) throws -> Recommendation {
        guard let id = data["id"] as? String,
              let destination = data["destination"] as? String,
              let overview = data["overview"] as? String,
              let bestTimeToVisit = data["bestTimeToVisit"] as? String,
              let tips = data["tips"] as? [String],
              let createdAt = data["createdAt"] as? Timestamp else {
            throw TravelAppError.dataError("Invalid recommendation data structure")
        }
        
        // Parse activities
        let activities: [Activity]
        if let activitiesData = data["activities"] as? [[String: Any]] {
            activities = try activitiesData.compactMap { activityData in
                try parseActivity(from: activityData)
            }
        } else {
            activities = []
        }
        
        // Parse accommodations
        let accommodations: [Accommodation]
        if let accommodationsData = data["accommodations"] as? [[String: Any]] {
            accommodations = try accommodationsData.compactMap { accommodationData in
                try parseAccommodation(from: accommodationData)
            }
        } else {
            accommodations = []
        }
        
        // Parse transportation
        let transportation: TransportationInfo
        if let transportationData = data["transportation"] as? [String: Any] {
            transportation = try parseTransportation(from: transportationData)
        } else {
            // Default transportation info
            transportation = TransportationInfo(
                flightInfo: nil,
                localTransport: [],
                estimatedFlightCost: 0,
                localTransportCost: 0
            )
        }
        
        // Parse cost breakdown
        let estimatedCost: CostBreakdown
        if let costData = data["estimatedCost"] as? [String: Any] {
            estimatedCost = try parseCostBreakdown(from: costData)
        } else {
            // Default cost breakdown
            estimatedCost = CostBreakdown(
                totalEstimate: 0,
                flights: 0,
                accommodation: 0,
                activities: 0,
                food: 0,
                localTransport: 0,
                miscellaneous: 0,
                currency: "USD"
            )
        }
        
        return Recommendation(
            id: id,
            destination: destination,
            overview: overview,
            activities: activities,
            accommodations: accommodations,
            transportation: transportation,
            estimatedCost: estimatedCost,
            bestTimeToVisit: bestTimeToVisit,
            tips: tips,
            createdAt: createdAt
        )
    }
    
    private func parseActivity(from data: [String: Any]) throws -> Activity {
        guard let id = data["id"] as? String,
              let name = data["name"] as? String,
              let description = data["description"] as? String,
              let category = data["category"] as? String,
              let estimatedDuration = data["estimatedDuration"] as? String,
              let estimatedCost = data["estimatedCost"] as? Double,
              let priority = data["priority"] as? Int else {
            throw TravelAppError.dataError("Invalid activity data structure")
        }
        
        return Activity(
            id: id,
            name: name,
            description: description,
            category: category,
            estimatedDuration: estimatedDuration,
            estimatedCost: estimatedCost,
            priority: priority
        )
    }
    
    private func parseAccommodation(from data: [String: Any]) throws -> Accommodation {
        guard let id = data["id"] as? String,
              let name = data["name"] as? String,
              let type = data["type"] as? String,
              let description = data["description"] as? String,
              let priceRange = data["priceRange"] as? String,
              let rating = data["rating"] as? Double,
              let amenities = data["amenities"] as? [String] else {
            throw TravelAppError.dataError("Invalid accommodation data structure")
        }
        
        return Accommodation(
            id: id,
            name: name,
            type: type,
            description: description,
            priceRange: priceRange,
            rating: rating,
            amenities: amenities
        )
    }
    
    private func parseTransportation(from data: [String: Any]) throws -> TransportationInfo {
        let estimatedFlightCost = data["estimatedFlightCost"] as? Double ?? 0
        let localTransportCost = data["localTransportCost"] as? Double ?? 0
        let localTransport = data["localTransport"] as? [String] ?? []
        
        let flightInfo: FlightInfo?
        if let flightData = data["flightInfo"] as? [String: Any] {
            flightInfo = try parseFlightInfo(from: flightData)
        } else {
            flightInfo = nil
        }
        
        return TransportationInfo(
            flightInfo: flightInfo,
            localTransport: localTransport,
            estimatedFlightCost: estimatedFlightCost,
            localTransportCost: localTransportCost
        )
    }
    
    private func parseFlightInfo(from data: [String: Any]) throws -> FlightInfo {
        guard let recommendedAirlines = data["recommendedAirlines"] as? [String],
              let estimatedFlightTime = data["estimatedFlightTime"] as? String,
              let bestBookingTime = data["bestBookingTime"] as? String else {
            throw TravelAppError.dataError("Invalid flight info data structure")
        }
        
        return FlightInfo(
            recommendedAirlines: recommendedAirlines,
            estimatedFlightTime: estimatedFlightTime,
            bestBookingTime: bestBookingTime
        )
    }
    
    private func parseCostBreakdown(from data: [String: Any]) throws -> CostBreakdown {
        guard let totalEstimate = data["totalEstimate"] as? Double,
              let flights = data["flights"] as? Double,
              let accommodation = data["accommodation"] as? Double,
              let activities = data["activities"] as? Double,
              let food = data["food"] as? Double,
              let localTransport = data["localTransport"] as? Double,
              let miscellaneous = data["miscellaneous"] as? Double,
              let currency = data["currency"] as? String else {
            throw TravelAppError.dataError("Invalid cost breakdown data structure")
        }
        
        return CostBreakdown(
            totalEstimate: totalEstimate,
            flights: flights,
            accommodation: accommodation,
            activities: activities,
            food: food,
            localTransport: localTransport,
            miscellaneous: miscellaneous,
            currency: currency
        )
    }
}