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

extension CategorySlice {
    static let previewData: [CategorySlice] = [
        CategorySlice(category: "Social", minutes: 120),
        CategorySlice(category: "Productivity", minutes: 90),
        CategorySlice(category: "Entertainment", minutes: 150),
        CategorySlice(category: "Education", minutes: 60),
        CategorySlice(category: "Other", minutes: 30)
    ]
}
