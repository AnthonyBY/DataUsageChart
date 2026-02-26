//
//  AppUsageRowView.swift
//  DataUsageChart
//
//  Created by Anton Marchanka on 2/26/26.
//

import SwiftUI

struct AppUsageRowView: View {
    let appUsage: SessionCategory
    let total: Int
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading) {
                Text(appUsage.appName)
                    .font(.body)

                ProgressView(value: Double(appUsage.totalMinutes), total: Double(total))
                    .progressViewStyle(.linear)
                    .tint(Color.appColor(hex: appUsage.colorHex, key: appUsage.appName))
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
                HStack(spacing: 0) {
                    Text(appUsage.name ?? "")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    Text(" - ")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    Text(appUsage.sessionsText)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)

            Spacer()

            VStack(alignment: .trailing) {
                Text(appUsage.totalMinutes.hoursMinutesString)
                    .font(.body)
                    .monospacedDigit()
                Text(percentage(appUsage.totalMinutes, of: total))
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .frame(minWidth: 40, alignment: .trailing)
        }
        .padding(.vertical, 8)
    }

    private func percentage(_ part: Int, of total: Int) -> String {
        guard total > 0 else { return "0%" }
        let percent = (Double(part) / Double(total)) * 100

        if percent < 1, percent > 0 {
            return String(format: "%.1f%%", p)
        } else {
            return String(format: "%.0f%%", p)
        }
    }
}

#Preview {
    VStack {
        AppUsageRowView(appUsage: SessionCategory.preview, total: 300)
    }
}
