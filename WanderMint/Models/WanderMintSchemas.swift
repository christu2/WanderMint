// AUTO-GENERATED CODE - DO NOT EDIT MANUALLY
// Generated from: shared-schemas/schemas/core/*.schema.json
// Generation Date: 2026-01-03T02:34:25.006Z
//
// IMPORTANT: This file is auto-generated from shared schemas.
// To modify types, edit the source JSON schemas and regenerate.
//
// Available types:
//   - Budget (enum)
//   - TravelStyle (enum)
//
// To regenerate:
//   cd /Users/nick/Development/travelBusiness/shared-schemas
//   npm run generate:swift
//

import Foundation

// MARK: - Budget Enum

/// Travel budget preference levels - determines accommodation and activity pricing tiers
///
/// IMPORTANT: This is different from travelStyle
/// Budget controls PRICING tier (how much to spend)
/// TravelStyle controls PACE and TYPE (Adventure vs Relaxation)
/// A user can have budget='Budget' and travelStyle='Adventure'
/// Do NOT confuse with monetary amounts like '$1500'
public enum Budget: String, Codable, CaseIterable, Hashable {
    case budget = "Budget"
    case comfortable = "Comfortable"
    case midrange = "Mid-range"
    case luxury = "Luxury"
    case ultraluxury = "Ultra-Luxury"

    /// Display name for UI
    public var displayName: String {
        return self.rawValue
    }

    /// Description from schema
    public var schemaDescription: String {
        return "Travel budget preference levels - determines accommodation and activity pricing tiers"
    }
}

// MARK: - Travel Style Enum

/// Travel preference style or pace - defines the TYPE and PACE of travel, NOT the budget
///
/// IMPORTANT: This is different from budget
/// TravelStyle controls PACE and TYPE (fast-paced vs slow, active vs restful)
/// Budget controls PRICING tier
/// Adventure and Relaxation are ONLY valid for travelStyle, NOT budget
/// Mid-range and Ultra-Luxury are ONLY valid for budget, NOT travelStyle
public enum TravelStyle: String, Codable, CaseIterable, Hashable {
    case budget = "Budget"
    case comfortable = "Comfortable"
    case luxury = "Luxury"
    case adventure = "Adventure"
    case relaxation = "Relaxation"

    /// Display name for UI
    public var displayName: String {
        return self.rawValue
    }

    /// Description from schema
    public var schemaDescription: String {
        return "Travel preference style or pace - defines the TYPE and PACE of travel, NOT the budget"
    }

    /// Semantic meaning of this travel style
    public var meaning: String {
        switch self {
        case .budget: return "Budget-conscious travel style with basic accommodations"
        case .comfortable: return "Moderate comfort with good value"
        case .luxury: return "High-end experiences and premium services"
        case .adventure: return "Active, fast-paced, outdoor/adventure-focused"
        case .relaxation: return "Slow-paced, restful, spa/beach-focused"
        }
    }
}

// MARK: - Helper Extensions

extension Budget {
    /// Check if this is a budget-only value (not valid for travelStyle)
    public var isBudgetOnly: Bool {
        switch self {
        case .midrange, .ultraluxury:
            return true
        default:
            return false
        }
    }
}

extension TravelStyle {
    /// Check if this is a travelStyle-only value (not valid for budget)
    public var isTravelStyleOnly: Bool {
        switch self {
        case .adventure, .relaxation:
            return true
        default:
            return false
        }
    }
}

// MARK: - Validation Helpers

/// Validate that a string is a valid Budget value
public func isValidBudget(_ value: String) -> Bool {
    return Budget(rawValue: value) != nil
}

/// Validate that a string is a valid TravelStyle value
public func isValidTravelStyle(_ value: String) -> Bool {
    return TravelStyle(rawValue: value) != nil
}

// MARK: - Schema Metadata

public struct SchemaMetadata {
    public static let budgetVersion = "1.0.0"
    public static let travelStyleVersion = "2.0.0"
    public static let lastUpdated = "2026-01-02"

    public static let validBudgetValues: [String] = ["Budget","Comfortable","Mid-range","Luxury","Ultra-Luxury"]
    public static let validTravelStyleValues: [String] = ["Budget","Comfortable","Luxury","Adventure","Relaxation"]
}
