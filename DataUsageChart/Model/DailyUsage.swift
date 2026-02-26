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
