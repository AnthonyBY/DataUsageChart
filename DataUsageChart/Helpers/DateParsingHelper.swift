import Foundation

enum DateParsingHelper {
    /// Parses a date string in the format "yyyy-MM-dd" with GMT timezone.
    /// - Parameter string: The date string to parse.
    /// - Returns: A Date if parsing succeeds, otherwise nil.
    static func parseYYYYMMDD(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.date(from: string)
    }
}
