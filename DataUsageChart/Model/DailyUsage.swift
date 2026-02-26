//
//  DailyUsage.swift
//  DataUsageChart
//
//  Created by Anton Marchanka on 2/26/26.
//

import Foundation

struct DailyUsage: Codable, Equatable {
    let date: String
    let sessionCategories: [SessionCategory]
}

extension DailyUsage {
    static let previewData: DailyUsage =
    DailyUsage(
        date: "2026-02-23",
        sessionCategories: [
            SessionCategory.preview,
            SessionCategory.preview
        ]
    )
}
