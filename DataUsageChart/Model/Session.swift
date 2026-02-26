//
//  Session.swift
//  DataUsageChart
//
//  Created by Anton Marchanka on 2/26/26.
//

import Foundation

struct Session: Codable, Identifiable, Equatable {
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
