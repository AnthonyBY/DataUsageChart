//
//  CategoryBreakdown.swift
//  DataUsageChart
//

import Foundation

/// A slice for category pie chart; lazy-computed from `[Session]` for a given day.
struct CategorySlice: Identifiable, Equatable {
    let id = UUID()
    let category: String
    let minutes: Int
}
