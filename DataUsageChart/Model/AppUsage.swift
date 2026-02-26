//
//  AppUsage.swift
//  DataUsageChart
//
//  Created by Anton Marchanka on 2/26/26.
//

import Foundation

struct AppUsage: Codable, Identifiable {
    var id = UUID()
    let name: String
    let category: String?
    var colorHex: String? = nil
    let totalMinutes: Int
    let sessions: Int
    let hourly: [HourlyUsage]
}

extension AppUsage {
    var sessionsText: String {
        let count = sessions
        return count == 1 ? "1 session" : "\(count) sessions"
    }
}

extension AppUsage {
    static let preview = AppUsage(
        name: "Clock",
        category: "System",
        colorHex: "#FF9500",
        totalMinutes: 78,
        sessions: 3,
        hourly: HourlyUsage.previewData
    )
}
