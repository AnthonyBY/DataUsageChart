//
//  AppUsageRowView.swift
//  DataUsageChart
//
//  Created by Anton Marchanka on 2/26/26.
//

import SwiftUI

struct AppUsageRowView: View {
    let appUsage: AppUsage
    let total: Int
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(appUsage.colorHex?.hexColor ?? .clear)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading) {
                Text(appUsage.app)
                    .font(.body)

                if let category = appUsage.category, !category.isEmpty {
                    Text(category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text(appUsage.totalMinutes.hoursMinutesString)
                    .font(.body)
                    .monospacedDigit()
                Text(percentage(appUsage.totalMinutes, of: total))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }

    private func percentage(_ part: Int, of total: Int) -> String {
        guard total > 0 else { return "0%" }
        let p = (Double(part) / Double(total)) * 100
        return String(format: "%.0f%%", p)
    }
}

#Preview {
    VStack {
        AppUsageRowView(appUsage: AppUsage.preview, total: 300)
    }
}
