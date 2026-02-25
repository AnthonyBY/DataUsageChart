import Foundation

// MARK: - Raw session from JSON
struct Session: Codable, Identifiable {
    let id: String
    let appName: String
    let category: String?
    let startTimestamp: Date
    let endTimestamp: Date

    enum CodingKeys: String, CodingKey {
        case id = "session_id"
        case appName = "app_name"
        case category
        case startTimestamp = "start_timestamp"
        case endTimestamp = "end_timestamp"
    }
}

// MARK: - Aggregated domain models
struct HourlyUsage: Codable, Identifiable {
    var id = UUID()
    let hour: Int
    let minutes: Int
}

struct AppUsage: Codable, Identifiable {
    var id = UUID()
    let app: String
    let category: String?
    var colorHex: String? = nil
    let totalMinutes: Int
    let hourly: [HourlyUsage]
}

struct DailyUsage: Codable {
    let date: String
    let apps: [AppUsage]
}

