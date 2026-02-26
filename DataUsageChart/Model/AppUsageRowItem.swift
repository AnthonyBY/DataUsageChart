//
//  AppUsageRowItem.swift
//  DataUsageChart
//
//  Created by Anton Marchanka on 2/26/26.
//

import Foundation

struct AppUsageRowItem: Identifiable {
    let id = UUID()
    let appName: String
    let categoryName: String
    var totalMinutes: Int
    var sessionsCount: Int
    let colorHex: String?

    var sessionsText: String {
        sessionsCount == 1 ? "1 session" : "\(sessionsCount) sessions"
    }
}

extension AppUsageRowItem {
    init(from sessionCategory: SessionCategory) {
        self.appName = sessionCategory.appName
        self.categoryName = (sessionCategory.name?.isEmpty == false && sessionCategory.name?.lowercased() != "other")
            ? (sessionCategory.name ?? "Other")
            : "Other"
        self.totalMinutes = sessionCategory.totalMinutes
        self.sessionsCount = sessionCategory.sessions
        self.colorHex = sessionCategory.colorHex
    }
}
