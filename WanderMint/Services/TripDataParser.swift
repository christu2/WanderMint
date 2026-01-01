import Foundation
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

// MARK: - Trip Data Parsing Helper
class TripDataParser {
    
    static func parseTrip(from data: [String: Any]) throws -> TravelTrip {
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
        
        let paymentMethod = data["paymentMethod"] as? String
        let flexibleDates = data["flexibleDates"] as? Bool ?? false
        
        // Parse status with backwards compatibility
        let statusString = data["status"] as? String ?? "pending"
        guard let status = TripStatusType(rawValue: statusString) else {
            throw TravelAppError.dataError("Invalid status: \(statusString)")
        }
        
        // Parse timestamps
        guard let createdAt = data["createdAt"] as? AppTimestamp else {
            throw TravelAppError.dataError("Missing createdAt timestamp")
        }
        
        let updatedAt = data["updatedAt"] as? AppTimestamp
        
        // Parse dates
        guard let startDate = parseTimestamp(from: data["startDate"]),
              let endDate = parseTimestamp(from: data["endDate"]) else {
            throw TravelAppError.dataError("Invalid date format")
        }
        
        // Parse optional fields
        let flightClass = data["flightClass"] as? String
        let budget = data["budget"] as? String
        let travelStyle = data["travelStyle"] as? String
        let groupSize = data["groupSize"] as? Int
        let interests = data["interests"] as? [String]
        let specialRequests = data["specialRequests"] as? String
        
        // Legacy recommendation support removed
        let recommendation: Recommendation? = nil
        
        // Parse admin-compatible destination-based recommendation
        // Enhanced destinationRecommendation parsing with fallback
        let destinationRecommendation: AdminDestinationBasedRecommendation?
        if let destRecData = data["destinationRecommendation"] as? [String: Any] {
            do {
                // Sanitize data before parsing
                let sanitizedData = sanitizeDataForSerialization(destRecData)
                let jsonData = try JSONSerialization.data(withJSONObject: sanitizedData)
                destinationRecommendation = try JSONDecoder().decode(AdminDestinationBasedRecommendation.self, from: jsonData)
            } catch {
                Logger.error("Failed to parse destinationRecommendation: \(error)", category: Logger.data)
                
                // Try to create a minimal recommendation with basic data
                destinationRecommendation = createMinimalRecommendation(from: destRecData)
                
                // Log specific error details for debugging
                if let decodingError = error as? DecodingError {
                    logDecodingError(decodingError)
                }
                
                // Add this temporary debugging code:
                print("=== TRIP PARSING DEBUG ===")
                print("Trip ID: \(id)")
                print("Parsing failed for destinationRecommendation")
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .typeMismatch(let type, let context):
                        print("Type mismatch: expected \(type) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                    case .keyNotFound(let key, let context):
                        print("Missing key: \(key.stringValue) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                    default:
                        print("Other error: \(decodingError)")
                    }
                }
                print("=== END DEBUG ===")
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
    
    private static func parseTimestamp(from data: Any?) -> AppTimestamp? {
        if let timestamp = data as? AppTimestamp {
            return timestamp
        } else if let dateString = data as? String {
            // Handle string dates (ISO format)
            let formatter = ISO8601DateFormatter()
            if let date = formatter.date(from: dateString) {
                return createTimestamp(date: date)
            }
        }
        return nil
    }
    
    private static func sanitizeDataForSerialization(_ data: Any) -> Any {
        if let dict = data as? [String: Any] {
            var sanitizedDict: [String: Any] = [:]
            for (key, value) in dict {
                let sanitizedValue = sanitizeDataForSerialization(value)
                
                // Handle specific null-prone fields
                if key == "linkedSegmentId" && sanitizedValue is NSNull {
                    // Convert null linkedSegmentId to nil (omit from JSON)
                    continue
                }
                
                sanitizedDict[key] = sanitizedValue
            }
            return sanitizedDict
        } else if let array = data as? [Any] {
            return array.map { sanitizeDataForSerialization($0) }
        } else if let double = data as? Double {
            return double.isNaN || double.isInfinite ? 0.0 : double
        } else if let float = data as? Float {
            return float.isNaN || float.isInfinite ? 0.0 : Double(float)
        } else if data is NSNull {
            return NSNull()
        } else if let stringValue = data as? String, stringValue.lowercased() == "nan" {
            // Handle NaN that comes as string from Firestore
            return 0.0
        } else {
            // Additional NaN detection for Firestore edge cases
            let description = String(describing: data)
            if description.lowercased().contains("nan") || description == "nan" {
                return 0.0
            }
            return data
        }
    }
    
    private static func createMinimalRecommendation(from data: [String: Any]) -> AdminDestinationBasedRecommendation? {
        do {
            var minimalData: [String: Any] = [
                "id": data["id"] as? String ?? UUID().uuidString,
                "tripOverview": data["tripOverview"] as? String ?? "",
                "destinations": [],
                "logistics": [
                    "transportSegments": [],
                    "generalInstructions": "",
                    "bookingDeadlines": []
                ],
                "totalCost": [
                    "currency": "USD",
                    "totalEstimate": 0,
                    "accommodation": 0,
                    "flights": 0,
                    "food": 0,
                    "activities": 0,
                    "localTransport": 0,
                    "miscellaneous": 0
                ]
            ]
            
            let jsonData = try JSONSerialization.data(withJSONObject: minimalData)
            return try JSONDecoder().decode(AdminDestinationBasedRecommendation.self, from: jsonData)
        } catch {
            Logger.error("Failed to create minimal recommendation: \(error)", category: Logger.data)
            return nil
        }
    }
    
    private static func logDecodingError(_ error: DecodingError) {
        switch error {
        case .typeMismatch(let type, let context):
            let path = context.codingPath.map { $0.stringValue }.joined(separator: ".")
            Logger.error("Type mismatch at '\(path)': expected \(type)", category: Logger.data)
        case .valueNotFound(let type, let context):
            let path = context.codingPath.map { $0.stringValue }.joined(separator: ".")
            Logger.error("Value not found at '\(path)': expected \(type)", category: Logger.data)
        case .keyNotFound(let key, let context):
            let path = context.codingPath.map { $0.stringValue }.joined(separator: ".")
            Logger.error("Key not found: '\(key.stringValue)' at path '\(path)'", category: Logger.data)
        case .dataCorrupted(let context):
            let path = context.codingPath.map { $0.stringValue }.joined(separator: ".")
            Logger.error("Data corrupted at '\(path)': \(context.debugDescription)", category: Logger.data)
        @unknown default:
            Logger.error("Unknown decoding error: \(error)", category: Logger.data)
        }
    }
}

// MARK: - Data Validation Helper
class TripDataValidator {
    
    static func validateTripSubmission(_ submission: EnhancedTripSubmission) throws {
        if submission.destinations.isEmpty {
            throw TravelAppError.dataError("At least one destination is required")
        }
        
        if submission.groupSize <= 0 {
            throw TravelAppError.dataError("Group size must be greater than 0")
        }
        
        // Add more validation as needed
    }
    
    static func validateUserInput(destinations: [String], startDate: String, endDate: String) throws {
        if destinations.isEmpty {
            throw TravelAppError.dataError("Please select at least one destination")
        }
        
        // Add date validation
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let start = formatter.date(from: startDate),
              let end = formatter.date(from: endDate) else {
            throw TravelAppError.dataError("Invalid date format")
        }
        
        if start >= end {
            throw TravelAppError.dataError("End date must be after start date")
        }
        
        if start < Date() {
            throw TravelAppError.dataError("Start date cannot be in the past")
        }
    }
}