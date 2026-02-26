//
//  CategoryPieChartView.swift
//  DataUsageChart
//
//  Created by Anton Marchanka on 2/26/26.
//

import SwiftUI
import Charts

/// Pie chart by category; takes lazy-computed `[CategorySlice]` (e.g. from `categoryBreakdown(sessions:for:)`).
struct CategoryPieChartView: View {
    let slices: [CategorySlice]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("By category")
                .font(.headline)

            if slices.isEmpty {
                Text("No usage data for this day")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            } else {
                Chart(slices) { slice in
                    SectorMark(
                        angle: .value("Minutes", slice.minutes),
                        innerRadius: .ratio(0.5),
                        angularInset: 1
                    )
                    .foregroundStyle(by: .value("Category", slice.category))
                    .cornerRadius(4)
                }
                .chartLegend(position: .bottom, spacing: 8)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

#Preview {
    CategoryPieChartView(slices: CategorySlice.previewData)
}
