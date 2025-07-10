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
        
        // Prepare request data with enhanced structure
        var requestData: [String: Any] = [
            "destinations": submission.destinations,
            "startDate": submission.startDate,
            "endDate": submission.endDate,
            "flexibleDates": submission.flexibleDates,
            "budget": submission.budget ?? "",
            "travelStyle": submission.travelStyle,
            "groupSize": submission.groupSize,
            "specialRequests": submission.specialRequests,
            "interests": submission.interests
        ]
        
        // Add optional fields
        if let flightClass = submission.flightClass {
            requestData["flightClass"] = flightClass
        }
        
        if let duration = submission.tripDuration {
            requestData["tripDuration"] = duration
        }
        
        print("Submitting enhanced trip data: \(requestData)")
        
        // Use the updated Cloud Function URL
        guard let url = URL(string: "https://us-central1-travel-consulting-app-1.cloudfunctions.net/submitTrip") else {
            throw TravelAppError.networkError("Invalid URL")
        }
        
        print("Making request to: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestData)
        } catch {
            throw TravelAppError.dataError("Failed to encode request data")
        }
        
        // Make the network call
        do {
            print("Sending HTTP request...")
            let (data, response) = try await URLSession.shared.data(for: request)
            
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
                throw TravelAppError.submissionFailed("Invalid request: \(errorMessage)")
            } else if httpResponse.statusCode == 401 {
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
            "flexibleDates": submission.flexibleDates
        ]
        
        // Add paymentMethod only if it exists (for backward compatibility)
        if let paymentMethod = submission.paymentMethod {
            requestData["paymentMethod"] = paymentMethod
        }
        
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
        guard let id = data["id"] as? String else {
            throw TravelAppError.dataError("Missing trip ID")
        }
        
        guard let userId = data["userId"] as? String else {
            throw TravelAppError.dataError("Missing user ID")
        }
        
        // Handle both old single destination and new multiple destinations
        let destination = data["destination"] as? String
        let destinations = data["destinations"] as? [String]
        
        // For backward compatibility, ensure we have at least one destination
        if destination == nil && (destinations == nil || destinations!.isEmpty) {
            throw TravelAppError.dataError("Missing destination(s)")
        }
        
        let paymentMethod = data["paymentMethod"] as? String // Now optional
        let flexibleDates = data["flexibleDates"] as? Bool ?? false
        
        // Parse status with backwards compatibility
        let statusString = data["status"] as? String ?? "pending"
        var status: TripStatusType
        switch statusString {
        case "submitted":
            status = .pending
        case "processing":
            status = .inProgress
        case "failed":
            status = .cancelled
        default:
            status = TripStatusType(rawValue: statusString) ?? .pending
        }
        
        // Parse timestamps (these should still be timestamps from Firestore)
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
        
        // Parse new fields
        let flightClass = data["flightClass"] as? String
        let budget = data["budget"] as? String
        let travelStyle = data["travelStyle"] as? String
        let groupSize = data["groupSize"] as? Int
        let interests = data["interests"] as? [String]
        let specialRequests = data["specialRequests"] as? String
        
        // Parse recommendation if it exists
        let recommendation: Recommendation?
        if let recData = data["recommendation"] as? [String: Any] {
            do {
                recommendation = try parseRecommendation(from: recData)
            } catch {
                print("Warning: Failed to parse recommendation: \(error)")
                recommendation = nil
            }
        } else {
            recommendation = nil
        }
        
        return TravelTrip(
            id: id,
            userId: userId,
            destination: destination,
            destinations: destinations,
            startDate: startDate,
            endDate: endDate,
            paymentMethod: paymentMethod,
            flexibleDates: flexibleDates,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
            recommendation: recommendation,
            flightClass: flightClass,
            budget: budget,
            travelStyle: travelStyle,
            groupSize: groupSize,
            interests: interests,
            specialRequests: specialRequests
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
        
        // Parse detailed itinerary if available
        let detailedItinerary: DetailedItinerary?
        if let itineraryData = data["itinerary"] as? [String: Any] {
            detailedItinerary = try parseDetailedItinerary(from: itineraryData)
        } else {
            detailedItinerary = nil
        }
        
        return Recommendation(
            id: id,
            destination: destination,
            overview: overview,
            itinerary: detailedItinerary,
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
    
    // MARK: - Detailed Itinerary Parsing
    private func parseDetailedItinerary(from data: [String: Any]) throws -> DetailedItinerary {
        guard let id = data["id"] as? String else {
            throw TravelAppError.dataError("Missing detailed itinerary ID")
        }
        
        // Parse flights
        let flights: FlightItinerary
        if let flightsData = data["flights"] as? [[String: Any]], !flightsData.isEmpty {
            // Admin dashboard saves flights as an array of flight objects
            // We need to parse them into our FlightItinerary structure
            flights = try parseFlightItinerary(from: flightsData)
        } else {
            // Fallback empty flight itinerary
            flights = FlightItinerary(
                outbound: createEmptyFlightDetails(),
                returnFlight: nil,
                additionalFlights: nil,
                totalFlightCost: FlexibleCost(cashOnly: 0),
                bookingDeadline: "",
                bookingInstructions: ""
            )
        }
        
        // Parse daily plans
        let dailyPlans: [DailyPlan]
        if let dailyPlansData = data["dailyPlans"] as? [[String: Any]] {
            dailyPlans = try dailyPlansData.compactMap { dayData in
                try parseDailyPlan(from: dayData)
            }
        } else {
            dailyPlans = []
        }
        
        // Parse accommodations  
        let accommodations: [AccommodationDetails]
        if let accommodationsData = data["accommodations"] as? [[String: Any]] {
            accommodations = try accommodationsData.compactMap { accData in
                try parseAccommodationDetails(from: accData)
            }
        } else {
            accommodations = []
        }
        
        // Parse total cost
        let totalCost: CostBreakdown
        if let costData = data["totalCost"] as? [String: Any] {
            totalCost = try parseCostBreakdown(from: costData)
        } else {
            totalCost = CostBreakdown(
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
        
        // Parse booking instructions (optional)
        let bookingInstructions = parseBookingInstructions(from: data["bookingInstructions"] as? [String: Any])
        
        // Parse major transportation (trains, buses, etc.)
        let majorTransportation: [LocalTransportation]?
        if let transportData = data["transportation"] as? [[String: Any]] {
            majorTransportation = try transportData.compactMap { try parseLocalTransportation(from: $0) }
        } else {
            majorTransportation = nil
        }
        
        // Parse emergency info (optional)
        let emergencyInfo = parseEmergencyInfo(from: data["emergencyInfo"] as? [String: Any])
        
        return DetailedItinerary(
            id: id,
            flights: flights,
            majorTransportation: majorTransportation,
            dailyPlans: dailyPlans,
            accommodations: accommodations,
            totalCost: totalCost,
            bookingInstructions: bookingInstructions,
            emergencyInfo: emergencyInfo
        )
    }
    
    private func parseFlightItinerary(from flightsData: [[String: Any]]) throws -> FlightItinerary {
        // Admin dashboard can have multiple flights (Flight 1, Flight 2, Flight 3)
        // We'll treat the first as outbound, second as return, and rest as additional
        var outboundFlight: FlightDetails?
        var returnFlight: FlightDetails?
        var additionalFlights: [FlightDetails] = []
        var totalCost = FlexibleCost(cashOnly: 0)
        var bookingInstructions = ""
        
        for (flightIndex, flightData) in flightsData.enumerated() {
            // Each flight can have multiple segments, but we'll take the first segment for now
            if let segments = flightData["segments"] as? [[String: Any]], 
               let firstSegment = segments.first {
                
                // Pass the flight-level booking instructions to the segment
                var segmentWithInstructions = firstSegment
                if let instructions = flightData["bookingInstructions"] as? String {
                    segmentWithInstructions["flightBookingInstructions"] = instructions
                }
                
                let flightDetails = try parseFlightDetails(from: segmentWithInstructions)
                
                // Add this flight's cost to the total
                totalCost = FlexibleCost(
                    cashOnly: totalCost.cashAmount + flightDetails.cost.cashAmount
                )
                
                if flightIndex == 0 {
                    outboundFlight = flightDetails
                } else if flightIndex == 1 {
                    returnFlight = flightDetails
                } else {
                    // Flight 3, Flight 4, etc.
                    additionalFlights.append(flightDetails)
                }
            }
        }
        
        return FlightItinerary(
            outbound: outboundFlight ?? createEmptyFlightDetails(),
            returnFlight: returnFlight,
            additionalFlights: additionalFlights.isEmpty ? nil : additionalFlights,
            totalFlightCost: totalCost,
            bookingDeadline: "",
            bookingInstructions: bookingInstructions.trimmingCharacters(in: .whitespaces)
        )
    }
    
    private func parseFlightDetails(from data: [String: Any]) throws -> FlightDetails {
        let flightNumber = data["flightNumber"] as? String ?? ""
        let airline = data["airline"] as? String ?? ""
        let duration = data["duration"] as? String ?? ""
        
        // Parse departure
        let departure: FlightSegment
        if let depData = data["departure"] as? [String: Any] {
            departure = FlightSegment(
                airport: depData["airport"] as? String ?? "",
                airportCode: depData["airportCode"] as? String ?? "",
                city: depData["city"] as? String ?? "",
                date: depData["date"] as? String ?? "",
                time: depData["time"] as? String ?? "",
                terminal: depData["terminal"] as? String,
                gate: depData["gate"] as? String
            )
        } else {
            departure = FlightSegment(airport: "", airportCode: "", city: "", date: "", time: "", terminal: nil, gate: nil)
        }
        
        // Parse arrival
        let arrival: FlightSegment
        if let arrData = data["arrival"] as? [String: Any] {
            arrival = FlightSegment(
                airport: arrData["airport"] as? String ?? "",
                airportCode: arrData["airportCode"] as? String ?? "",
                city: arrData["city"] as? String ?? "",
                date: arrData["date"] as? String ?? "",
                time: arrData["time"] as? String ?? "",
                terminal: arrData["terminal"] as? String,
                gate: arrData["gate"] as? String
            )
        } else {
            arrival = FlightSegment(airport: "", airportCode: "", city: "", date: "", time: "", terminal: nil, gate: nil)
        }
        
        // Parse cost
        let cost: FlexibleCost
        if let costData = data["cost"] as? [String: Any] {
            cost = try parseFlexibleCost(from: costData)
        } else {
            cost = FlexibleCost(cashOnly: 0)
        }
        
        return FlightDetails(
            flightNumber: flightNumber,
            airline: airline,
            departure: departure,
            arrival: arrival,
            duration: duration,
            aircraft: data["aircraft"] as? String ?? "",
            cost: cost,
            bookingClass: data["bookingClass"] as? String ?? "",
            bookingUrl: data["bookingUrl"] as? String,
            seatRecommendations: data["seatRecommendations"] as? String,
            bookingInstructions: data["flightBookingInstructions"] as? String,
            notes: data["notes"] as? String
        )
    }
    
    private func parseDailyPlan(from data: [String: Any]) throws -> DailyPlan {
        guard let id = data["id"] as? String,
              let dayNumber = data["dayNumber"] as? Int,
              let date = data["date"] as? String,
              let title = data["title"] as? String else {
            throw TravelAppError.dataError("Invalid daily plan data structure")
        }
        
        // Parse activities
        let activities: [DailyActivity]
        if let activitiesData = data["activities"] as? [[String: Any]] {
            activities = try activitiesData.compactMap { activityData in
                try parseDailyActivity(from: activityData)
            }
        } else {
            activities = []
        }
        
        // Parse estimated cost
        let estimatedCost: FlexibleCost
        if let costData = data["estimatedCost"] as? [String: Any] {
            estimatedCost = try parseFlexibleCost(from: costData)
        } else {
            estimatedCost = FlexibleCost(cashOnly: 0)
        }
        
        return DailyPlan(
            id: id,
            dayNumber: dayNumber,
            date: date,
            title: title,
            activities: activities,
            meals: [], // Not implemented in admin dashboard yet
            transportation: [], // Not implemented in admin dashboard yet
            estimatedCost: estimatedCost,
            notes: data["notes"] as? String
        )
    }
    
    private func parseDailyActivity(from data: [String: Any]) throws -> DailyActivity {
        guard let id = data["id"] as? String,
              let time = data["time"] as? String,
              let title = data["title"] as? String,
              let description = data["description"] as? String else {
            throw TravelAppError.dataError("Invalid daily activity data structure")
        }
        
        // Parse location
        let location: ActivityLocation
        if let locationData = data["location"] as? [String: Any] {
            location = ActivityLocation(
                name: locationData["name"] as? String ?? "",
                address: locationData["address"] as? String ?? "",
                coordinates: nil, // Not implemented yet
                nearbyLandmarks: locationData["nearbyLandmarks"] as? String
            )
        } else {
            location = ActivityLocation(name: "", address: "", coordinates: nil, nearbyLandmarks: nil)
        }
        
        // Parse cost
        let cost: FlexibleCost
        if let costData = data["cost"] as? [String: Any] {
            cost = try parseFlexibleCost(from: costData)
        } else {
            cost = FlexibleCost(cashOnly: 0)
        }
        
        // Parse category
        let category: ActivityCategory
        if let categoryString = data["category"] as? String,
           let parsedCategory = ActivityCategory(rawValue: categoryString) {
            category = parsedCategory
        } else {
            category = .sightseeing // Default
        }
        
        return DailyActivity(
            id: id,
            time: time,
            duration: data["duration"] as? String ?? "",
            title: title,
            description: description,
            location: location,
            cost: cost,
            bookingRequired: data["bookingRequired"] as? Bool ?? false,
            bookingUrl: data["bookingUrl"] as? String,
            bookingInstructions: data["bookingInstructions"] as? String,
            tips: data["tips"] as? [String] ?? [],
            category: category
        )
    }
    
    private func parseAccommodationDetails(from data: [String: Any]) throws -> AccommodationDetails {
        guard let id = data["id"] as? String,
              let name = data["name"] as? String,
              let checkIn = data["checkIn"] as? String,
              let checkOut = data["checkOut"] as? String,
              let nights = data["nights"] as? Int else {
            throw TravelAppError.dataError("Invalid accommodation details data structure")
        }
        
        // Parse type
        let type: AccommodationType
        if let typeString = data["type"] as? String,
           let parsedType = AccommodationType(rawValue: typeString) {
            type = parsedType
        } else {
            type = .hotel // Default
        }
        
        // Parse location
        let location: ActivityLocation
        if let locationData = data["location"] as? [String: Any] {
            location = ActivityLocation(
                name: locationData["name"] as? String ?? "",
                address: locationData["address"] as? String ?? "",
                coordinates: nil,
                nearbyLandmarks: locationData["nearbyLandmarks"] as? String
            )
        } else {
            location = ActivityLocation(name: "", address: "", coordinates: nil, nearbyLandmarks: nil)
        }
        
        // Parse cost
        let cost: FlexibleCost
        if let costData = data["cost"] as? [String: Any] {
            cost = try parseFlexibleCost(from: costData)
        } else {
            cost = FlexibleCost(cashOnly: 0)
        }
        
        // Parse contact info
        let contactInfo: ContactInfo
        if let contactData = data["contactInfo"] as? [String: Any] {
            contactInfo = ContactInfo(
                phone: contactData["phone"] as? String,
                email: contactData["email"] as? String,
                website: contactData["website"] as? String
            )
        } else {
            contactInfo = ContactInfo(phone: nil, email: nil, website: nil)
        }
        
        return AccommodationDetails(
            id: id,
            name: name,
            type: type,
            checkIn: checkIn,
            checkOut: checkOut,
            nights: nights,
            location: location,
            roomType: data["roomType"] as? String ?? "",
            amenities: data["amenities"] as? [String] ?? [],
            cost: cost,
            bookingUrl: data["bookingUrl"] as? String,
            bookingInstructions: data["bookingInstructions"] as? String ?? "",
            cancellationPolicy: data["cancellationPolicy"] as? String ?? "",
            contactInfo: contactInfo
        )
    }
    
    private func parseFlexibleCost(from data: [String: Any]) throws -> FlexibleCost {
        let paymentType = PaymentType(rawValue: data["paymentType"] as? String ?? "cash") ?? .cash
        let cashAmount = data["cashAmount"] as? Double ?? 0
        let pointsAmount = data["pointsAmount"] as? Int
        let pointsProgram = data["pointsProgram"] as? String
        let totalCashValue = data["totalCashValue"] as? Double ?? cashAmount
        let notes = data["notes"] as? String
        
        switch paymentType {
        case .cash:
            return FlexibleCost(cashOnly: cashAmount, notes: notes)
        case .points:
            return FlexibleCost(
                pointsOnly: pointsAmount ?? 0,
                program: pointsProgram ?? "",
                cashValue: totalCashValue,
                notes: notes
            )
        case .hybrid:
            return FlexibleCost(
                hybrid: cashAmount,
                points: pointsAmount ?? 0,
                program: pointsProgram ?? "",
                notes: notes
            )
        }
    }
    
    private func parseBookingInstructions(from data: [String: Any]?) -> BookingInstructions {
        guard let data = data else {
            return BookingInstructions(
                overallInstructions: "",
                flightBookingTips: [],
                accommodationBookingTips: [],
                activityBookingTips: [],
                paymentMethods: [],
                cancellationPolicies: "",
                travelInsuranceRecommendation: nil
            )
        }
        
        return BookingInstructions(
            overallInstructions: data["overallInstructions"] as? String ?? "",
            flightBookingTips: data["flightBookingTips"] as? [String] ?? [],
            accommodationBookingTips: data["accommodationBookingTips"] as? [String] ?? [],
            activityBookingTips: data["activityBookingTips"] as? [String] ?? [],
            paymentMethods: data["paymentMethods"] as? [String] ?? [],
            cancellationPolicies: data["cancellationPolicies"] as? String ?? "",
            travelInsuranceRecommendation: data["travelInsuranceRecommendation"] as? String
        )
    }
    
    private func parseEmergencyInfo(from data: [String: Any]?) -> EmergencyInfo {
        guard let data = data else {
            return EmergencyInfo(
                emergencyContacts: [],
                localEmergencyNumbers: [:],
                nearestEmbassy: nil,
                medicalFacilities: [],
                importantPhrases: [:]
            )
        }
        
        return EmergencyInfo(
            emergencyContacts: [], // Not implemented yet
            localEmergencyNumbers: data["localEmergencyNumbers"] as? [String: String] ?? [:],
            nearestEmbassy: nil, // Not implemented yet
            medicalFacilities: [], // Not implemented yet
            importantPhrases: data["importantPhrases"] as? [String: String] ?? [:]
        )
    }
    
    private func createEmptyFlightDetails() -> FlightDetails {
        return FlightDetails(
            flightNumber: "",
            airline: "",
            departure: FlightSegment(airport: "", airportCode: "", city: "", date: "", time: "", terminal: nil, gate: nil),
            arrival: FlightSegment(airport: "", airportCode: "", city: "", date: "", time: "", terminal: nil, gate: nil),
            duration: "",
            aircraft: "",
            cost: FlexibleCost(cashOnly: 0),
            bookingClass: "",
            bookingUrl: nil,
            seatRecommendations: nil,
            bookingInstructions: nil,
            notes: nil
        )
    }
    
    private func parseLocalTransportation(from data: [String: Any]) throws -> LocalTransportation {
        guard let id = data["id"] as? String else {
            throw TravelAppError.dataError("Missing transportation id")
        }
        
        // Admin dashboard uses different field names
        let departureDate = data["departureDate"] as? String ?? ""
        let departureTime = data["departureTime"] as? String ?? ""
        let arrivalDate = data["arrivalDate"] as? String ?? ""
        let arrivalTime = data["arrivalTime"] as? String ?? ""
        
        // Combine date and time for compatibility
        let time: String
        if !departureDate.isEmpty && !departureTime.isEmpty {
            time = "\(departureDate) \(departureTime)"
        } else if !departureTime.isEmpty {
            time = departureTime
        } else {
            time = data["time"] as? String ?? ""
        }
        
        let from = data["from"] as? String ?? ""
        let to = data["to"] as? String ?? ""
        
        // Calculate duration from arrival/departure if available
        let duration: String
        if !arrivalDate.isEmpty && !arrivalTime.isEmpty && !departureDate.isEmpty && !departureTime.isEmpty {
            // Could calculate duration here, but for now just use what's provided
            duration = data["duration"] as? String ?? ""
        } else {
            duration = data["duration"] as? String ?? ""
        }
        
        // Admin dashboard uses "bookingInstructions" and "notes" 
        let instructions = data["bookingInstructions"] as? String ?? data["instructions"] as? String ?? ""
        let bookingUrl = data["bookingUrl"] as? String
        
        // Parse transport method - admin dashboard uses "type" field
        let methodString = data["type"] as? String ?? data["method"] as? String ?? "train"
        let method: TransportMethod
        switch methodString.lowercased() {
        case "train":
            method = .train
        case "car_rental", "car", "rental":
            method = .rental
        case "ferry":
            method = .bus // Use bus as closest match, or could add ferry to enum
        case "bus":
            method = .bus
        case "taxi", "rideshare":
            method = .taxi
        case "metro", "subway":
            method = .metro
        default:
            method = .train
        }
        
        // Parse cost
        let cost: FlexibleCost
        if let costData = data["cost"] as? [String: Any] {
            cost = try parseFlexibleCost(from: costData)
        } else {
            cost = FlexibleCost(cashOnly: 0)
        }
        
        return LocalTransportation(
            id: id,
            time: time,
            method: method,
            from: from,
            to: to,
            duration: duration,
            cost: cost,
            instructions: instructions,
            bookingUrl: bookingUrl
        )
    }
}
