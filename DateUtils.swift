import Foundation

// MARK: - Date Utilities for Timezone-Agnostic Handling
struct DateUtils {
    
    // MARK: - Date-Only Formatters
    
    /// Creates a date formatter for date-only strings (YYYY-MM-DD) without timezone conversion
    static var dateOnlyFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0) // UTC to avoid timezone shifts
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }
    
    /// Creates a display formatter for showing dates to users in their local timezone
    static var displayDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.timeZone = TimeZone.current // Use device's timezone for display
        return formatter
    }
    
    /// Creates a full display formatter with day of week
    static var fullDisplayDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        formatter.timeZone = TimeZone.current
        return formatter
    }
    
    /// Creates a short display formatter (e.g., "Jan 15")
    static var shortDisplayDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        formatter.timeZone = TimeZone.current
        return formatter
    }
    
    // MARK: - Date-Only Conversion Methods
    
    /// Converts a Date to a date-only string (YYYY-MM-DD) without timezone conversion
    static func toDateOnlyString(_ date: Date) -> String {
        // Use local calendar to preserve the exact date as displayed to user
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = components.year,
              let month = components.month,
              let day = components.day else {
            return dateOnlyFormatter.string(from: date) // Fallback
        }
        return dateString(year: year, month: month, day: day)
    }
    
    /// Converts a date-only string (YYYY-MM-DD) to a Date at midnight local time
    static func fromDateOnlyString(_ dateString: String) -> Date? {
        // Parse as UTC first to avoid timezone shifts
        guard let utcDate = dateOnlyFormatter.date(from: dateString) else {
            return nil
        }
        
        // Convert to local midnight to maintain the same calendar date
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: utcDate)
        return calendar.date(from: components)
    }
    
    /// Creates a date-only string from Date components
    static func dateString(year: Int, month: Int, day: Int) -> String {
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
    
    /// Extracts date components without time
    static func dateComponents(from date: Date) -> DateComponents {
        let calendar = Calendar.current
        return calendar.dateComponents([.year, .month, .day], from: date)
    }
    
    /// Creates a Date from date components at midnight local time
    static func date(from components: DateComponents) -> Date? {
        let calendar = Calendar.current
        return calendar.date(from: components)
    }
    
    // MARK: - Timezone-Safe Date Operations
    
    /// Adds days to a date while maintaining the same calendar date (no timezone shift)
    static func addDays(_ days: Int, to date: Date) -> Date? {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: days, to: date)
    }
    
    /// Calculates the number of days between two dates
    static func daysBetween(_ startDate: Date, and endDate: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        return components.day ?? 0
    }
    
    /// Checks if two dates are on the same calendar day
    static func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(date1, inSameDayAs: date2)
    }
    
    /// Gets the start of day for a given date in local timezone
    static func startOfDay(_ date: Date) -> Date {
        let calendar = Calendar.current
        return calendar.startOfDay(for: date)
    }
    
    // MARK: - API Communication Helpers
    
    /// Converts a local Date to an API-safe date string for backend communication
    static func toAPIDateString(_ date: Date) -> String {
        // Use local calendar to preserve the exact date as displayed to user
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = components.year,
              let month = components.month,
              let day = components.day else {
            return toDateOnlyString(date) // Fallback
        }
        return dateString(year: year, month: month, day: day)
    }
    
    /// Converts an API date string to a local Date
    static func fromAPIDateString(_ dateString: String) -> Date? {
        return fromDateOnlyString(dateString)
    }
    
    // MARK: - Display Helpers
    
    /// Formats a date for user display
    static func displayString(for date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
    
    /// Formats a date range for user display
    static func displayString(from startDate: Date, to endDate: Date) -> String {
        let startString = displayString(for: startDate, style: .medium)
        let endString = displayString(for: endDate, style: .medium)
        
        if isSameDay(startDate, endDate) {
            return startString
        } else {
            return "\(startString) - \(endString)"
        }
    }
}

// MARK: - Date Extensions
extension Date {
    /// Converts this Date to a timezone-safe date-only string
    var dateOnlyString: String {
        return DateUtils.toDateOnlyString(self)
    }
    
    /// Gets a display string for this date
    var displayString: String {
        return DateUtils.displayString(for: self)
    }
    
    /// Gets the start of the day for this date
    var startOfDay: Date {
        return DateUtils.startOfDay(self)
    }
}

// MARK: - String Extensions
extension String {
    /// Converts this date string to a Date (assuming YYYY-MM-DD format)
    var toDate: Date? {
        return DateUtils.fromDateOnlyString(self)
    }
}