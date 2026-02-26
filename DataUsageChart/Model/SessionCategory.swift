//
//  AppUsage.swift
//  DataUsageChart
//
//  Created by Anton Marchanka on 2/26/26.
//

import Foundation

struct SessionCategory: Codable, Identifiable, Equatable {
    var id = UUID()
    let name: String?
    let appName: String
    var colorHex: String? = nil
    let totalMinutes: Int
    let sessions: Int
    let hourly: [HourlyUsage]
}

extension SessionCategory {
    var sessionsText: String {
        let count = sessions
        return count == 1 ? "1 session" : "\(count) sessions"
    }
}

extension SessionCategory {
    static let preview = SessionCategory(
        name: "System",
        appName: "Clock",
        colorHex: "#FF9500",
        totalMinutes: 78,
        sessions: 3,
        hourly: HourlyUsage.previewData
    )
}
