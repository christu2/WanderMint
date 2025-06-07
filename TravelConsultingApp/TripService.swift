import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore

@MainActor
class TripService: ObservableObject {
    private let db = Firestore.firestore()
    
    // MARK: - Submit Enhanced Trip
    func submitEnhancedTrip(_ submission: EnhancedTripSubmission) async throws {
        print("🔐 Checking authentication...")
        guard let user = Auth.auth().currentUser else {
            print("❌ No current user found")
            throw TravelAppError.authenticationFailed
        }
        
        print("✅ User found: \(user.uid)")
        print("📧 User email: \(user.email ?? "No email")")
        
        // Get ID token for authentication
        print("🔑 Getting ID token...")
        let idToken: String
        do {
            idToken = try await user.getIDToken()
            print("✅ Got ID token (length: \(idToken.count))")
        } catch {
            print("❌ Failed to get ID token: \(error)")
            throw TravelAppError.authenticationFailed
        }
        
        // Format dates for the backend - use ISO 8601 format
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var requestData: [String: Any] = [
            "destination": submission.destination,
            "startDate": dateFormatter.string(from: submission.startDate),
            "endDate": dateFormatter.string(from: submission.endDate),
            "paymentMethod": submission.paymentMethod,
            "flexibleDates": submission.flexibleDates,
            "budget": submission.budget ?? "",
            "travelStyle": submission.travelStyle,
            "groupSize": submission.groupSize,
            "specialRequests": submission.specialRequests,
            "interests": submission.interests
        ]
        
        // Add trip duration for flexible dates
        if let duration = submission.tripDuration {
            requestData["tripDuration"] = duration
        }
        
        print("Submitting enhanced trip data: \(requestData)")
        
        // Create the HTTP request - V2 function will have Cloud Run URL
        // You'll need to get the actual URL after deployment
        guard let url = URL(string: "https://submittrip-z7ztkcre7q-uc.a.run.app") else {
            throw TravelAppError.networkError("Invalid URL")
        }
        
        print("Making request to: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        
        // Add debugging headers
        print("Request headers: \(request.allHTTPHeaderFields ?? [:])")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestData)
        } catch {
            throw TravelAppError.dataError("Failed to encode request data")
        }
        
        // Make the network call
        do {
            print("Sending HTTP request...")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            print("Response received: \(response)")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TravelAppError.networkError("Invalid response")
            }
            
            print("HTTP Status Code: \(httpResponse.statusCode)")
            let responseString = String(data: data, encoding: .utf8) ?? "No response data"
            print("Response body: \(responseString)")
            
            if httpResponse.statusCode == 200 {
                print("Enhanced trip submitted successfully")
                return
            } else if httpResponse.statusCode == 400 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Bad Request"
                print("Bad Request Error: \(errorMessage)")
                throw TravelAppError.submissionFailed("Invalid request: \(errorMessage)")
            } else if httpResponse.statusCode == 401 {
                print("❌ 401 Unauthorized - Token might be invalid")
                throw TravelAppError.authenticationFailed
            } else if httpResponse.statusCode == 403 {
                print("❌ 403 Forbidden - Token valid but access denied")
                throw TravelAppError.authenticationFailed
            } else if httpResponse.statusCode == 429 {
                throw TravelAppError.submissionFailed("Daily submission limit reached")
            } else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw TravelAppError.submissionFailed(errorMessage)
            }
        } catch {
            if error is TravelAppError {
                throw error
            } else {
                throw TravelAppError.networkError(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Submit Trip (Legacy)
    func submitTrip(_ submission: TripSubmission) async throws {
        guard let user = Auth.auth().currentUser else {
            throw TravelAppError.authenticationFailed
        }
        
        // Get ID token for authentication
        let idToken = try await user.getIDToken()
        
        // Format dates for the backend - use ISO 8601 format
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var requestData: [String: Any] = [
            "destination": submission.destination,
            "startDate": dateFormatter.string(from: submission.startDate),
            "endDate": dateFormatter.string(from: submission.endDate),
            "paymentMethod": submission.paymentMethod,
            "flexibleDates": submission.flexibleDates
        ]
        
        print("Submitting trip data: \(requestData)")
        
        // Create the HTTP request - use v1 function URL
        guard let url = URL(string: "https://us-central1-travel-consulting-app-1.cloudfunctions.net/submitTrip") else {
            throw TravelAppError.networkError("Invalid URL")
        }
        
        print("Making request to: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        
        // Add debugging headers
        print("Request headers: \(request.allHTTPHeaderFields ?? [:])")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestData)
        } catch {
            throw TravelAppError.dataError("Failed to encode request data")
        }
        
        // Make the network call
        do {
            print("Sending HTTP request...")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            print("Response received: \(response)")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TravelAppError.networkError("Invalid response")
            }
            
            print("HTTP Status Code: \(httpResponse.statusCode)")
            let responseString = String(data: data, encoding: .utf8) ?? "No response data"
            print("Response body: \(responseString)")
            
            if httpResponse.statusCode == 200 {
                print("Trip submitted successfully")
                return
            } else if httpResponse.statusCode == 400 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Bad Request"
                print("Bad Request Error: \(errorMessage)")
                throw TravelAppError.submissionFailed("Invalid request: \(errorMessage)")
            } else if httpResponse.statusCode == 401 {
                print("❌ 401 Unauthorized - Token might be invalid")
                throw TravelAppError.authenticationFailed
            } else if httpResponse.statusCode == 403 {
                print("❌ 403 Forbidden - Token valid but access denied")
                throw TravelAppError.authenticationFailed
            } else if httpResponse.statusCode == 429 {
                throw TravelAppError.submissionFailed("Daily submission limit reached")
            } else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw TravelAppError.submissionFailed(errorMessage)
            }
        } catch {
            if error is TravelAppError {
                throw error
            } else {
                throw TravelAppError.networkError(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Fetch User Trips
    func fetchUserTrips() async throws -> [TravelTrip] {
        guard let user = Auth.auth().currentUser else {
            throw TravelAppError.authenticationFailed
        }
        
        do {
            let snapshot = try await db.collection("trips")
                .whereField("userId", isEqualTo: user.uid)
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            print("Fetched \(snapshot.documents.count) trip documents")
            
            let trips = try snapshot.documents.compactMap { document -> TravelTrip? in
                var data = document.data()
                data["id"] = document.documentID
                
                print("Processing document \(document.documentID) with data keys: \(data.keys.sorted())")
                
                do {
                    return try self.parseTrip(from: data)
                } catch {
                    print("Failed to parse trip \(document.documentID): \(error)")
                    return nil // Skip invalid trips instead of failing everything
                }
            }
            
            print("Successfully parsed \(trips.count) trips")
            return trips
            
        } catch {
            print("Error fetching trips: \(error)")
            throw TravelAppError.dataError(error.localizedDescription)
        }
    }
    
    // MARK: - Fetch Single Trip
    func fetchTrip(tripId: String) async throws -> TravelTrip? {
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
    func listenToTrip(tripId: String, completion: @escaping (Result<TravelTrip?, Error>) -> Void) -> ListenerRegistration {
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
    private func parseTrip(from data: [String: Any]) throws -> TravelTrip {
        // Debug: Print the raw data structure
        print("Parsing trip data: \(data)")
        
        guard let id = data["id"] as? String else {
            throw TravelAppError.dataError("Missing trip ID")
        }
        
        guard let userId = data["userId"] as? String else {
            throw TravelAppError.dataError("Missing user ID")
        }
        
        guard let destination = data["destination"] as? String else {
            throw TravelAppError.dataError("Missing destination")
        }
        
        guard let paymentMethod = data["paymentMethod"] as? String else {
            throw TravelAppError.dataError("Missing payment method")
        }
        
        let flexibleDates = data["flexibleDates"] as? Bool ?? false
        
        // Parse status with fallback and backwards compatibility
        let statusString = data["status"] as? String ?? "pending"
        var status: TripStatusType
        
        // Handle backwards compatibility with old status values
        switch statusString {
        case "submitted":
            status = .pending  // Convert old 'submitted' to new 'pending'
        case "processing":
            status = .inProgress  // Convert old 'processing' to new 'inProgress'
        case "failed":
            status = .cancelled  // Convert old 'failed' to new 'cancelled'
        default:
            status = TripStatusType(rawValue: statusString) ?? .pending
        }
        
        // Parse timestamps with better error handling
        guard let startDate = data["startDate"] as? Timestamp else {
            throw TravelAppError.dataError("Missing or invalid start date")
        }
        
        guard let endDate = data["endDate"] as? Timestamp else {
            throw TravelAppError.dataError("Missing or invalid end date")
        }
        
        guard let createdAt = data["createdAt"] as? Timestamp else {
            throw TravelAppError.dataError("Missing or invalid created date")
        }
        
        let updatedAt = data["updatedAt"] as? Timestamp
        
        // Parse recommendation if it exists (optional)
        let recommendation: Recommendation?
        if let recData = data["recommendation"] as? [String: Any] {
            do {
                recommendation = try parseRecommendation(from: recData)
            } catch {
                print("Warning: Failed to parse recommendation: \(error)")
                recommendation = nil // Don't fail the whole trip if recommendation fails
            }
        } else {
            recommendation = nil
        }
        
        return TravelTrip(
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
