//
//  Session.swift
//  DataUsageChart
//
//  Created by Anton Marchanka on 2/26/26.
//

import Foundation

struct Session: Codable, Identifiable {
    let id: String
    let appName: String
    let category: String
    let startTimestamp: Date
    let endTimestamp: Date

    enum CodingKeys: String, CodingKey {
        case id = "session_id"
        case appName = "app_name"
        case category
        case startTimestamp = "start_timestamp"
        case endTimestamp = "end_timestamp"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        appName = try container.decode(String.self, forKey: .appName)
        category = (try container.decodeIfPresent(String.self, forKey: .category)) ?? "Other"
        startTimestamp = try container.decode(Date.self, forKey: .startTimestamp)
        endTimestamp = try container.decode(Date.self, forKey: .endTimestamp)
    }
}
