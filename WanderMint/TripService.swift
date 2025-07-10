import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import os.log

@MainActor
class TripService: ObservableObject {
    private let db = Firestore.firestore()
    @Published var networkMonitor = NetworkMonitor()
    
    // MARK: - Submit Enhanced Trip
    func submitEnhancedTrip(_ submission: EnhancedTripSubmission) async throws {
        // Check network connectivity
        guard networkMonitor.isConnected else {
            throw TravelAppError.networkUnavailable()
        }
        
        guard let user = Auth.auth().currentUser else {
            throw TravelAppError.authenticationFailed
        }
        
        
        // Get ID token for authentication
        let idToken: String
        do {
            idToken = try await user.getIDToken()
        } catch {
            throw TravelAppError.authenticationFailed
        }
        
        // Prepare request data with enhanced structure
        var requestData: [String: Any] = [
            "destinations": submission.destinations,
            "departureLocation": submission.departureLocation,
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
        
        
        // Use the configured Cloud Function URL
        guard let url = URL(string: AppConfig.API.Endpoints.submitTrip) else {
            throw TravelAppError.networkError("Invalid URL")
        }
        
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = AppConfig.Network.requestTimeout
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestData)
        } catch {
            throw TravelAppError.dataError("Failed to encode request data")
        }
        
        // Make the network call with timeout handling
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TravelAppError.networkError("Invalid response")
            }
            
            let responseString = String(data: data, encoding: .utf8) ?? "No response data"
            
            if httpResponse.statusCode == 200 {
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
            } else if let urlError = error as? URLError {
                switch urlError.code {
                case .timedOut:
                    throw TravelAppError.requestTimeout()
                case .notConnectedToInternet, .networkConnectionLost:
                    throw TravelAppError.networkUnavailable()
                default:
                    throw TravelAppError.networkError(urlError.localizedDescription)
                }
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
        
        
        // Create the HTTP request - use configured function URL
        guard let url = URL(string: AppConfig.API.Endpoints.submitTrip) else {
            throw TravelAppError.networkError("Invalid URL")
        }
        
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = AppConfig.Network.requestTimeout
        
        // Add debugging headers
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestData)
        } catch {
            throw TravelAppError.dataError("Failed to encode request data")
        }
        
        // Make the network call with timeout handling
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TravelAppError.networkError("Invalid response")
            }
            
            let responseString = String(data: data, encoding: .utf8) ?? "No response data"
            
            if httpResponse.statusCode == 200 {
                return
            } else if httpResponse.statusCode == 400 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Bad Request"
                throw TravelAppError.submissionFailed("Invalid request: \(errorMessage)")
            } else if httpResponse.statusCode == 401 {
                throw TravelAppError.authenticationFailed
            } else if httpResponse.statusCode == 403 {
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
            } else if let urlError = error as? URLError {
                switch urlError.code {
                case .timedOut:
                    throw TravelAppError.requestTimeout()
                case .notConnectedToInternet, .networkConnectionLost:
                    throw TravelAppError.networkUnavailable()
                default:
                    throw TravelAppError.networkError(urlError.localizedDescription)
                }
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
            
            
            let trips = snapshot.documents.compactMap { document -> TravelTrip? in
                var data = document.data()
                data["id"] = document.documentID
                
                
                do {
                    return try self.parseTrip(from: data)
                } catch {
                    return nil // Skip invalid trips instead of failing everything
                }
            }
            
            return trips
            
        } catch {
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
            
            
            // Check if recommendation exists
            if let recData = data["recommendation"] as? [String: Any] {
                if let transportationData = recData["transportation"] as? [String: Any] {
                    if let flightInfo = transportationData["flightInfo"] as? [String: Any] {
                    }
                }
                if let accommodationsData = recData["accommodations"] as? [[String: Any]] {
                } else {
                }
                
                // Check for itinerary structure
                if let itineraryData = recData["itinerary"] as? [String: Any] {
                    
                    if let flightsData = itineraryData["flights"] as? [String: Any] {
                        
                        // Check what type allFlights actually is
                        let allFlightsValue = flightsData["allFlights"]
                        
                        if let allFlights = flightsData["allFlights"] as? [[String: Any]] {
                            if let firstFlight = allFlights.first {
                            }
                        } else if let allFlights = flightsData["allFlights"] as? [Any] {
                        } else {
                        }
                    }
                    
                    if let accommodationsData = itineraryData["accommodations"] as? [[String: Any]] {
                    }
                } else {
                }
            } else {
            }
            
            var tripData = data
            tripData["id"] = document.documentID
            
            let parsedTrip = try parseTrip(from: tripData)
            return parsedTrip
        } catch {
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
        return try TripDataParser.parseTrip(from: data)
    }
    
    private func parseTrip_Legacy(from data: [String: Any]) throws -> TravelTrip {
        guard let id = data["id"] as? String else {
            throw TravelAppError.dataError("Missing trip ID")
        }
        
        guard let userId = data["userId"] as? String else {
            throw TravelAppError.dataError("Missing user ID")
        }
        
        // Handle both old single destination and new multiple destinations
        let destination = data["destination"] as? String
        let destinations = data["destinations"] as? [String]
        let departureLocation = data["departureLocation"] as? String
        
        // For backward compatibility, ensure we have at least one destination
        if destination == nil && (destinations?.isEmpty ?? true) {
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
        
        // Legacy recommendation support removed - only use destinationRecommendation
        let recommendation: Recommendation? = nil
        
        // Parse admin-compatible destination-based recommendation
        let destinationRecommendation: AdminDestinationBasedRecommendation?
        if let destRecData = data["destinationRecommendation"] as? [String: Any] {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: destRecData)
                destinationRecommendation = try JSONDecoder().decode(AdminDestinationBasedRecommendation.self, from: jsonData)
            } catch {
                destinationRecommendation = nil
            }
        } else {
            destinationRecommendation = nil
        }
        
        return TravelTrip(
            id: id,
            userId: userId,
            destination: destination,
            destinations: destinations,
            departureLocation: departureLocation,
            startDate: startDate,
            endDate: endDate,
            paymentMethod: paymentMethod,
            flexibleDates: flexibleDates,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
            recommendation: recommendation,
            destinationRecommendation: destinationRecommendation,
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
    
    // MARK: - Destination-Based Recommendation Parsing (Simplified)
    private func parseDestinationRecommendation(from data: [String: Any]) throws -> DestinationRecommendation {
        guard let id = data["id"] as? String,
              let cityName = data["cityName"] as? String,
              let arrivalDate = data["arrivalDate"] as? String,
              let departureDate = data["departureDate"] as? String,
              let numberOfNights = data["numberOfNights"] as? Int else {
            throw TravelAppError.dataError("Invalid destination recommendation data structure")
        }
        
        // Parse accommodation options
        let accommodationOptions: [AccommodationOption]
        if let accommodationData = data["accommodationOptions"] as? [[String: Any]] {
            accommodationOptions = try accommodationData.map { try parseAccommodationOption(from: $0) }
        } else {
            accommodationOptions = []
        }
        
        // Parse daily itinerary
        let dailyItinerary: [DailyPlan]
        if let dailyData = data["dailyItinerary"] as? [[String: Any]] {
            dailyItinerary = try dailyData.map { try parseDailyPlan(from: $0) }
        } else {
            dailyItinerary = []
        }
        
        // Parse local transportation
        let localTransportation: [LocalTransportOption]
        if let transportData = data["localTransportation"] as? [[String: Any]] {
            localTransportation = try transportData.map { try parseLocalTransportOption(from: $0) }
        } else {
            localTransportation = []
        }
        
        let selectedAccommodationId = data["selectedAccommodationId"] as? String
        
        return DestinationRecommendation(
            id: id,
            cityName: cityName,
            arrivalDate: arrivalDate,
            departureDate: departureDate,
            numberOfNights: numberOfNights,
            accommodationOptions: accommodationOptions,
            dailyItinerary: dailyItinerary,
            localTransportation: localTransportation,
            selectedAccommodationId: selectedAccommodationId
        )
    }
    
    private func parseAccommodationOption(from data: [String: Any]) throws -> AccommodationOption {
        guard let id = data["id"] as? String,
              let hotelData = data["hotel"] as? [String: Any],
              let isSelected = data["isSelected"] as? Bool,
              let isBooked = data["isBooked"] as? Bool,
              let priority = data["priority"] as? Int else {
            throw TravelAppError.dataError("Invalid accommodation option data structure")
        }
        
        // Parse hotel details (simplified - reuse existing accommodation parsing logic if available)
        let hotel = try parseAccommodationDetails(from: hotelData)
        
        let bookingReference = data["bookingReference"] as? String
        let bookedDate = data["bookedDate"] as? String
        
        return AccommodationOption(
            id: id,
            hotel: hotel,
            isSelected: isSelected,
            isBooked: isBooked,
            bookingReference: bookingReference,
            bookedDate: bookedDate,
            priority: priority
        )
    }
    
    private func parseLocalTransportOption(from data: [String: Any]) throws -> LocalTransportOption {
        guard let id = data["id"] as? String,
              let transportData = data["transportation"] as? [String: Any],
              let isRecommended = data["isRecommended"] as? Bool else {
            throw TravelAppError.dataError("Invalid local transport option data structure")
        }
        
        let transportation = try parseLocalTransportation(from: transportData)
        let notes = data["notes"] as? String
        
        return LocalTransportOption(
            id: id,
            transportation: transportation,
            isRecommended: isRecommended,
            notes: notes
        )
    }
    
    private func parseLogisticsRecommendation(from data: [String: Any]) throws -> LogisticsRecommendation {
        let transportSegments: [TransportSegment]
        if let segmentsData = data["transportSegments"] as? [[String: Any]] {
            transportSegments = try segmentsData.map { try parseTransportSegment(from: $0) }
        } else {
            transportSegments = []
        }
        
        let bookingDeadlines = data["bookingDeadlines"] as? [String] ?? []
        let generalInstructions = data["generalInstructions"] as? String ?? ""
        
        return LogisticsRecommendation(
            transportSegments: transportSegments,
            bookingDeadlines: bookingDeadlines,
            generalInstructions: generalInstructions
        )
    }
    
    private func parseTransportSegment(from data: [String: Any]) throws -> TransportSegment {
        guard let id = data["id"] as? String,
              let date = data["date"] as? String,
              let route = data["route"] as? String else {
            throw TravelAppError.dataError("Invalid transport segment data structure")
        }
        
        let transportOptions: [TransportOption]
        if let optionsData = data["transportOptions"] as? [[String: Any]] {
            transportOptions = try optionsData.map { try parseTransportOption(from: $0) }
        } else {
            transportOptions = []
        }
        
        let selectedOptionId = data["selectedOptionId"] as? String
        
        // Parse booking groups
        let bookingGroups: [BookingGroup]
        if let bookingGroupsData = data["bookingGroups"] as? [[String: Any]] {
            bookingGroups = try bookingGroupsData.map { try parseBookingGroup(from: $0) }
        } else {
            bookingGroups = []
        }
        
        return TransportSegment(
            id: id,
            date: date,
            route: route,
            transportOptions: transportOptions,
            selectedOptionId: selectedOptionId,
            bookingGroups: bookingGroups
        )
    }
    
    private func parseTransportOption(from data: [String: Any]) throws -> TransportOption {
        guard let id = data["id"] as? String,
              let transportType = data["transportType"] as? String,
              let detailsData = data["details"] as? [String: Any] else {
            throw TravelAppError.dataError("Invalid transport option data structure")
        }
        
        // Parse transport details based on type
        let type = TransportType(rawValue: transportType) ?? .flight
        let details: TransportDetails
        
        // Handle nested structure from admin dashboard: { type: 'flight', details: {...} }
        let actualDetailsData: [String: Any]
        if let nestedDetails = detailsData["details"] as? [String: Any] {
            actualDetailsData = nestedDetails
        } else {
            actualDetailsData = detailsData
        }
        
        switch type {
        case .flight:
            let flightDetails = try parseFlightDetails(from: actualDetailsData)
            details = .flight(flightDetails)
        case .train:
            let trainDetails = try parseTrainDetails(from: actualDetailsData)
            details = .train(trainDetails)
        case .bus:
            let busDetails = try parseBusDetails(from: actualDetailsData)
            details = .bus(busDetails)
        case .ferry:
            let ferryDetails = try parseFerryDetails(from: actualDetailsData)
            details = .ferry(ferryDetails)
        case .car:
            let carDetails = try parseCarRentalDetails(from: actualDetailsData)
            details = .car(carDetails)
        }
        
        // Parse cost
        let cost: TransportCost
        if let costData = data["cost"] as? [String: Any] {
            cost = try parseTransportCost(from: costData)
        } else {
            cost = TransportCost(cash: 0, points: 0, currency: "USD")
        }
        
        let duration = data["duration"] as? String ?? ""
        let bookingUrl = data["bookingUrl"] as? String
        let notes = data["notes"] as? String
        let isSelected = data["isSelected"] as? Bool ?? false
        let isBooked = data["isBooked"] as? Bool ?? false
        let bookingReference = data["bookingReference"] as? String
        let bookedDate = data["bookedDate"] as? String
        let priority = data["priority"] as? Int ?? 1
        
        return TransportOption(
            id: id,
            transportType: transportType,
            details: details,
            cost: cost,
            duration: duration,
            bookingUrl: bookingUrl,
            notes: notes,
            isSelected: isSelected,
            isBooked: isBooked,
            bookingReference: bookingReference,
            bookedDate: bookedDate,
            priority: priority
        )
    }
    
    private func parseTransportCost(from data: [String: Any]) throws -> TransportCost {
        // Handle both old simple format and new FlexibleCost format
        if let cashAmount = data["cashAmount"] as? Double {
            // New FlexibleCost format from admin dashboard
            let points = data["pointsAmount"] as? Int ?? 0
            let cash = cashAmount
            let currency = "USD" // Default currency
            return TransportCost(cash: cash, points: points, currency: currency)
        } else {
            // Legacy format
            let cash = data["cash"] as? Double ?? 0
            let points = data["points"] as? Int ?? 0
            let currency = data["currency"] as? String ?? "USD"
            return TransportCost(cash: cash, points: points, currency: currency)
        }
    }
    
    // Additional parsing functions for transport details
    private func parseFlightDetails(from data: [String: Any]) throws -> FlightDetails {
        let flightNumber = data["flightNumber"] as? String ?? ""
        let airline = data["airline"] as? String ?? ""
        let duration = data["duration"] as? String ?? ""
        let aircraft = data["aircraft"] as? String ?? ""
        let bookingClass = data["bookingClass"] as? String ?? "economy"
        let bookingUrl = data["bookingUrl"] as? String
        let seatRecommendations = data["seatRecommendations"] as? String
        let bookingInstructions = data["bookingInstructions"] as? String
        let notes = data["notes"] as? String
        let isBooked = data["isBooked"] as? Bool
        let bookingReference = data["bookingReference"] as? String
        let bookedDate = data["bookedDate"] as? String
        let seatNumbers = data["seatNumbers"] as? String
        
        // Parse departure and arrival segments
        let departure: FlightSegment
        if let depData = data["departure"] as? [String: Any] {
            departure = try parseFlightSegment(from: depData)
        } else {
            departure = FlightSegment(airport: "", airportCode: "", city: "", date: "", time: "", terminal: nil, gate: nil)
        }
        
        let arrival: FlightSegment
        if let arrData = data["arrival"] as? [String: Any] {
            arrival = try parseFlightSegment(from: arrData)
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
            aircraft: aircraft,
            cost: cost,
            bookingClass: bookingClass,
            bookingUrl: bookingUrl,
            seatRecommendations: seatRecommendations,
            bookingInstructions: bookingInstructions,
            notes: notes,
            isBooked: isBooked,
            bookingReference: bookingReference,
            bookedDate: bookedDate,
            seatNumbers: seatNumbers
        )
    }
    
    private func parseFlightSegment(from data: [String: Any]) throws -> FlightSegment {
        let airport = data["airport"] as? String ?? ""
        let airportCode = data["airportCode"] as? String ?? ""
        let city = data["city"] as? String ?? ""
        let date = data["date"] as? String ?? ""
        let time = data["time"] as? String ?? ""
        let terminal = data["terminal"] as? String
        let gate = data["gate"] as? String
        
        return FlightSegment(
            airport: airport,
            airportCode: airportCode,
            city: city,
            date: date,
            time: time,
            terminal: terminal,
            gate: gate
        )
    }
    
    private func parseFlexibleCost(from data: [String: Any]) throws -> FlexibleCost {
        if let paymentType = data["paymentType"] as? String {
            // New FlexibleCost format
            let cashAmount = data["cashAmount"] as? Double ?? 0
            let pointsAmount = data["pointsAmount"] as? Int
            let pointsProgram = data["pointsProgram"] as? String
            let totalCashValue = data["totalCashValue"] as? Double ?? cashAmount
            let notes = data["notes"] as? String
            
            switch paymentType {
            case "cash":
                return FlexibleCost(cashOnly: cashAmount, notes: notes)
            case "points":
                return FlexibleCost(
                    pointsOnly: pointsAmount ?? 0,
                    program: pointsProgram ?? "",
                    cashValue: totalCashValue,
                    notes: notes
                )
            case "hybrid":
                return FlexibleCost(
                    hybrid: cashAmount,
                    points: pointsAmount ?? 0,
                    program: pointsProgram ?? "",
                    notes: notes
                )
            default:
                return FlexibleCost(cashOnly: cashAmount, notes: notes)
            }
        } else {
            // Legacy format
            let cash = data["cash"] as? Double ?? 0
            return FlexibleCost(cashOnly: cash)
        }
    }
    
    private func parseTrainDetails(from data: [String: Any]) throws -> TrainDetails {
        // Simplified implementation - you can expand this based on your needs
        throw TravelAppError.dataError("Train details parsing not yet implemented")
    }
    
    private func parseBusDetails(from data: [String: Any]) throws -> BusDetails {
        // Simplified implementation - you can expand this based on your needs
        throw TravelAppError.dataError("Bus details parsing not yet implemented")
    }
    
    private func parseFerryDetails(from data: [String: Any]) throws -> FerryDetails {
        // Simplified implementation - you can expand this based on your needs
        throw TravelAppError.dataError("Ferry details parsing not yet implemented")
    }
    
    private func parseCarRentalDetails(from data: [String: Any]) throws -> CarRentalDetails {
        // Simplified implementation - you can expand this based on your needs
        throw TravelAppError.dataError("Car rental details parsing not yet implemented")
    }
    
    // MARK: - Detailed Itinerary Parsing
    private func parseDetailedItinerary(from data: [String: Any]) throws -> DetailedItinerary {
        guard let id = data["id"] as? String else {
            throw TravelAppError.dataError("Missing detailed itinerary ID")
        }
        
        // Parse flights
        let flights: FlightItinerary
        if let flightsContainer = data["flights"] as? [String: Any] {
            if let flightsData = flightsContainer["allFlights"] as? [[String: Any]], !flightsData.isEmpty {
                // Standard array format
                flights = try parseFlightItinerary(from: flightsData)
            } else if let flightsDict = flightsContainer["allFlights"] as? [String: [String: Any]] {
                // Dictionary format (Firebase sometimes stores arrays as dictionaries with numeric keys)
                let sortedFlights = flightsDict.keys.sorted { Int($0) ?? 0 < Int($1) ?? 0 }
                let flightsArray = sortedFlights.compactMap { flightsDict[$0] }
                if let firstFlight = flightsArray.first {
                    
                    // Check if we have complete flight data or just booking fields
                    let hasFlightDetails = firstFlight.keys.contains { !["isBooked", "bookingReference", "bookedDate"].contains($0) }
                    if !hasFlightDetails {
                    }
                }
                flights = try parseFlightItinerary(from: flightsArray)
            } else {
                flights = createEmptyFlightItinerary()
            }
        } else if let flightsData = data["flights"] as? [[String: Any]], !flightsData.isEmpty {
            // Legacy direct array format
            flights = try parseFlightItinerary(from: flightsData)
        } else {
            flights = createEmptyFlightItinerary()
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
        let bookingInstructions = ""
        
        for (flightIndex, flightData) in flightsData.enumerated() {
            // Each flight can have multiple segments, but we'll take the first segment for now
            if let segments = flightData["segments"] as? [[String: Any]], 
               let firstSegment = segments.first {
                
                // Pass the flight-level data to the segment (booking data + instructions)
                var segmentWithFlightData = firstSegment
                
                // Pass booking instructions from flight level
                if let instructions = flightData["bookingInstructions"] as? String {
                    segmentWithFlightData["flightBookingInstructions"] = instructions
                }
                
                // Pass booking data from flight level (entire route)
                if let isBooked = flightData["isBooked"] as? Bool {
                    segmentWithFlightData["isBooked"] = isBooked
                }
                if let bookingReference = flightData["bookingReference"] as? String {
                    segmentWithFlightData["bookingReference"] = bookingReference
                }
                if let bookedDate = flightData["bookedDate"] as? String {
                    segmentWithFlightData["bookedDate"] = bookedDate
                }
                
                let flightDetails = try parseFlightDetails(from: segmentWithFlightData)
                
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
        
        // Parse photos
        let photos: [AccommodationPhoto]?
        if let photosData = data["photos"] as? [[String: Any]] {
            photos = photosData.compactMap { photoData in
                guard let url = photoData["url"] as? String else { return nil }
                return AccommodationPhoto(
                    id: photoData["id"] as? String ?? UUID().uuidString,
                    url: url,
                    caption: photoData["caption"] as? String,
                    width: photoData["width"] as? Int,
                    height: photoData["height"] as? Int
                )
            }
        } else {
            photos = nil
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
            contactInfo: contactInfo,
            photos: photos,
            detailedDescription: data["description"] as? String,
            reviewRating: data["rating"] as? Double,
            numReviews: data["numReviews"] as? Int,
            priceLevel: data["priceLevel"] as? String,
            hotelChain: data["hotelChain"] as? String,
            tripadvisorUrl: data["tripadvisorUrl"] as? String,
            tripadvisorId: data["tripAdvisorLocationId"] as? String ?? data["tripadvisorId"] as? String,
            consultantNotes: data["consultantNotes"] as? String,
            source: data["source"] as? String,
            airbnbUrl: data["airbnbUrl"] as? String,
            airbnbListingId: data["airbnbListingId"] as? String,
            hostName: data["hostName"] as? String,
            hostIsSuperhost: data["hostIsSuperhost"] as? Bool,
            propertyType: data["propertyType"] as? String,
            bedrooms: data["bedrooms"] as? Int,
            bathrooms: data["bathrooms"] as? Double,
            maxGuests: data["maxGuests"] as? Int,
            instantBook: data["instantBook"] as? Bool,
            neighborhood: data["neighborhood"] as? String,
            houseRules: data["houseRules"] as? [String],
            checkInInstructions: data["checkInInstructions"] as? String,
            isBooked: data["isBooked"] as? Bool,
            bookingReference: data["bookingReference"] as? String,
            bookedDate: data["bookedDate"] as? String
        )
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
    
    private func parseBookingGroup(from data: [String: Any]) throws -> BookingGroup {
        guard let id = data["id"] as? String,
              let title = data["title"] as? String,
              let description = data["description"] as? String else {
            throw TravelAppError.dataError("Invalid booking group data structure")
        }
        
        let transportOptionIds = data["transportOptionIds"] as? [String] ?? []
        let bookingUrl = data["bookingUrl"] as? String
        
        // Parse total cost if provided
        let totalCost: TransportCost?
        if let costData = data["totalCost"] as? [String: Any] {
            totalCost = try parseTransportCost(from: costData)
        } else {
            totalCost = nil
        }
        
        let notes = data["notes"] as? String
        let isRoundTrip = data["isRoundTrip"] as? Bool ?? false
        let bookingDeadline = data["bookingDeadline"] as? String
        let isSelected = data["isSelected"] as? Bool ?? false
        let isBooked = data["isBooked"] as? Bool ?? false
        let bookingReference = data["bookingReference"] as? String
        let bookedDate = data["bookedDate"] as? String
        
        return BookingGroup(
            id: id,
            title: title,
            description: description,
            transportOptionIds: transportOptionIds,
            bookingUrl: bookingUrl,
            totalCost: totalCost,
            notes: notes,
            isRoundTrip: isRoundTrip,
            bookingDeadline: bookingDeadline,
            isSelected: isSelected,
            isBooked: isBooked,
            bookingReference: bookingReference,
            bookedDate: bookedDate
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
            notes: nil,
            isBooked: nil,
            bookingReference: nil,
            bookedDate: nil,
            seatNumbers: nil
        )
    }
    
    private func createEmptyFlightItinerary() -> FlightItinerary {
        return FlightItinerary(
            outbound: createEmptyFlightDetails(),
            returnFlight: nil,
            additionalFlights: nil,
            totalFlightCost: FlexibleCost(cashOnly: 0),
            bookingDeadline: "",
            bookingInstructions: ""
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
    
    // MARK: - Booking Status Updates
    func updateFlightBookingStatus(tripId: String, flightIndex: Int, isBooked: Bool, bookingReference: String, bookedDate: String) async throws {
        guard Auth.auth().currentUser != nil else {
            throw TravelAppError.authenticationFailed
        }
        
        
        let tripRef = db.collection("trips").document(tripId)
        
        // First, fetch the current trip to preserve existing flight data
        let document = try await tripRef.getDocument()
        guard let tripData = document.data() else {
            throw TravelAppError.dataError("Trip not found")
        }
        
        guard let recData = tripData["recommendation"] as? [String: Any] else {
            throw TravelAppError.dataError("No recommendation data")
        }
        
        guard let itineraryData = recData["itinerary"] as? [String: Any] else {
            throw TravelAppError.dataError("No itinerary data")
        }
        
        
        // The flights data is stored as an array of flight objects, not a dictionary with allFlights
        guard var flightsArray = itineraryData["flights"] as? [[String: Any]] else {
            throw TravelAppError.dataError("Flights data format mismatch")
        }
        
        
        // Validate flight index
        guard flightIndex >= 0 && flightIndex < flightsArray.count else {
            throw TravelAppError.dataError("Flight index out of bounds")
        }
        
        // Update the flight at the specified index while preserving existing data
        var existingFlight = flightsArray[flightIndex]
        
        // Store booking data at FLIGHT level (entire route including connections)
        existingFlight["isBooked"] = isBooked
        existingFlight["bookingReference"] = bookingReference
        existingFlight["bookedDate"] = bookedDate
        
        
        // Update the array with the modified flight
        flightsArray[flightIndex] = existingFlight
        
        let updateData: [String: Any] = [
            "recommendation.itinerary.flights": flightsArray,
            "updatedAt": Timestamp()
        ]
        
        try await tripRef.updateData(updateData)
    }
    
    func updateAccommodationBookingStatus(tripId: String, accommodationIndex: Int, isBooked: Bool, bookingReference: String, bookedDate: String) async throws {
        guard Auth.auth().currentUser != nil else {
            throw TravelAppError.authenticationFailed
        }
        
        
        let tripRef = db.collection("trips").document(tripId)
        
        let updateData: [String: Any] = [
            "recommendation.itinerary.accommodations.\(accommodationIndex).isBooked": isBooked,
            "recommendation.itinerary.accommodations.\(accommodationIndex).bookingReference": bookingReference,
            "recommendation.itinerary.accommodations.\(accommodationIndex).bookedDate": bookedDate,
            "updatedAt": Timestamp()
        ]
        
        try await tripRef.updateData(updateData)
    }
}
