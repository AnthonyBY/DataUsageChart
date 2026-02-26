import Foundation

struct HourlyUsage: Codable, Identifiable, Equatable {
    var id = UUID()
    let hour: Int
    let minutes: Int
}

struct DailyUsage: Codable, Equatable {
    let date: String
    let sessionCategories: [SessionCategory]
}

extension HourlyUsage {
    static let previewData: [HourlyUsage] = [
        HourlyUsage(hour: 8, minutes: 10),
        HourlyUsage(hour: 9, minutes: 25),
        HourlyUsage(hour: 10, minutes: 40),
        HourlyUsage(hour: 11, minutes: 15),
        HourlyUsage(hour: 12, minutes: 30)
    ]
}
