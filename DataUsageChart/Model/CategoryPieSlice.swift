//
//  CategorySlice.swift
//  DataUsageChart
//
//  Created by Anton Marchanka on 2/26/26.
//

import Foundation

/// A slice for category pie chart; lazy-computed from `[Session]` for a given day.
struct CategoryPieSlice: Identifiable, Equatable {
    let id = UUID()
    let category: String
    var minutes: Int
}

extension CategoryPieSlice {
    static let previewData: [CategoryPieSlice] = [
        CategoryPieSlice(category: "Social", minutes: 120),
        CategoryPieSlice(category: "Productivity", minutes: 90),
        CategoryPieSlice(category: "Entertainment", minutes: 150),
        CategoryPieSlice(category: "Education", minutes: 60),
        CategoryPieSlice(category: "Other", minutes: 30)
    ]
}
