//
//  UsageBarChartView.swift
//  DataUsageChart
//
//  Created by Anton Marchanka on 2/26/26.
//

import SwiftUI
import Charts

private struct ChartPoint: Identifiable {
    let id = UUID()
    let app: String
    let hour: Int
    let minutes: Int
    let colorHex: String?
}

/// Hourly stacked bar chart per app; takes `DailyUsage` (session categories with hourly breakdown).
struct HourlyUsageBarChartView: View {
    let daily: DailyUsage

    var body: some View {
        let points: [ChartPoint] = daily.sessionCategories.flatMap { sessionCategory in
            sessionCategory.hourly.map { h in
                ChartPoint(
                    app: sessionCategory.appName,
                    hour: h.hour,
                    minutes: h.minutes,
                    colorHex: sessionCategory.colorHex
                )
            }
        }

        VStack(alignment: .leading, spacing: 8) {
            Text("Hourly breakdown")
                .font(.headline)

            if points.isEmpty {
                Text("No usage data for this day")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            } else {
                let maxY = max(points.map(\.minutes).max() ?? 0, 1)

                Chart(points) { p in
                    BarMark(
                        x: .value("Hour", p.hour),
                        y: .value("Minutes", p.minutes)
                    )
                    .foregroundStyle(by: .value("App", p.app))
                }
                .chartXScale(domain: 0...23)
                .chartYScale(domain: 0...maxY)
                .chartXAxis {
                    AxisMarks(values: .stride(by: 2)) { value in
                        if let hour = value.as(Int.self), (0...23).contains(hour) {
                            AxisGridLine()
                            AxisValueLabel(String(format: "%02d", hour))
                        }
                    }
                }
                .chartLegend(.hidden)
                .frame(height: 220)
                .padding()
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
    }
}

#Preview {
    HourlyUsageBarChartView(daily: DailyUsage.previewData)
}
