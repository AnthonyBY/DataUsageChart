//
//  CategorySlice.swift
//  DataUsageChart
//
//  Created by Anton Marchanka on 2/26/26.
//

import Foundation

/// A slice for category pie chart; lazy-computed from `[Session]` for a given day.
struct CategorySlice: Identifiable, Equatable {
    let id = UUID()
    let category: String
    var minutes: Int
}
