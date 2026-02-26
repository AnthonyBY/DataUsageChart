//
//  AppUsage.swift
//  DataUsageChart
//
//  Created by Anton Marchanka on 2/26/26.
//

import Foundation

struct AppUsage: Codable, Identifiable {
    var id = UUID()
    let app: String
    let category: String?
    var colorHex: String? = nil
    let totalMinutes: Int
    let hourly: [HourlyUsage]
}

extension AppUsage {
    static let preview = AppUsage(
        app: "Clock",
        category: "System",
        colorHex: "#FF9500",
        totalMinutes: 78,
        hourly: HourlyUsage.previewData
    )
}
