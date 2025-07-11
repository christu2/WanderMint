import Foundation

/// Form validation utilities
struct FormValidation {
    
    // MARK: - General Validation
    
    /// Validate email format
    static func isValidEmail(_ email: String) -> Bool {
        guard !email.isEmpty else { return false }
        let emailComponents = email.components(separatedBy: "@")
        guard emailComponents.count == 2 else { return false }
        let local = emailComponents[0]
        let domain = emailComponents[1]
        
        // Check local part
        guard !local.isEmpty else { return false }
        guard !local.contains("..") else { return false }
        
        // Check domain part
        guard !domain.isEmpty else { return false }
        guard !domain.hasPrefix(".") && !domain.hasSuffix(".") else { return false }
        guard !domain.contains("..") else { return false }
        
        let domainComponents = domain.components(separatedBy: ".")
        return domainComponents.count >= 2 && domainComponents.allSatisfy { !$0.isEmpty }
    }
    
    /// Validate password strength (minimum 8 characters)
    static func isValidPassword(_ password: String) -> Bool {
        return password.count >= 8
    }
    
    /// Validate name format
    static func isValidName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        
        let nameRegex = #"^[a-zA-ZÀ-ÿ\s\-']+$"#
        return NSPredicate(format: "SELF MATCHES %@", nameRegex).evaluate(with: trimmed)
    }
    
    /// Validate date range
    static func isValidDateRange(start: Date, end: Date) -> Bool {
        return start < end
    }
    
    /// Validate trip title
    static func isValidTripTitle(_ title: String) -> Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 2
    }
    
    /// Validate destination
    static func isValidDestination(_ destination: String) -> Bool {
        let trimmed = destination.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 2
    }
    
    /// Validate points amount
    static func isValidPointsAmount(_ amount: Int) -> Bool {
        return amount >= 0
    }
    
    /// Validate provider name
    static func isValidProviderName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty
    }
    
    /// Trim whitespace from string
    static func trimWhitespace(_ input: String) -> String {
        return input.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Sanitize input by removing potentially harmful characters
    static func sanitizeInput(_ input: String) -> String {
        return input
            .replacingOccurrences(of: "<", with: "")
            .replacingOccurrences(of: ">", with: "")
            .replacingOccurrences(of: "&", with: "")
            .replacingOccurrences(of: "script", with: "")
    }
    
    // MARK: - Trip Validation
    struct Trip {
        
        /// Validate destinations array
        static func validateDestinations(_ destinations: [String]) -> ValidationResult {
            let nonEmptyDestinations = destinations.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            
            if nonEmptyDestinations.isEmpty {
                return .invalid("Please enter at least one destination")
            }
            
            if nonEmptyDestinations.count > AppConfig.Limits.maxDestinationsPerTrip {
                return .invalid("Maximum \(AppConfig.Limits.maxDestinationsPerTrip) destinations allowed")
            }
            
            // Check for duplicate destinations
            let uniqueDestinations = Set(nonEmptyDestinations.map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) })
            if uniqueDestinations.count != nonEmptyDestinations.count {
                return .invalid("Please remove duplicate destinations")
            }
            
            return .valid
        }
        
        /// Validate departure location
        static func validateDepartureLocation(_ location: String) -> ValidationResult {
            let trimmed = location.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                return .invalid("Please enter your departure location")
            }
            if trimmed.count < 2 {
                return .invalid("Departure location must be at least 2 characters")
            }
            return .valid
        }
        
        /// Validate trip dates
        static func validateDates(start: Date, end: Date) -> ValidationResult {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let startDay = calendar.startOfDay(for: start)
            let endDay = calendar.startOfDay(for: end)
            
            // Check if start date is in the past
            if startDay < today {
                return .invalid("Start date cannot be in the past")
            }
            
            // Check if end date is after start date
            if endDay <= startDay {
                return .invalid("End date must be after start date")
            }
            
            // Check for reasonable trip length (max 1 year)
            let oneYearFromStart = calendar.date(byAdding: .year, value: 1, to: start) ?? start
            if end > oneYearFromStart {
                return .invalid("Trip cannot be longer than one year")
            }
            
            // Check for minimum trip length (at least 1 day)
            let daysBetween = calendar.dateComponents([.day], from: startDay, to: endDay).day ?? 0
            if daysBetween < 1 {
                return .invalid("Trip must be at least one day long")
            }
            
            return .valid
        }
        
        /// Validate group size
        static func validateGroupSize(_ size: Int) -> ValidationResult {
            if size < 1 {
                return .invalid("Group size must be at least 1 person")
            }
            if size > AppConfig.Limits.maxGroupSize {
                return .invalid("Maximum group size is \(AppConfig.Limits.maxGroupSize) people")
            }
            return .valid
        }
        
        /// Validate budget string
        static func validateBudget(_ budget: String) -> ValidationResult {
            let trimmed = budget.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Budget is optional, so empty is valid
            if trimmed.isEmpty {
                return .valid
            }
            
            // Check if it's a valid number
            if let budgetValue = Double(trimmed.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) {
                if budgetValue < 0 {
                    return .invalid("Budget cannot be negative")
                }
                if budgetValue > 1_000_000 {
                    return .invalid("Budget seems unreasonably high")
                }
                return .valid
            }
            
            return .invalid("Please enter a valid budget amount")
        }
        
        /// Validate flexible dates configuration
        static func validateFlexibleDates(earliest: Date, latest: Date, duration: Int) -> ValidationResult {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let earliestDay = calendar.startOfDay(for: earliest)
            let latestDay = calendar.startOfDay(for: latest)
            
            if earliestDay < today {
                return .invalid("Earliest start date cannot be in the past")
            }
            
            if latestDay <= earliestDay {
                return .invalid("Latest start date must be after earliest start date")
            }
            
            if duration < 1 {
                return .invalid("Trip duration must be at least 1 day")
            }
            
            if duration > 365 {
                return .invalid("Trip duration cannot exceed 365 days")
            }
            
            return .valid
        }
    }
}

// MARK: - Validation Result
enum ValidationResult {
    case valid
    case invalid(String)
    
    var isValid: Bool {
        switch self {
        case .valid:
            return true
        case .invalid:
            return false
        }
    }
    
    var errorMessage: String? {
        switch self {
        case .valid:
            return nil
        case .invalid(let message):
            return message
        }
    }
}

// MARK: - Validation State
struct ValidationState {
    var destinations: ValidationResult = .valid
    var departureLocation: ValidationResult = .valid
    var dates: ValidationResult = .valid
    var groupSize: ValidationResult = .valid
    var budget: ValidationResult = .valid
    var flexibleDates: ValidationResult = .valid
    
    var isFormValid: Bool {
        return destinations.isValid &&
               departureLocation.isValid &&
               dates.isValid &&
               groupSize.isValid &&
               budget.isValid &&
               flexibleDates.isValid
    }
    
    var firstError: String? {
        return destinations.errorMessage ??
               departureLocation.errorMessage ??
               dates.errorMessage ??
               groupSize.errorMessage ??
               budget.errorMessage ??
               flexibleDates.errorMessage
    }
}