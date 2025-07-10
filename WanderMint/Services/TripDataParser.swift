import Foundation
import FirebaseFirestore

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
        if destination == nil && (destinations == nil || destinations!.isEmpty) {
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
        guard let createdAt = data["createdAt"] as? Timestamp else {
            throw TravelAppError.dataError("Missing createdAt timestamp")
        }
        
        let updatedAt = data["updatedAt"] as? Timestamp
        
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
        let destinationRecommendation: AdminDestinationBasedRecommendation?
        if let destRecData = data["destinationRecommendation"] as? [String: Any] {
            do {
                // Sanitize data before parsing to remove NaN values
                let sanitizedData = sanitizeDataForSerialization(destRecData)
                let jsonData = try JSONSerialization.data(withJSONObject: sanitizedData)
                
                // Add detailed debugging
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                }
                
                destinationRecommendation = try JSONDecoder().decode(AdminDestinationBasedRecommendation.self, from: jsonData)
            } catch {
                
                // Try to get more specific error information
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        Logger.error("Missing key: \(key.stringValue) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))", category: Logger.data)
                    case .typeMismatch(let type, let context):
                        Logger.error("Type mismatch for type '\(type)' at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))", category: Logger.data)
                    case .valueNotFound(let type, let context):
                        Logger.error("Value not found for type '\(type)' at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))", category: Logger.data)
                    case .dataCorrupted(let context):
                        Logger.error("Data corrupted at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))", category: Logger.data)
                    @unknown default:
                        Logger.error("Unknown decoding error: \(decodingError)", category: Logger.data)
                    }
                }
                
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
    
    private static func parseTimestamp(from data: Any?) -> Timestamp? {
        if let timestamp = data as? Timestamp {
            return timestamp
        } else if let dateString = data as? String {
            // Handle string dates (ISO format)
            let formatter = ISO8601DateFormatter()
            if let date = formatter.date(from: dateString) {
                return Timestamp(date: date)
            }
        }
        return nil
    }
    
    private static func sanitizeDataForSerialization(_ data: Any) -> Any {
        if let dict = data as? [String: Any] {
            var sanitizedDict: [String: Any] = [:]
            for (key, value) in dict {
                sanitizedDict[key] = sanitizeDataForSerialization(value)
            }
            return sanitizedDict
        } else if let array = data as? [Any] {
            return array.map { sanitizeDataForSerialization($0) }
        } else if let double = data as? Double {
            // Replace NaN and infinite values with 0.0
            return double.isNaN || double.isInfinite ? 0.0 : double
        } else if let float = data as? Float {
            // Replace NaN and infinite values with 0.0
            return float.isNaN || float.isInfinite ? 0.0 : Double(float)
        } else {
            return data
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